import assert from 'node:assert/strict';
import type { Server } from 'node:http';
import { after, before, test } from 'node:test';
import { createApp } from '../src/app.js';

let server: Server;
let baseUrl: string;

before(async () => {
  server = createApp().listen(0, '127.0.0.1');
  await new Promise<void>((resolve) => server.once('listening', resolve));
  const address = server.address();
  assert.ok(address && typeof address === 'object');
  baseUrl = `http://127.0.0.1:${address.port}`;
});

after(async () => {
  await new Promise<void>((resolve, reject) => {
    server.close((error) => (error ? reject(error) : resolve()));
  });
});

test('GET /api/questions without a token returns 401', async () => {
  const response = await fetch(`${baseUrl}/api/questions`);
  const body = (await response.json()) as { error?: string };
  assert.equal(response.status, 401);
  assert.equal(body.error, 'Sign in required.');
});

test('POST /api/questions without a token returns 401', async () => {
  const response = await fetch(`${baseUrl}/api/questions`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      body: 'How does this session apply in clinic today?',
      topic: 'nutrition',
    }),
  });
  const body = (await response.json()) as { error?: string };
  assert.equal(response.status, 401);
  assert.equal(body.error, 'Sign in required.');
});
