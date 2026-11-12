import assert from 'node:assert/strict';
import type { Server } from 'node:http';
import { after, before, test } from 'node:test';
import { createApp } from '../src/app.js';
import { setUserResolverOverride } from '../src/middleware/require-user.js';
import {
  createMemoryProfileStore,
  setProfileStoreOverride,
} from '../src/services/profile-service.js';

let server: Server;
let baseUrl: string;

before(async () => {
  setProfileStoreOverride(createMemoryProfileStore());
  setUserResolverOverride(async (token) => {
    if (token === 'user-a') return {
      id: '11111111-1111-4111-8111-111111111111',
      email: 'huda@example.com',
    };
    if (token === 'user-b') return {
      id: '22222222-2222-4222-8222-222222222222',
      email: 'amira@example.com',
    };
    throw new Error('Invalid test credential');
  });
  server = createApp().listen(0, '127.0.0.1');
  await new Promise<void>((resolve) => server.once('listening', resolve));
  const address = server.address();
  assert.ok(address && typeof address === 'object');
  baseUrl = `http://127.0.0.1:${address.port}`;
});

after(async () => {
  setProfileStoreOverride(null);
  setUserResolverOverride(null);
  await new Promise<void>((resolve, reject) =>
    server.close((error) => (error ? reject(error) : resolve())),
  );
});

async function call(
  token: string | undefined,
  method: 'GET' | 'POST',
  payload?: Record<string, unknown>,
) {
  const response = await fetch(`${baseUrl}/api/me`, {
    method,
    headers: {
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(payload ? { 'Content-Type': 'application/json' } : {}),
    },
    body: payload ? JSON.stringify(payload) : undefined,
  });
  const data = await response.json() as {
    profile?: {
      fullName: string; organization: string; phone: string;
      badgeId: string; email: string; userId: string;
    };
    error?: string;
  };
  return { status: response.status, data };
}

test('profile endpoints reject anonymous requests', async () => {
  assert.equal((await call(undefined, 'GET')).status, 401);
  assert.equal((await call(undefined, 'POST', {
    fullName: 'Huda Latheef', organization: 'NTAM',
  })).status, 401);
});

test('a user can edit name, organization and phone without changing badge', async () => {
  const original = await call('user-a', 'POST', {
    fullName: 'Huda Latheef', organization: 'NTAM',
  });
  assert.equal(original.status, 200);
  assert.equal(original.data.profile?.phone, '');
  const badge = original.data.profile?.badgeId;

  const edited = await call('user-a', 'POST', {
    fullName: 'Huda Updated', organization: 'Dubai Clinic', phone: '+971 50 123 4567',
  });
  assert.equal(edited.status, 200);
  assert.equal(edited.data.profile?.phone, '+971 50 123 4567');
  assert.equal(edited.data.profile?.badgeId, badge);

  const fetched = await call('user-a', 'GET');
  assert.equal(fetched.data.profile?.fullName, 'Huda Updated');
  assert.equal(fetched.data.profile?.organization, 'Dubai Clinic');
  assert.equal(fetched.data.profile?.phone, '+971 50 123 4567');
  assert.equal(fetched.data.profile?.email, 'huda@example.com');

  // Legacy registration upserts that omit phone must not erase it.
  const legacy = await call('user-a', 'POST', {
    fullName: 'Huda Updated', organization: 'Dubai Clinic',
  });
  assert.equal(legacy.data.profile?.phone, '+971 50 123 4567');
});

test('a second user cannot read or modify someone else\'s profile', async () => {
  const absent = await call('user-b', 'GET');
  assert.equal(absent.status, 404);
  const forbidden = await call('user-b', 'POST', {
    fullName: 'Amira Hassan', organization: 'Hospital',
    phone: '+971501112233',
    userId: '11111111-1111-4111-8111-111111111111',
  });
  assert.equal(forbidden.status, 400);
  const own = await call('user-b', 'POST', {
    fullName: 'Amira Hassan', organization: 'Hospital', phone: '',
  });
  assert.equal(own.status, 200);
  assert.equal(own.data.profile?.email, 'amira@example.com');
  const huda = await call('user-a', 'GET');
  assert.equal(huda.data.profile?.fullName, 'Huda Updated');
});

test('invalid name and phone are rejected', async () => {
  for (const payload of [
    { fullName: 'A', organization: 'NTAM', phone: '' },
    { fullName: 'Huda Latheef', organization: 'NTAM', phone: '1234' },
    { fullName: 'Huda Latheef', organization: 'NTAM', phone: 'hello1234567' },
    { fullName: 'Huda Latheef', organization: 'NTAM', phone: '1234567890123456' },
  ]) {
    assert.equal((await call('user-a', 'POST', payload)).status, 400);
  }
});
