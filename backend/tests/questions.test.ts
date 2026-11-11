import assert from 'node:assert/strict';
import type { Server } from 'node:http';
import { after, before, test } from 'node:test';
import { createApp } from '../src/app.js';
import { setUserResolverOverride } from '../src/middleware/require-user.js';
import {
  MEMORY_QUESTION_1_ID,
  MEMORY_QUESTION_2_ID,
  createMemoryQuestionStore,
  setQuestionStoreOverride,
} from '../src/services/qa-service.js';

let server: Server;
let baseUrl: string;

before(async () => {
  setQuestionStoreOverride(createMemoryQuestionStore());
  setUserResolverOverride(async (token) => {
    if (token === 'user-a') {
      return {
        id: '11111111-1111-4111-8111-111111111111',
        email: 'huda@example.com',
        user_metadata: { full_name: 'Huda Latheef' },
      };
    }
    if (token === 'user-b') {
      return {
        id: '22222222-2222-4222-8222-222222222222',
        email: 'amira@example.com',
        user_metadata: { full_name: 'Amira Hassan' },
      };
    }
    throw new Error('unexpected token');
  });
  server = createApp().listen(0, '127.0.0.1');
  await new Promise<void>((resolve) => server.once('listening', resolve));
  const address = server.address();
  assert.ok(address && typeof address === 'object');
  baseUrl = `http://127.0.0.1:${address.port}`;
});

after(async () => {
  setQuestionStoreOverride(null);
  setUserResolverOverride(null);
  await new Promise<void>((resolve, reject) => {
    server.close((error) => (error ? reject(error) : resolve()));
  });
});

async function json(
  path: string,
  {
    token,
    method = 'GET',
    body,
  }: { token?: string; method?: string; body?: unknown } = {},
) {
  const response = await fetch(`${baseUrl}${path}`, {
    method,
    headers: {
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(body ? { 'Content-Type': 'application/json' } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const payload = (await response.json()) as {
    error?: string;
    questions?: {
      id: string;
      likeCount: number;
      replyCount: number;
      likedByMe: boolean;
      answered: boolean;
      createdAt: string;
      authorName: string;
    }[];
    question?: {
      id: string;
      likeCount: number;
      replyCount: number;
      likedByMe: boolean;
      answered: boolean;
    };
    replies?: {
      id: string;
      authorName: string;
      body: string;
      createdAt: string;
    }[];
    reply?: { id: string; authorName: string; body: string };
  };
  return { response, payload };
}

test('GET /api/questions without a token returns 401', async () => {
  const { response, payload } = await json('/api/questions');
  assert.equal(response.status, 401);
  assert.equal(payload.error, 'Sign in required.');
});

test('POST /api/questions without a token returns 401', async () => {
  const { response, payload } = await json('/api/questions', {
    method: 'POST',
    body: {
      body: 'How does this session apply in clinic today?',
      topic: 'nutrition',
    },
  });
  assert.equal(response.status, 401);
  assert.equal(payload.error, 'Sign in required.');
});

test('GET /api/questions returns recent questions with real like counts', async () => {
  const { response, payload } = await json('/api/questions', { token: 'user-a' });
  assert.equal(response.status, 200);
  assert.equal(payload.questions?.length, 2);
  assert.deepEqual(
    payload.questions?.map((question) => question.id),
    [MEMORY_QUESTION_2_ID, MEMORY_QUESTION_1_ID],
  );
  assert.equal(payload.questions?.[0]?.likeCount, 0);
  assert.equal(payload.questions?.[0]?.replyCount, 0);
  assert.equal(payload.questions?.[0]?.likedByMe, false);
  assert.equal(payload.questions?.[0]?.answered, false);
});

test('POST /api/questions/:id/like is unique per user and visible to others', async () => {
  const first = await json(`/api/questions/${MEMORY_QUESTION_1_ID}/like`, {
    token: 'user-a',
    method: 'POST',
  });
  assert.equal(first.response.status, 200);
  assert.equal(first.payload.question?.likeCount, 1);
  assert.equal(first.payload.question?.likedByMe, true);

  const duplicate = await json(`/api/questions/${MEMORY_QUESTION_1_ID}/like`, {
    token: 'user-a',
    method: 'POST',
  });
  assert.equal(duplicate.response.status, 200);
  assert.equal(duplicate.payload.question?.likeCount, 1);

  const other = await json('/api/questions', { token: 'user-b' });
  const q1 = other.payload.questions?.find(
    (question) => question.id === MEMORY_QUESTION_1_ID,
  );
  assert.equal(q1?.likeCount, 1);
  assert.equal(q1?.likedByMe, false);

  const second = await json(`/api/questions/${MEMORY_QUESTION_1_ID}/like`, {
    token: 'user-b',
    method: 'POST',
  });
  assert.equal(second.payload.question?.likeCount, 2);
  assert.equal(second.payload.question?.likedByMe, true);
});

test('DELETE /api/questions/:id/like is idempotent', async () => {
  const unlike = await json(`/api/questions/${MEMORY_QUESTION_1_ID}/like`, {
    token: 'user-a',
    method: 'DELETE',
  });
  assert.equal(unlike.response.status, 200);
  assert.equal(unlike.payload.question?.likeCount, 1);
  assert.equal(unlike.payload.question?.likedByMe, false);

  const again = await json(`/api/questions/${MEMORY_QUESTION_1_ID}/like`, {
    token: 'user-a',
    method: 'DELETE',
  });
  assert.equal(again.response.status, 200);
  assert.equal(again.payload.question?.likeCount, 1);
  assert.equal(again.payload.question?.likedByMe, false);
});

test('replies use the session author and stay visible across accounts', async () => {
  const created = await json(`/api/questions/${MEMORY_QUESTION_2_ID}/replies`, {
    token: 'user-b',
    method: 'POST',
    body: { body: 'Bedside endpoints should stay clinically meaningful.' },
  });
  assert.equal(created.response.status, 201);
  assert.equal(created.payload.reply?.authorName, 'Amira Hassan');
  assert.equal(
    created.payload.reply?.body,
    'Bedside endpoints should stay clinically meaningful.',
  );

  const listed = await json(`/api/questions/${MEMORY_QUESTION_2_ID}/replies`, {
    token: 'user-a',
  });
  assert.equal(listed.response.status, 200);
  assert.equal(listed.payload.replies?.length, 1);
  assert.equal(listed.payload.replies?.[0]?.authorName, 'Amira Hassan');
  assert.ok(listed.payload.replies?.[0]?.createdAt);

  const questions = await json('/api/questions', { token: 'user-a' });
  const q2 = questions.payload.questions?.find(
    (question) => question.id === MEMORY_QUESTION_2_ID,
  );
  assert.equal(q2?.replyCount, 1);
  assert.equal(q2?.answered, false);
});

test('POST /api/questions/:id/replies rejects a missing question and short body', async () => {
  const missing = await json(
    '/api/questions/00000000-0000-4000-8000-000000000099/replies',
    {
      token: 'user-a',
      method: 'POST',
      body: { body: 'This reply should not attach to a missing question.' },
    },
  );
  assert.equal(missing.response.status, 404);

  const short = await json(`/api/questions/${MEMORY_QUESTION_1_ID}/replies`, {
    token: 'user-a',
    method: 'POST',
    body: { body: 'x' },
  });
  assert.equal(short.response.status, 400);
});
