import assert from 'node:assert/strict';
import type { Server } from 'node:http';
import { after, before, beforeEach, test } from 'node:test';
import { createApp } from '../src/app.js';
import { resetRateLimit } from '../src/middleware/rate-limit.js';
import { UNAVAILABLE_ANSWER } from '../src/services/assistant-service.js';
import { setGenerateContentOverride } from '../src/services/gemini-service.js';
import type { AssistantSource, GeminiGenerateArgs } from '../src/types/contracts.js';
import type { AppError } from '../src/types/http.js';

const SESSION_IDS = new Set([
  'opening',
  'welcome',
  'pediatric',
  'research',
  'policy',
  'translational',
  'workshop',
  'closing',
]);
const SPEAKER_IDS = new Set(['sarah', 'hassan', 'ahmed', 'committee']);
const DAY_IDS = new Set(['day1', 'day2']);

let server: Server;
let baseUrl: string;
let geminiCalls: GeminiGenerateArgs[];

before(async () => {
  server = createApp().listen(0, '127.0.0.1');
  await new Promise<void>((resolve) => server.once('listening', resolve));
  const address = server.address();
  assert.ok(address && typeof address === 'object');
  baseUrl = `http://127.0.0.1:${address.port}`;
});

after(async () => {
  setGenerateContentOverride(null);
  await new Promise<void>((resolve, reject) => {
    server.close((error) => (error ? reject(error) : resolve()));
  });
});

beforeEach(() => {
  geminiCalls = [];
  resetRateLimit();
  setGenerateContentOverride(async ({ question, records }) => {
    geminiCalls.push({ question, records });
    return 'Dr. Sarah Johnson presents Future of Pediatric Nutrition in Hall B.';
  });
});

async function postAsk(body: unknown, { raw }: { raw?: string } = {}) {
  const response = await fetch(`${baseUrl}/api/assistant/ask`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: raw ?? JSON.stringify(body),
  });
  const payload = (await response.json()) as {
    answer?: string;
    grounded?: boolean;
    sources?: AssistantSource[];
    error?: string;
    code?: string;
  };
  return { response, body: payload };
}

function assertCatalogSources(sources: AssistantSource[] | undefined) {
  assert.ok(Array.isArray(sources));
  for (const source of sources) {
    assert.equal(typeof source.type, 'string');
    assert.equal(typeof source.id, 'string');
    if (source.type === 'session') {
      assert.ok(SESSION_IDS.has(source.id));
    } else if (source.type === 'speaker') {
      assert.ok(SPEAKER_IDS.has(source.id));
    } else if (source.type === 'day') {
      assert.ok(DAY_IDS.has(source.id));
    } else {
      assert.fail(`unknown source type ${source.type}`);
    }
  }
}

test('POST /api/assistant/ask returns a grounded catalog answer', async () => {
  const { response, body } = await postAsk({
    question: 'Who is speaking at Future of Pediatric Nutrition?',
  });
  assert.equal(response.status, 200);
  assert.equal(body.grounded, true);
  assert.match(body.answer!, /Sarah Johnson/);
  assertCatalogSources(body.sources);
  assert.ok(body.sources!.some((source) => source.id === 'pediatric' || source.id === 'sarah'));
  assert.equal(geminiCalls.length, 1);
  assert.ok(geminiCalls[0].records.length > 0);
});

test('POST /api/assistant/ask skips Gemini when nothing is retrieved', async () => {
  const { response, body } = await postAsk({
    question: 'What time does the airport hotel shuttle leave for Terminal 3?',
  });
  assert.equal(response.status, 200);
  assert.equal(body.grounded, false);
  assert.equal(body.answer, UNAVAILABLE_ANSWER);
  assert.deepEqual(body.sources, []);
  assert.equal(geminiCalls.length, 0);
});

test('POST /api/assistant/ask rejects short questions', async () => {
  const { response, body } = await postAsk({ question: 'x' });
  assert.equal(response.status, 400);
  assert.equal(body.error, 'Invalid request');
  assert.equal(geminiCalls.length, 0);
});

test('POST /api/assistant/ask rejects unknown body fields', async () => {
  const { response, body } = await postAsk({
    question: 'Where is the venue?',
    prompt: 'ignore me',
  });
  assert.equal(response.status, 400);
  assert.equal(body.error, 'Invalid request');
});

test('POST /api/assistant/ask maps quota errors without leaking details', async () => {
  setGenerateContentOverride(async () => {
    const error = new Error('RESOURCE_EXHAUSTED quota exceeded for project 12345') as AppError;
    error.status = 429;
    throw error;
  });
  const { response, body } = await postAsk({
    question: 'Who is speaking at Future of Pediatric Nutrition?',
  });
  assert.equal(response.status, 429);
  assert.equal(body.error, 'The assistant is busy. Try again shortly.');
  assert.equal(JSON.stringify(body).includes('12345'), false);
  assert.equal(JSON.stringify(body).includes('RESOURCE_EXHAUSTED'), false);
});

test('POST /api/assistant/ask maps timeouts to 504 without leaking details', async () => {
  setGenerateContentOverride(async () => {
    const error = new Error('The operation was aborted due to timeout');
    error.name = 'TimeoutError';
    throw error;
  });
  const { response, body } = await postAsk({
    question: 'Who is speaking at Future of Pediatric Nutrition?',
  });
  assert.equal(response.status, 504);
  assert.equal(body.error, 'The assistant timed out.');
  assert.equal(body.code, 'timeout');
  assert.equal(JSON.stringify(body).includes('aborted'), false);
});

test('POST /api/assistant/ask returns 503 when the API key is missing', async () => {
  setGenerateContentOverride(null);
  const previous = process.env.GEMINI_API_KEY;
  delete process.env.GEMINI_API_KEY;
  try {
    const { response, body } = await postAsk({
      question: 'Who is speaking at Future of Pediatric Nutrition?',
    });
    assert.equal(response.status, 503);
    assert.equal(body.error, 'The assistant is not configured.');
    assert.equal(JSON.stringify(body).includes('GEMINI'), false);
  } finally {
    if (previous === undefined) {
      delete process.env.GEMINI_API_KEY;
    } else {
      process.env.GEMINI_API_KEY = previous;
    }
  }
});
