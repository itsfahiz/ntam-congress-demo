import { getPool } from '../db/pool.js';
import { publicError } from '../types/http.js';

export const SEEDED_POLL_ID = '7a1c0001-0000-4000-8000-000000000001';
export const SEEDED_OPTION_AI = '7a1c0001-0000-4000-8000-000000000011';
export const SEEDED_OPTION_NUTRITION = '7a1c0001-0000-4000-8000-000000000012';
export const SEEDED_OPTION_DIGITAL = '7a1c0001-0000-4000-8000-000000000013';

export const SEEDED_POLL_2_ID = '7a1c0001-0000-4000-8000-000000000002';
export const SEEDED_OPTION_PEDIATRIC = '7a1c0001-0000-4000-8000-000000000021';
export const SEEDED_OPTION_RESEARCH = '7a1c0001-0000-4000-8000-000000000022';
export const SEEDED_OPTION_PREVENTIVE = '7a1c0001-0000-4000-8000-000000000023';

export const SEEDED_POLL_3_ID = '7a1c0001-0000-4000-8000-000000000003';
export const SEEDED_OPTION_PANEL = '7a1c0001-0000-4000-8000-000000000031';
export const SEEDED_OPTION_CASES = '7a1c0001-0000-4000-8000-000000000032';
export const SEEDED_OPTION_WORKSHOPS = '7a1c0001-0000-4000-8000-000000000033';

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
  listActive(userId: string): Promise<LivePoll[]>;
  getActive(userId: string): Promise<LivePoll | null>;
  getById(userId: string, pollId: string): Promise<LivePoll | null>;
  vote(userId: string, pollId: string, optionId: string): Promise<LivePoll>;
};

type OptionRow = {
  poll_id: string;
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
  async listActive(userId) {
    const pool = getPool();
    const { rows: polls } = await pool.query<PollRow>(
      `SELECT id, question, topic_label
       FROM public.polls
       WHERE active = true
       ORDER BY id ASC`,
    );
    if (!polls.length) return [];

    const ids = polls.map((poll) => poll.id);
    const { rows: options } = await pool.query<OptionRow>(
      `SELECT o.poll_id, o.id, o.label, COUNT(v.id)::int AS vote_count
       FROM public.poll_options o
       LEFT JOIN public.poll_votes v ON v.option_id = o.id
       WHERE o.poll_id = ANY($1::uuid[])
       GROUP BY o.poll_id, o.id, o.label, o.sort_order
       ORDER BY o.poll_id, o.sort_order ASC`,
      [ids],
    );
    const { rows: mine } = await pool.query<{
      poll_id: string;
      option_id: string;
    }>(
      `SELECT poll_id, option_id
       FROM public.poll_votes
       WHERE user_id = $1 AND poll_id = ANY($2::uuid[])`,
      [userId, ids],
    );

    const mineByPoll = new Map(
      mine.map((row) => [row.poll_id, row.option_id]),
    );
    const optionsByPoll = new Map<
      string,
      { id: string; label: string; voteCount: number }[]
    >();
    for (const row of options) {
      const list = optionsByPoll.get(row.poll_id) ?? [];
      list.push({
        id: row.id,
        label: row.label,
        voteCount: Number(row.vote_count),
      });
      optionsByPoll.set(row.poll_id, list);
    }

    return polls.map((poll) =>
      withPercents(
        {
          id: poll.id,
          question: poll.question,
          topicLabel: poll.topic_label,
        },
        optionsByPoll.get(poll.id) ?? [],
        mineByPoll.get(poll.id) ?? null,
      ),
    );
  },

  async getActive(userId) {
    const polls = await postgresStore.listActive(userId);
    return polls[0] ?? null;
  },

  async getById(userId, pollId) {
    const polls = await postgresStore.listActive(userId);
    return polls.find((poll) => poll.id === pollId) ?? null;
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

    const poll = await postgresStore.getById(userId, pollId);
    if (!poll) throw publicError(404, 'Poll not found.');
    return poll;
  },
};

function store() {
  return storeOverride ?? postgresStore;
}

export async function listActivePolls(userId: string) {
  return store().listActive(userId);
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

type MemoryPoll = {
  id: string;
  question: string;
  topicLabel: string;
  options: { id: string; label: string }[];
};

export function createMemoryPollStore(): PollStore {
  const polls: MemoryPoll[] = [
    {
      id: SEEDED_POLL_ID,
      question: 'Which innovation will have the greatest impact on healthcare?',
      topicLabel: 'Healthcare innovation',
      options: [
        { id: SEEDED_OPTION_AI, label: 'Artificial Intelligence' },
        { id: SEEDED_OPTION_NUTRITION, label: 'Personalized Nutrition' },
        { id: SEEDED_OPTION_DIGITAL, label: 'Digital Health' },
      ],
    },
    {
      id: SEEDED_POLL_2_ID,
      question:
        'Which topic would you most like to explore at a future medical congress?',
      topicLabel: 'Future congress',
      options: [
        { id: SEEDED_OPTION_PEDIATRIC, label: 'Pediatric Nutrition' },
        { id: SEEDED_OPTION_RESEARCH, label: 'Clinical Research' },
        { id: SEEDED_OPTION_PREVENTIVE, label: 'Preventive Healthcare' },
      ],
    },
    {
      id: SEEDED_POLL_3_ID,
      question: 'Which session format helps you learn most effectively?',
      topicLabel: 'Learning format',
      options: [
        { id: SEEDED_OPTION_PANEL, label: 'Expert Panel Discussions' },
        { id: SEEDED_OPTION_CASES, label: 'Clinical Case Studies' },
        { id: SEEDED_OPTION_WORKSHOPS, label: 'Interactive Workshops' },
      ],
    },
  ];
  const votes = new Map<string, string>();
  const voteKey = (userId: string, pollId: string) => `${userId}:${pollId}`;

  const snapshot = (userId: string, poll: MemoryPoll): LivePoll => {
    const optionIds = new Set(poll.options.map((option) => option.id));
    const counts = new Map<string, number>();
    for (const [key, optionId] of votes) {
      if (key.endsWith(`:${poll.id}`) && optionIds.has(optionId)) {
        counts.set(optionId, (counts.get(optionId) ?? 0) + 1);
      }
    }
    return withPercents(
      poll,
      poll.options.map((option) => ({
        id: option.id,
        label: option.label,
        voteCount: counts.get(option.id) ?? 0,
      })),
      votes.get(voteKey(userId, poll.id)) ?? null,
    );
  };

  return {
    async listActive(userId) {
      return polls.map((poll) => snapshot(userId, poll));
    },
    async getActive(userId) {
      return snapshot(userId, polls[0]!);
    },
    async getById(userId, pollId) {
      const poll = polls.find((item) => item.id === pollId);
      return poll ? snapshot(userId, poll) : null;
    },
    async vote(userId, pollId, optionId) {
      const poll = polls.find((item) => item.id === pollId);
      if (!poll) throw publicError(404, 'Poll not found.');
      if (!poll.options.some((option) => option.id === optionId)) {
        throw publicError(400, 'That option is not part of this poll.');
      }
      const key = voteKey(userId, pollId);
      if (votes.has(key)) {
        throw publicError(409, 'You already voted in this poll.', 'already_voted');
      }
      votes.set(key, optionId);
      return snapshot(userId, poll);
    },
  };
}
