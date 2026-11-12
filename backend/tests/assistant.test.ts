import assert from 'node:assert/strict';
import type { Server } from 'node:http';
import { after, before, beforeEach, test } from 'node:test';

import { createApp } from '../src/app.js';
import { resetRateLimit } from '../src/middleware/rate-limit.js';
import { setUserResolverOverride } from '../src/middleware/require-user.js';
import {
  setAssistantModelTurnOverride,
  type AssistantModelTurn,
} from '../src/services/assistant-agent.js';
import {
  createMemoryProfileStore,
  setProfileStoreOverride,
} from '../src/services/profile-service.js';
import {
  createMemorySavedStore,
  setSavedStoreOverride,
} from '../src/services/saved-items-service.js';
import {
  createMemoryQuestionStore,
  setQuestionStoreOverride,
} from '../src/services/questions-service.js';
import {
  createMemoryPollStore,
  setPollStoreOverride,
} from '../src/services/poll-service.js';

const USER_A = '11111111-1111-4111-8111-111111111111';
const USER_B = '22222222-2222-4222-8222-222222222222';
let server: Server;
let baseUrl: string;

type Reply = {
  answer?: string;
  grounded?: boolean;
  sources?: Array<{ type: string; id: string }>;
  error?: string;
  code?: string;
};

before(async () => {
  const profiles = createMemoryProfileStore();
  await profiles.upsert({
    userId: USER_A,
    fullName: 'Huda Latheef',
    organization: 'NTAM',
    phone: '+971 50 123 4567',
  });
  await profiles.upsert({
    userId: USER_B,
    fullName: 'Amira Hassan',
    organization: 'Other Hospital',
    phone: '+971 54 987 6543',
  });
  setProfileStoreOverride(profiles);

  const saved = createMemorySavedStore();
  await saved.save(USER_A, 'session', 'opening');
  await saved.save(USER_A, 'resource', 'programme');
  await saved.save(USER_A, 'speaker', 'sarah');
  await saved.save(USER_B, 'session', 'closing');
  setSavedStoreOverride(saved);
  setQuestionStoreOverride(createMemoryQuestionStore());
  setPollStoreOverride(createMemoryPollStore());

  setUserResolverOverride(async (token) => {
    if (token === 'user-a') return { id: USER_A, email: 'huda@example.com' };
    if (token === 'user-b') return { id: USER_B, email: 'amira@example.com' };
    throw new Error('Invalid test credentials');
  });
  server = createApp().listen(0, '127.0.0.1');
  await new Promise<void>((resolve) => server.once('listening', resolve));
  const address = server.address();
  assert.ok(address && typeof address === 'object');
  baseUrl = 'http://127.0.0.1:' + address.port;
});

after(async () => {
  setAssistantModelTurnOverride(null);
  setUserResolverOverride(null);
  setProfileStoreOverride(null);
  setSavedStoreOverride(null);
  setQuestionStoreOverride(null);
  setPollStoreOverride(null);
  await new Promise<void>((resolve, reject) =>
    server.close((error) => (error ? reject(error) : resolve())),
  );
});

beforeEach(() => {
  resetRateLimit();
  setAssistantModelTurnOverride(null);
});

async function ask(
  question: string,
  token?: string,
  extra: Record<string, unknown> = {},
) {
  const response = await fetch(baseUrl + '/api/assistant/ask', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: 'Bearer ' + token } : {}),
    },
    body: JSON.stringify({ question, ...extra }),
  });
  return { status: response.status, body: await response.json() as Reply };
}

function toolResponse(contents: Array<{ parts?: unknown[] }>) {
  const finalContent = contents[contents.length - 1];
  const part = finalContent?.parts?.[0] as {
    functionResponse?: { response?: Record<string, unknown> };
  };
  return part?.functionResponse?.response ?? {};
}

test('anonymous prompts are rejected before model invocation', async () => {
  let calls = 0;
  setAssistantModelTurnOverride(async () => {
    calls++;
    return { text: 'not allowed', calls: [] };
  });
  const response = await ask('my mobile number?');
  assert.equal(response.status, 401);
  assert.equal(calls, 0);
});

test('the model uses a scoped profile tool and returns the REAL saved phone', async () => {
  const observations: Record<string, unknown>[] = [];
  setAssistantModelTurnOverride(async ({ contents, round }): Promise<AssistantModelTurn> => {
    if (round === 0) {
      return {
        text: '',
        calls: [{ name: 'get_my_profile_field', args: { field: 'phone' } }],
      };
    }
    const data = toolResponse(contents);
    observations.push(data);
    return {
      text: 'Your mobile number is ' + String(data.value),
      calls: [],
    };
  });
  const a = await ask('What is my mobile number?', 'user-a');
  const b = await ask('What is my mobile number?', 'user-b');
  assert.equal(a.status, 200);
  assert.equal(b.status, 200);
  assert.match(a.body.answer ?? '', /\+971 50 123 4567/);
  assert.match(b.body.answer ?? '', /\+971 54 987 6543/);
  assert.equal(a.body.grounded, true);
  assert.equal(observations[0]?.value, '+971 50 123 4567');
  assert.equal(observations[1]?.value, '+971 54 987 6543');
});

