import assert from 'node:assert/strict';
import type { Server } from 'node:http';
import { after, before, test } from 'node:test';
import { createApp } from '../src/app.js';
import { setUserResolverOverride } from '../src/middleware/require-user.js';
import {
  SEEDED_OPTION_AI,
  SEEDED_OPTION_DIGITAL,
  SEEDED_POLL_ID,
  createMemoryPollStore,
  setPollStoreOverride,
} from '../src/services/poll-service.js';

let server: Server;
let baseUrl: string;

before(async () => {
  setPollStoreOverride(createMemoryPollStore());
  setUserResolverOverride(async (token) => {
    if (token === 'user-a') return { id: '11111111-1111-4111-8111-111111111111' };
    if (token === 'user-b') return { id: '22222222-2222-4222-8222-222222222222' };
    throw new Error('unexpected token');
  });
  server = createApp().listen(0, '127.0.0.1');
  await new Promise<void>((resolve) => server.once('listening', resolve));
  const address = server.address();
  assert.ok(address && typeof address === 'object');
  baseUrl = `http://127.0.0.1:${address.port}`;
});

after(async () => {
  setPollStoreOverride(null);
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
    code?: string;
    poll?: {
      id: string;
      question: string;
      totalVotes: number;
      myOptionId: string | null;
      options: { id: string; label: string; voteCount: number; percent: number }[];
    };
  };
  return { response, payload };
}

test('GET /api/polls/active without a token returns 401', async () => {
  const { response, payload } = await json('/api/polls/active');
  assert.equal(response.status, 401);
  assert.equal(payload.error, 'Sign in required.');
});

test('POST /api/polls/:id/vote without a token returns 401', async () => {
  const { response, payload } = await json(`/api/polls/${SEEDED_POLL_ID}/vote`, {
    method: 'POST',
    body: { optionId: SEEDED_OPTION_AI },
  });
  assert.equal(response.status, 401);
  assert.equal(payload.error, 'Sign in required.');
});

test('GET /api/polls/active returns the seeded poll', async () => {
  const { response, payload } = await json('/api/polls/active', { token: 'user-a' });
  assert.equal(response.status, 200);
  assert.equal(payload.poll?.id, SEEDED_POLL_ID);
  assert.equal(
    payload.poll?.question,
    'Which innovation will have the greatest impact on healthcare?',
  );
  assert.deepEqual(
    payload.poll?.options.map((option) => option.label),
    ['Artificial Intelligence', 'Personalized Nutrition', 'Digital Health'],
  );
});

test('POST /api/polls/:id/vote records a vote and returns live results', async () => {
  const { response, payload } = await json(`/api/polls/${SEEDED_POLL_ID}/vote`, {
    token: 'user-a',
    method: 'POST',
    body: { optionId: SEEDED_OPTION_AI },
  });
  assert.equal(response.status, 200);
  assert.equal(payload.poll?.myOptionId, SEEDED_OPTION_AI);
  assert.equal(payload.poll?.totalVotes, 1);
  const ai = payload.poll?.options.find((option) => option.id === SEEDED_OPTION_AI);
  assert.equal(ai?.voteCount, 1);
  assert.equal(ai?.percent, 100);
});

test('POST /api/polls/:id/vote rejects an option from another choice set', async () => {
  const { response, payload } = await json(`/api/polls/${SEEDED_POLL_ID}/vote`, {
    token: 'user-b',
    method: 'POST',
    body: { optionId: '00000000-0000-4000-8000-000000000099' },
  });
  assert.equal(response.status, 400);
  assert.equal(payload.error, 'That option is not part of this poll.');
});

test('POST /api/polls/:id/vote rejects a duplicate vote without changing it', async () => {
  const second = await json(`/api/polls/${SEEDED_POLL_ID}/vote`, {
    token: 'user-a',
    method: 'POST',
    body: { optionId: SEEDED_OPTION_DIGITAL },
  });
  assert.equal(second.response.status, 409);
  assert.equal(second.payload.error, 'You already voted in this poll.');
  assert.equal(second.payload.code, 'already_voted');

  const active = await json('/api/polls/active', { token: 'user-a' });
  assert.equal(active.payload.poll?.myOptionId, SEEDED_OPTION_AI);
  assert.equal(active.payload.poll?.totalVotes, 1);
});

test('GET /api/polls/active still shows the recorded vote when reopened', async () => {
  const { payload } = await json('/api/polls/active', { token: 'user-a' });
  assert.equal(payload.poll?.myOptionId, SEEDED_OPTION_AI);
  assert.equal(
    payload.poll?.options.find((option) => option.id === SEEDED_OPTION_AI)?.voteCount,
    1,
  );
});
