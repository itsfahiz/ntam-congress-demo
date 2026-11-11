import { getPool } from '../db/pool.js';
import type { QuestionRecord, QuestionTopic } from '../types/contracts.js';
import { publicError } from '../types/http.js';

const TOPICS = new Set<string>(['general', 'nutrition', 'research', 'clinical']);

type QuestionRow = {
  id: string;
  user_id: string;
  body: string;
  topic: QuestionTopic;
  author_name: string;
  answered: boolean;
  created_at: Date | string;
};

function mapQuestion(row: QuestionRow): QuestionRecord {
  return {
    id: row.id,
    userId: row.user_id,
    body: row.body,
    topic: row.topic,
    authorName: row.author_name,
    answered: row.answered,
    createdAt: row.created_at,
  };
}

export async function listQuestions() {
  const { rows } = await getPool().query<QuestionRow>(
    `SELECT id, user_id, body, topic, author_name, answered, created_at
     FROM public.questions
     ORDER BY created_at DESC`,
  );
  return rows.map(mapQuestion);
}

export async function createQuestion({
  userId,
  body,
  topic,
  authorName,
}: {
  userId: string;
  body: string;
  topic: string;
  authorName: string;
}) {
  const text = String(body ?? '').trim();
  const chosenTopic = String(topic ?? 'general');
  if (!TOPICS.has(chosenTopic)) {
    throw publicError(400, 'Invalid question topic.');
  }
  const { rows } = await getPool().query<QuestionRow>(
    `INSERT INTO public.questions (user_id, body, topic, author_name)
     VALUES ($1, $2, $3, $4)
     RETURNING id, user_id, body, topic, author_name, answered, created_at`,
    [userId, text, chosenTopic, String(authorName ?? '').trim()],
  );
  return mapQuestion(rows[0]!);
}
