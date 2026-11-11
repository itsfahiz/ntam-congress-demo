import { getPool } from '../db/pool.js';
import type {
  AuthUser,
  QuestionRecord,
  QuestionReplyRecord,
  QuestionTopic,
} from '../types/contracts.js';
import { publicError } from '../types/http.js';
import { getProfile } from './profile-service.js';

const TOPICS = new Set<string>(['general', 'nutrition', 'research', 'clinical']);
const REPLY_MIN = 2;
const REPLY_MAX = 240;

type QuestionRow = {
  id: string;
  user_id: string;
  body: string;
  topic: QuestionTopic;
  author_name: string;
  answered: boolean;
  created_at: Date | string;
  like_count?: number | string | boolean;
  reply_count?: number | string;
  liked_by_me?: boolean | string;
};

type ReplyRow = {
  id: string;
  question_id: string;
  body: string;
  author_name: string;
  created_at: Date | string;
};

type QuestionStore = {
  list(userId: string): Promise<QuestionRecord[]>;
  create(input: {
    userId: string;
    body: string;
    topic: string;
    authorName: string;
  }): Promise<QuestionRecord>;
  like(userId: string, questionId: string): Promise<QuestionRecord>;
  unlike(userId: string, questionId: string): Promise<QuestionRecord>;
  listReplies(questionId: string): Promise<QuestionReplyRecord[]>;
  createReply(input: {
    userId: string;
    questionId: string;
    body: string;
    authorName: string;
  }): Promise<QuestionReplyRecord>;
};

let storeOverride: QuestionStore | null = null;

export function setQuestionStoreOverride(store: QuestionStore | null) {
  storeOverride = store;
}

function mapQuestion(row: QuestionRow, likedByMe = false): QuestionRecord {
  return {
    id: row.id,
    userId: row.user_id,
    body: row.body,
    topic: row.topic,
    authorName: row.author_name,
    answered: row.answered,
    createdAt: row.created_at,
    likeCount: Number(row.like_count ?? 0),
    replyCount: Number(row.reply_count ?? 0),
    likedByMe,
  };
}

