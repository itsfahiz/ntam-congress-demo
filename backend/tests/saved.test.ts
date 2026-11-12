import assert from 'node:assert/strict';
import type { Server } from 'node:http';
import { after, before, test } from 'node:test';
import { createApp } from '../src/app.js';
import { setUserResolverOverride } from '../src/middleware/require-user.js';
import {
  createMemorySavedStore,
  setSavedStoreOverride,
} from '../src/services/saved-items-service.js';

let server: Server;
let baseUrl: string;

before(async () => {
  setSavedStoreOverride(createMemorySavedStore());
  setUserResolverOverride(async (token) => {
    if (token === 'user-a') return { id: '11111111-1111-4111-8111-111111111111' };
    if (token === 'user-b') return { id: '22222222-2222-4222-8222-222222222222' };
    throw new Error('invalid test token');
  });
  server = createApp().listen(0, '127.0.0.1');
  await new Promise<void>((resolve) => server.once('listening', resolve));
  const address = server.address();
  assert.ok(address && typeof address === 'object');
  baseUrl = 'http://127.0.0.1:' + address.port;
});

after(async () => {
  setSavedStoreOverride(null);
  setUserResolverOverride(null);
  await new Promise<void>((resolve, reject) =>
    server.close((error) => (error ? reject(error) : resolve())),
  );
});

async function request(path: string, opts: {
  token?: string; method?: string; body?: unknown;
} = {}) {
  const response = await fetch(baseUrl + path, {
    method: opts.method ?? 'GET',
    headers: {
      ...(opts.token ? { Authorization: 'Bearer ' + opts.token } : {}),
      ...(opts.body ? { 'Content-Type': 'application/json' } : {}),
    },
    body: opts.body == null ? undefined : JSON.stringify(opts.body),
  });
  return {
    status: response.status,
    body: await response.json() as {
      items?: { itemType: string; itemId: string }[];
      saved?: boolean; removed?: boolean; error?: string;
    },
  };
}

test('saved items require a signed-in attendee', async () => {
  assert.equal((await request('/api/saved')).status, 401);
  assert.equal((await request('/api/saved', {
    method: 'POST', body: { itemType: 'session', itemId: 'opening' },
  })).status, 401);
});

test('sessions and resources persist together, remain idempotent and private', async () => {
  const session = { itemType: 'session', itemId: 'opening' };
  const resource = { itemType: 'resource', itemId: 'programme' };
  const first = await request('/api/saved', {
    token: 'user-a', method: 'POST', body: session,
  });
  assert.equal(first.status, 200);
  assert.equal((await request('/api/saved', {
    token: 'user-a', method: 'POST', body: session,
  })).status, 200);
  assert.equal((await request('/api/saved', {
    token: 'user-a', method: 'POST', body: resource,
  })).status, 200);

  const userA = await request('/api/saved', { token: 'user-a' });
  assert.equal(userA.status, 200);
  assert.deepEqual(
    userA.body.items?.map((item) => [item.itemType, item.itemId]).sort(),
    [['resource', 'programme'], ['session', 'opening']],
  );
  assert.deepEqual((await request('/api/saved', { token: 'user-b' })).body.items, []);

  const removed = await request('/api/saved/session/opening', {
    token: 'user-a', method: 'DELETE',
  });
  assert.equal(removed.status, 200);
  assert.equal(removed.body.removed, true);
  assert.deepEqual(
    (await request('/api/saved', { token: 'user-a' })).body.items?.map((item) => item.itemId),
    ['programme'],
  );
});

test('unknown catalog ids, invalid item types and extra body fields are rejected', async () => {
  assert.equal((await request('/api/saved', {
    token: 'user-a', method: 'POST',
    body: { itemType: 'session', itemId: 'fake-session' },
  })).status, 404);
  assert.equal((await request('/api/saved', {
    token: 'user-a', method: 'POST',
    body: { itemType: 'video', itemId: 'programme' },
  })).status, 400);
  assert.equal((await request('/api/saved', {
    token: 'user-a', method: 'POST',
    body: { itemType: 'resource', itemId: 'programme', userId: 'someone-else' },
  })).status, 400);
  assert.equal((await request('/api/saved/resource/fake-resource', {
    token: 'user-a', method: 'DELETE',
  })).status, 404);
});