test('multi-part requests combine separate tools without cross-account leakage', async () => {
  setAssistantModelTurnOverride(async ({ contents, round }) => {
    if (round === 0) {
      return {
        text: '',
        calls: [
          { name: 'get_my_profile_field', args: { field: 'name' } },
          { name: 'get_my_saved_items', args: {} },
        ],
      };
    }
    const parts = contents.at(-1)?.parts ?? [];
    const results = parts.map((part) =>
      (part as { functionResponse?: { response?: Record<string, unknown> } })
        .functionResponse?.response ?? {},
    );
    return {
      text: JSON.stringify(results),
      calls: [],
    };
  });
  const a = await ask('What is my name and saved sessions?', 'user-a');
  const b = await ask('What is my name and saved sessions?', 'user-b');
  assert.equal(a.status, 200);
  assert.equal(a.body.grounded, true);
  assert.match(a.body.answer ?? '', /Huda Latheef/);
  assert.match(a.body.answer ?? '', /Opening Ceremony/);
  assert.doesNotMatch(a.body.answer ?? '', /Amira Hassan|Closing Keynote/);
  assert.match(b.body.answer ?? '', /Amira Hassan/);
  assert.doesNotMatch(b.body.answer ?? '', /Huda Latheef|Opening Ceremony/);
});

test('catalogue evidence includes the source id and resource availability', async () => {
  setAssistantModelTurnOverride(async ({ contents, round }) => {
    if (round === 0) {
      return {
        text: '',
        calls: [{
          name: 'search_congress',
          args: { query: 'Pediatric Nutrition Guide pdf' },
        }],
      };
    }
    const data = toolResponse(contents);
    return {
      text: 'Verified catalogue: ' + JSON.stringify(data),
      calls: [],
    };
  });
  const r = await ask('What is in the Pediatric Nutrition Guide?', 'user-a');
  assert.equal(r.status, 200);
  assert.ok(r.body.sources?.some((s) =>
    s.type === 'resource' && s.id === 'pediatric-guide'));
  assert.match(r.body.answer ?? '', /no downloadable PDF/i);
});

test('Q&A and polls use live tools with the authenticated user', async () => {
  setAssistantModelTurnOverride(async ({ contents, round }) => {
    if (round === 0) {
      return {
        text: '',
        calls: [
          { name: 'get_my_questions', args: {} },
          { name: 'get_active_polls', args: {} },
        ],
      };
    }
    const parts = contents.at(-1)?.parts ?? [];
    const responses = parts.map((part) =>
      (part as { functionResponse?: { response?: Record<string, unknown> } })
        .functionResponse?.response ?? {},
    );
    return { text: JSON.stringify(responses), calls: [] };
  });
  const r = await ask('What were my questions and what polls are open?', 'user-a');
  assert.equal(r.status, 200);
  assert.match(r.body.answer ?? '', /How does this session apply in clinic today/);
  assert.doesNotMatch(r.body.answer ?? '', /Which endpoints matter most/);
  assert.match(r.body.answer ?? '', /Which innovation will have the greatest impact/);
});

test('malicious account id passed by model cannot override signed-in account', async () => {
  setAssistantModelTurnOverride(async ({ round }) => {
    if (round === 0) {
      return {
        text: '',
        calls: [{
          name: 'get_my_profile_field',
          args: { field: 'phone', userId: USER_B },
        }],
      };
    }
    return { text: 'I do not have access to that.', calls: [] };
  });
  const r = await ask('Find another attendee phone', 'user-a');
  assert.equal(r.status, 200);
  assert.equal(r.body.grounded, false);
  assert.doesNotMatch(r.body.answer ?? '', /\+971/);
});

test('model cannot call arbitrary read/write tools', async () => {
  setAssistantModelTurnOverride(async ({ round }) => round === 0
    ? { text: '', calls: [{ name: 'execute_sql', args: { sql: 'DROP TABLE users' } }] }
    : { text: 'no', calls: [] });
  const r = await ask('delete user records', 'user-a');
  assert.equal(r.status, 200);
  assert.equal(r.body.grounded, false);
  assert.deepEqual(r.body.sources, []);
});

test('requests with client-controlled account IDs and empty prompts are rejected', async () => {
  assert.equal((await ask('my profile', 'user-a', { userId: USER_B })).status, 400);
  assert.equal((await ask('x', 'user-a')).status, 400);
});

test('without Gemini configuration, server reports a safe 503 error', async () => {
  setAssistantModelTurnOverride(null);
  const previous = process.env.GEMINI_API_KEY;
  delete process.env.GEMINI_API_KEY;
  try {
    const result = await ask('When is the opening ceremony?', 'user-a');
    assert.equal(result.status, 503);
    assert.equal(result.body.error, 'The assistant is not configured.');
  } finally {
    if (previous === undefined) delete process.env.GEMINI_API_KEY;
    else process.env.GEMINI_API_KEY = previous;
  }
});

test('favorite speaker tool provides owned favorites and their sessions', async () => {
  setAssistantModelTurnOverride(async ({ contents, round }) => {
    if (round === 0) {
      return { text: '', calls: [{ name: 'get_my_saved_items', args: {} }] };
    }
    const parts = contents.at(-1)?.parts ?? [];
    const data = (parts[0] as {
      functionResponse?: { response?: { items?: unknown[] } };
    })?.functionResponse?.response ?? {};
    return { text: JSON.stringify(data.items ?? []), calls: [] };
  });
  const huda = await ask('Which speakers did I favorite, and what are their sessions?', 'user-a');
  const amira = await ask('Which speakers did I favorite, and what are their sessions?', 'user-b');
  assert.equal(huda.status, 200);
  assert.equal(huda.body.grounded, true);
  assert.match(huda.body.answer ?? '', /Dr. Sarah Johnson/);
  assert.match(huda.body.answer ?? '', /Future of Pediatric Nutrition/);
  assert.ok(huda.body.sources?.some((item) => item.type === 'speaker' && item.id === 'sarah'));
  assert.doesNotMatch(amira.body.answer ?? '', /Dr. Sarah Johnson/);
});