function mapReply(row: ReplyRow): QuestionReplyRecord {
  return {
    id: row.id,
    questionId: row.question_id,
    body: row.body,
    authorName: row.author_name,
    createdAt: row.created_at,
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

function assertReplyBody(body: string) {
  const text = String(body ?? '').trim();
  if (text.length < REPLY_MIN || text.length > REPLY_MAX) {
    throw publicError(
      400,
      `Keep replies between ${REPLY_MIN} and ${REPLY_MAX} characters.`,
    );
  }
  return text;
}

const COUNT_SELECT = `
  SELECT
    q.id,
    q.user_id,
    q.body,
    q.topic,
    q.author_name,
    q.answered,
    q.created_at,
    (SELECT COUNT(*)::int FROM public.question_likes l WHERE l.question_id = q.id) AS like_count,
    (SELECT COUNT(*)::int FROM public.question_replies r WHERE r.question_id = q.id) AS reply_count,
    EXISTS(
      SELECT 1
      FROM public.question_likes me
      WHERE me.question_id = q.id AND me.user_id = $1
    ) AS liked_by_me
`;

const postgresStore: QuestionStore = {
  async list(userId) {
    const { rows } = await getPool().query<QuestionRow>(
      `${COUNT_SELECT}
       FROM public.questions q
       ORDER BY q.created_at DESC, q.id DESC`,
      [userId],
    );
    return rows.map((row) => mapQuestion(row, Boolean(row.liked_by_me)));
  },

  async create({ userId, body, topic, authorName }) {
    const text = String(body ?? '').trim();
    const chosenTopic = String(topic ?? 'general');
    if (!TOPICS.has(chosenTopic)) {
      throw publicError(400, 'Invalid question topic.');
    }
    const { rows } = await getPool().query<{ id: string }>(
      `INSERT INTO public.questions (user_id, body, topic, author_name)
       VALUES ($1, $2, $3, $4)
       RETURNING id`,
      [userId, text, chosenTopic, String(authorName ?? '').trim()],
    );
    const question = await snapshot(userId, rows[0]!.id);
    if (!question) throw publicError(404, 'Question not found.');
    return question;
  },

  async like(userId, questionId) {
    await assertQuestionExists(questionId);
    try {
      await getPool().query(
        `INSERT INTO public.question_likes (question_id, user_id)
         VALUES ($1, $2)
         ON CONFLICT (question_id, user_id) DO NOTHING`,
        [questionId, userId],
      );
    } catch (error) {
      if (!isUniqueViolation(error)) throw error;
    }
    const question = await snapshot(userId, questionId);
    if (!question) throw publicError(404, 'Question not found.');
    return question;
  },

  async unlike(userId, questionId) {
    await assertQuestionExists(questionId);
    await getPool().query(
      `DELETE FROM public.question_likes
       WHERE question_id = $1 AND user_id = $2`,
      [questionId, userId],
    );
    const question = await snapshot(userId, questionId);
    if (!question) throw publicError(404, 'Question not found.');
    return question;
  },

  async listReplies(questionId) {
    await assertQuestionExists(questionId);
    const { rows } = await getPool().query<ReplyRow>(
      `SELECT r.id, r.question_id, r.body, r.created_at,
              COALESCE(NULLIF(btrim(p.full_name), ''), r.author_name) AS author_name
       FROM public.question_replies r
       LEFT JOIN public.attendee_profiles p ON p.user_id = r.user_id
       WHERE r.question_id = $1
       ORDER BY r.created_at ASC, r.id ASC`,
      [questionId],
    );
    return rows.map(mapReply);
  },

  async createReply({ userId, questionId, body, authorName }) {
    await assertQuestionExists(questionId);
    const text = assertReplyBody(body);
    const { rows } = await getPool().query<ReplyRow>(
      `INSERT INTO public.question_replies (question_id, user_id, body, author_name)
       VALUES ($1, $2, $3, $4)
       RETURNING id, question_id, body, author_name, created_at`,
      [questionId, userId, text, String(authorName ?? '').trim()],
    );
    return mapReply(rows[0]!);
  },
};

async function assertQuestionExists(questionId: string) {
  const { rows } = await getPool().query<{ id: string }>(
    `SELECT id FROM public.questions WHERE id = $1 LIMIT 1`,
    [questionId],
  );
  if (!rows[0]) throw publicError(404, 'Question not found.');
}

async function snapshot(userId: string, questionId: string) {
  const { rows } = await getPool().query<QuestionRow>(
    `${COUNT_SELECT}
     FROM public.questions q
     WHERE q.id = $2
     LIMIT 1`,
    [userId, questionId],
  );
  const row = rows[0];
  return row ? mapQuestion(row, Boolean(row.liked_by_me)) : null;
}

function store() {
  return storeOverride ?? postgresStore;
}

export async function resolveQuestionAuthor(authUser: AuthUser) {
  const metadata = authUser.user_metadata ?? {};
  const fromMetadata =
    String(metadata.full_name ?? metadata.fullName ?? '').trim() ||
    String(authUser.email ?? '').trim();
  if (storeOverride) {
    return fromMetadata || 'Attendee';
  }
  const profile = await getProfile(authUser.id);
  return profile?.fullName || fromMetadata || 'Attendee';
}

export async function listQuestions(userId: string) {
  return store().list(userId);
}

export async function createQuestion(input: {
  userId: string;
  body: string;
  topic: string;
  authorName: string;
}) {
  return store().create(input);
}

export async function likeQuestion(userId: string, questionId: string) {
  return store().like(userId, questionId);
}

export async function unlikeQuestion(userId: string, questionId: string) {
  return store().unlike(userId, questionId);
}

export async function listQuestionReplies(questionId: string) {
  return store().listReplies(questionId);
}

export async function createQuestionReply(input: {
  userId: string;
  questionId: string;
  body: string;
  authorName: string;
}) {
  return store().createReply(input);
}

type MemoryQuestion = {
  id: string;
  userId: string;
  body: string;
  topic: QuestionTopic;
  authorName: string;
  answered: boolean;
  createdAt: Date;
};

export const MEMORY_QUESTION_1_ID = 'b1a10001-0000-4000-8000-000000000001';
export const MEMORY_QUESTION_2_ID = 'b1a10001-0000-4000-8000-000000000002';

export function createMemoryQuestionStore(): QuestionStore {
  const questions: MemoryQuestion[] = [
    {
      id: MEMORY_QUESTION_1_ID,
      userId: '11111111-1111-4111-8111-111111111111',
      body: 'How does this session apply in clinic today?',
      topic: 'nutrition',
      authorName: 'Huda Latheef',
      answered: false,
      createdAt: new Date('2026-11-11T10:00:00.000Z'),
    },
    {
      id: MEMORY_QUESTION_2_ID,
      userId: '22222222-2222-4222-8222-222222222222',
      body: 'Which endpoints matter most when translating nutrition trials?',
      topic: 'research',
      authorName: 'Amira Hassan',
      answered: false,
      createdAt: new Date('2026-11-11T11:00:00.000Z'),
    },
  ];
  const likes = new Map<string, Set<string>>();
  const replies: QuestionReplyRecord[] = [];

  const snapshotFor = (userId: string, question: MemoryQuestion): QuestionRecord => {
    const liked = likes.get(question.id) ?? new Set();
    return {
      id: question.id,
      userId: question.userId,
      body: question.body,
      topic: question.topic,
      authorName: question.authorName,
      answered: question.answered,
      createdAt: question.createdAt,
      likeCount: liked.size,
      replyCount: replies.filter((reply) => reply.questionId === question.id).length,
      likedByMe: liked.has(userId),
    };
  };

  const requireQuestion = (questionId: string) => {
    const question = questions.find((item) => item.id === questionId);
    if (!question) throw publicError(404, 'Question not found.');
    return question;
  };

  return {
    async list(userId) {
      return [...questions]
        .sort(
          (a, b) =>
            b.createdAt.getTime() - a.createdAt.getTime() ||
            b.id.localeCompare(a.id),
        )
        .map((question) => snapshotFor(userId, question));
    },
    async create({ userId, body, topic, authorName }) {
      const chosenTopic = String(topic ?? 'general');
      if (!TOPICS.has(chosenTopic)) {
        throw publicError(400, 'Invalid question topic.');
      }
      const question: MemoryQuestion = {
        id: crypto.randomUUID(),
        userId,
        body: String(body ?? '').trim(),
        topic: chosenTopic as QuestionTopic,
        authorName: String(authorName ?? '').trim(),
        answered: false,
        createdAt: new Date(),
      };
      questions.unshift(question);
      return snapshotFor(userId, question);
    },
    async like(userId, questionId) {
      const question = requireQuestion(questionId);
      const liked = likes.get(questionId) ?? new Set();
      liked.add(userId);
      likes.set(questionId, liked);
      return snapshotFor(userId, question);
    },
    async unlike(userId, questionId) {
      const question = requireQuestion(questionId);
      const liked = likes.get(questionId) ?? new Set();
      liked.delete(userId);
      likes.set(questionId, liked);
      return snapshotFor(userId, question);
    },
    async listReplies(questionId) {
      requireQuestion(questionId);
      return replies
        .filter((reply) => reply.questionId === questionId)
        .sort((a, b) => String(a.createdAt).localeCompare(String(b.createdAt)));
    },
    async createReply({ questionId, body, authorName }) {
      requireQuestion(questionId);
      const text = assertReplyBody(body);
      const reply: QuestionReplyRecord = {
        id: crypto.randomUUID(),
        questionId,
        body: text,
        authorName: String(authorName ?? '').trim(),
        createdAt: new Date(),
      };
      replies.push(reply);
      return reply;
    },
  };
}
