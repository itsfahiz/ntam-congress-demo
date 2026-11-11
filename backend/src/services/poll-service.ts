import { getPool } from '../db/pool.js';
import { publicError } from '../types/http.js';

export const SEEDED_POLL_ID = '7a1c0001-0000-4000-8000-000000000001';
export const SEEDED_OPTION_AI = '7a1c0001-0000-4000-8000-000000000011';
export const SEEDED_OPTION_NUTRITION = '7a1c0001-0000-4000-8000-000000000012';
export const SEEDED_OPTION_DIGITAL = '7a1c0001-0000-4000-8000-000000000013';

export type LivePollOption = {
  id: string;
  label: string;
  voteCount: number;
  percent: number;
};

export type LivePoll = {
  id: string;
  question: string;
  topicLabel: string;
  totalVotes: number;
  myOptionId: string | null;
  options: LivePollOption[];
};

type PollStore = {
  getActive(userId: string): Promise<LivePoll | null>;
  vote(userId: string, pollId: string, optionId: string): Promise<LivePoll>;
};

type OptionRow = {
  id: string;
  label: string;
  vote_count: number | string;
};

type PollRow = {
  id: string;
  question: string;
  topic_label: string;
};

let storeOverride: PollStore | null = null;

export function setPollStoreOverride(store: PollStore | null) {
  storeOverride = store;
}

function withPercents(
  poll: { id: string; question: string; topicLabel: string },
  options: { id: string; label: string; voteCount: number }[],
  myOptionId: string | null,
): LivePoll {
  const totalVotes = options.reduce((sum, option) => sum + option.voteCount, 0);
  return {
    id: poll.id,
    question: poll.question,
    topicLabel: poll.topicLabel,
    totalVotes,
    myOptionId,
    options: options.map((option) => ({
      id: option.id,
      label: option.label,
      voteCount: option.voteCount,
      percent:
        totalVotes === 0
          ? 0
          : Math.round((option.voteCount / totalVotes) * 100),
    })),
  };
}

function isUniqueViolation(error: unknown) {
  return (
    typeof error === 'object' &&
    error !== null &&
    'code' in error &&
    (error as { code?: string }).code === '23505'
  );
}

const postgresStore: PollStore = {
  async getActive(userId) {
    const pool = getPool();
    const { rows: polls } = await pool.query<PollRow>(
      `SELECT id, question, topic_label
       FROM public.polls
       WHERE active = true
       ORDER BY created_at DESC
       LIMIT 1`,
    );
    const poll = polls[0];
    if (!poll) return null;

    const { rows: options } = await pool.query<OptionRow>(
      `SELECT o.id, o.label, COUNT(v.id)::int AS vote_count
       FROM public.poll_options o
       LEFT JOIN public.poll_votes v ON v.option_id = o.id
       WHERE o.poll_id = $1
       GROUP BY o.id, o.label, o.sort_order
       ORDER BY o.sort_order ASC`,
      [poll.id],
    );
    const { rows: mine } = await pool.query<{ option_id: string }>(
      `SELECT option_id
       FROM public.poll_votes
       WHERE poll_id = $1 AND user_id = $2
       LIMIT 1`,
      [poll.id, userId],
    );

    return withPercents(
      {
        id: poll.id,
        question: poll.question,
        topicLabel: poll.topic_label,
      },
      options.map((row) => ({
        id: row.id,
        label: row.label,
        voteCount: Number(row.vote_count),
      })),
      mine[0]?.option_id ?? null,
    );
  },

  async vote(userId, pollId, optionId) {
    const pool = getPool();
    const { rows: polls } = await pool.query<{ id: string; active: boolean }>(
      `SELECT id, active FROM public.polls WHERE id = $1 LIMIT 1`,
      [pollId],
    );
    if (!polls[0] || !polls[0].active) {
      throw publicError(404, 'Poll not found.');
    }

    const { rows: options } = await pool.query<{ id: string }>(
      `SELECT id FROM public.poll_options WHERE id = $1 AND poll_id = $2 LIMIT 1`,
      [optionId, pollId],
    );
    if (!options[0]) {
      throw publicError(400, 'That option is not part of this poll.');
    }

    try {
      const inserted = await pool.query<{ id: string }>(
        `INSERT INTO public.poll_votes (poll_id, option_id, user_id)
         VALUES ($1, $2, $3)
         ON CONFLICT (poll_id, user_id) DO NOTHING
         RETURNING id`,
        [pollId, optionId, userId],
      );
      if (!inserted.rows[0]) {
        throw publicError(409, 'You already voted in this poll.', 'already_voted');
      }
    } catch (error) {
      if (isUniqueViolation(error)) {
        throw publicError(409, 'You already voted in this poll.', 'already_voted');
      }
      throw error;
    }

    const poll = await postgresStore.getActive(userId);
    if (!poll) throw publicError(404, 'Poll not found.');
    return poll;
  },
};

function store() {
  return storeOverride ?? postgresStore;
}

export async function getActivePoll(userId: string) {
  return store().getActive(userId);
}

export async function voteOnPoll(
  userId: string,
  pollId: string,
  optionId: string,
) {
  return store().vote(userId, pollId, optionId);
}

export function createMemoryPollStore(): PollStore {
  const options = [
    { id: SEEDED_OPTION_AI, label: 'Artificial Intelligence', voteCount: 0 },
    { id: SEEDED_OPTION_NUTRITION, label: 'Personalized Nutrition', voteCount: 0 },
    { id: SEEDED_OPTION_DIGITAL, label: 'Digital Health', voteCount: 0 },
  ];
  const votes = new Map<string, string>();

  const snapshot = (userId: string): LivePoll =>
    withPercents(
      {
        id: SEEDED_POLL_ID,
        question: 'Which innovation will have the greatest impact on healthcare?',
        topicLabel: 'Healthcare innovation',
      },
      options.map((option) => ({
        ...option,
        voteCount: [...votes.values()].filter((id) => id === option.id).length,
      })),
      votes.get(userId) ?? null,
    );

  return {
    async getActive(userId) {
      return snapshot(userId);
    },
    async vote(userId, pollId, optionId) {
      if (pollId !== SEEDED_POLL_ID) {
        throw publicError(404, 'Poll not found.');
      }
      if (!options.some((option) => option.id === optionId)) {
        throw publicError(400, 'That option is not part of this poll.');
      }
      const existing = votes.get(userId);
      if (existing) {
        throw publicError(409, 'You already voted in this poll.', 'already_voted');
      }
      votes.set(userId, optionId);
      return snapshot(userId);
    },
  };
}
