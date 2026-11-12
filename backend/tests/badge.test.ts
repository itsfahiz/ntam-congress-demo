import assert from 'node:assert/strict';
import type { Server } from 'node:http';
import { after, before, test } from 'node:test';
import { createApp } from '../src/app.js';
import {
  buildVerifyUrl,
  issueBadge,
  isValidBadgeSignature,
  setProfileLookupOverride,
  setPublicBadgeLookupOverride,
  signBadgeId,
} from '../src/services/badge-service.js';

const SECRET = 'test-badge-signing-secret';
const ORIGIN = 'https://ntam-congress-api.onrender.com';
const BADGE_ID = 'NMC-1BAC3BF0';

let previousSecret: string | undefined;
let previousPublic: string | undefined;
let server: Server;
let baseUrl: string;

before(async () => {
  previousSecret = process.env.BADGE_SIGNING_SECRET;
  previousPublic = process.env.PUBLIC_BASE_URL;
  process.env.BADGE_SIGNING_SECRET = SECRET;
  process.env.PUBLIC_BASE_URL = ORIGIN;
  setPublicBadgeLookupOverride(async (badgeId) => {
    if (badgeId === BADGE_ID) {
      return { fullName: 'Huda Latheef', badgeId };
    }
    if (badgeId === 'NMC-XSS-1') {
      return { fullName: '<script>alert(1)</script>', badgeId };
    }
    return null;
  });
  server = createApp().listen(0, '127.0.0.1');
  await new Promise<void>((resolve) => server.once('listening', resolve));
  const address = server.address();
  assert.ok(address && typeof address === 'object');
  baseUrl = `http://127.0.0.1:${address.port}`;
});

after(async () => {
  setPublicBadgeLookupOverride(null);
  setProfileLookupOverride(null);
  if (previousSecret === undefined) delete process.env.BADGE_SIGNING_SECRET;
  else process.env.BADGE_SIGNING_SECRET = previousSecret;
  if (previousPublic === undefined) delete process.env.PUBLIC_BASE_URL;
  else process.env.PUBLIC_BASE_URL = previousPublic;
  await new Promise<void>((resolve, reject) => {
    server.close((error) => (error ? reject(error) : resolve()));
  });
});

test('HMAC-SHA256 signatures are 64 hex chars and verify the same badge id', () => {
  const signature = signBadgeId(BADGE_ID, SECRET);
  assert.match(signature, /^[a-f0-9]{64}$/);
  assert.equal(isValidBadgeSignature(BADGE_ID, signature, SECRET), true);
  assert.equal(isValidBadgeSignature(BADGE_ID, signature.toUpperCase(), SECRET), true);
});

test('tampered or swapped signatures fail verification', () => {
  const signature = signBadgeId(BADGE_ID, SECRET);
  const flipped = `${signature.slice(0, -1)}${signature.endsWith('a') ? 'b' : 'a'}`;
  assert.equal(isValidBadgeSignature(BADGE_ID, flipped, SECRET), false);
  assert.equal(isValidBadgeSignature('NMC-OTHER01', signature, SECRET), false);
  assert.equal(isValidBadgeSignature(BADGE_ID, 'not-a-signature', SECRET), false);
});

test('issueBadge returns a stable HTTPS verification URL for the profile badge', async () => {
  setProfileLookupOverride(async () => ({
    userId: '11111111-2222-3333-4444-555555555555',
    fullName: 'Huda Latheef',
    organization: 'NTAM',
    phone: '',
    badgeId: BADGE_ID,
    email: 'huda@example.com',
  }));
  const issued = await issueBadge(
    '11111111-2222-3333-4444-555555555555',
    ORIGIN,
  );
  const expected = buildVerifyUrl(ORIGIN, BADGE_ID, signBadgeId(BADGE_ID));
  assert.equal(issued.badgeId, BADGE_ID);
  assert.equal(issued.verifyUrl, expected);
  assert.equal(
    issued.verifyUrl,
    `${ORIGIN}/badge/verify?b=${BADGE_ID}&s=${signBadgeId(BADGE_ID)}`,
  );
  assert.doesNotMatch(issued.verifyUrl, /huda@example.com/);
  assert.doesNotMatch(issued.verifyUrl, /11111111-2222-3333-4444-555555555555/);
  setProfileLookupOverride(null);
});

test('GET /api/me/badge without a token returns 401', async () => {
  const response = await fetch(`${baseUrl}/api/me/badge`);
  const body = (await response.json()) as { error?: string };
  assert.equal(response.status, 401);
  assert.equal(body.error, 'Sign in required.');
});

test('GET /badge/verify accepts a signed badge that exists', async () => {
  const signature = signBadgeId(BADGE_ID);
  const response = await fetch(
    `${baseUrl}/badge/verify?b=${BADGE_ID}&s=${signature}`,
  );
  const html = await response.text();
  assert.equal(response.status, 200);
  assert.match(response.headers.get('content-type') ?? '', /text\/html/);
  assert.match(html, /Valid attendee/);
  assert.match(html, /Huda Latheef/);
  assert.match(html, /NMC-1BAC3BF0/);
  assert.doesNotMatch(html, /Invalid badge/);
  assert.doesNotMatch(html, /huda@example.com/i);
  assert.doesNotMatch(html, /user_id|userId|uuid/i);
});

test('GET /badge/verify rejects tampered, malformed, and unknown tokens', async () => {
  const signature = signBadgeId(BADGE_ID);
  const flipped = `${signature.slice(0, -1)}${signature.endsWith('a') ? 'b' : 'a'}`;
  const unknown = signBadgeId('NMC-MISSING1');

  const cases = [
    `${baseUrl}/badge/verify`,
    `${baseUrl}/badge/verify?b=not-a-badge&s=${signature}`,
    `${baseUrl}/badge/verify?b=${BADGE_ID}&s=short`,
    `${baseUrl}/badge/verify?b=${BADGE_ID}&s=${flipped}`,
    `${baseUrl}/badge/verify?b=NMC-MISSING1&s=${unknown}`,
  ];

  for (const url of cases) {
    const response = await fetch(url);
    const html = await response.text();
    assert.equal(response.status, 200, url);
    assert.match(html, /Invalid badge/, url);
    assert.doesNotMatch(html, /Valid attendee/, url);
    assert.doesNotMatch(html, /Huda Latheef/, url);
  }
});

test('GET /badge/verify escapes attendee names in HTML', async () => {
  const signature = signBadgeId('NMC-XSS-1');
  const response = await fetch(
    `${baseUrl}/badge/verify?b=NMC-XSS-1&s=${signature}`,
  );
  const html = await response.text();
  assert.equal(response.status, 200);
  assert.match(html, /Valid attendee/);
  assert.match(html, /&lt;script&gt;alert\(1\)&lt;\/script&gt;/);
  assert.doesNotMatch(html, /<script>alert\(1\)<\/script>/);
});

test('POST /badge/verify does not create badges', async () => {
  const response = await fetch(`${baseUrl}/badge/verify`, { method: 'POST' });
  const body = await response.text();
  assert.notEqual(response.status, 200);
  assert.doesNotMatch(body, /Valid attendee/);
});
