import assert from 'node:assert/strict';
import type { Server } from 'node:http';
import { after, before, test } from 'node:test';
import { createApp } from '../src/app.js';
import { speakerInitials } from '../src/services/catalog-service.js';

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

async function getJson(path: string) {
  const response = await fetch(`${baseUrl}${path}`);
  const body = (await response.json()) as {
    status?: string;
    service?: string;
    error?: string;
    event?: {
      title: string;
      dateLabel: string;
      location: string;
      venue: { name: string };
      days: { dateLong: string }[];
    };
    sessions?: { id: string; speakerName?: string | null; title?: string }[];
    speakers?: {
      id: string;
      initials?: string;
      featured?: boolean;
      listed?: boolean;
    }[];
  };
  return { response, body };
}

test('GET /health returns ok', async () => {
  const { response, body } = await getJson('/health');
  assert.equal(response.status, 200);
  assert.equal(body.status, 'ok');
  assert.equal(body.service, 'ntam-congress-api');
});

test('GET /api/event matches the Flutter featured event', async () => {
  const { response, body } = await getJson('/api/event');
  assert.equal(response.status, 200);
  assert.equal(body.event!.title, 'The Next Era of Nutrition & Health');
  assert.equal(body.event!.dateLabel, 'May 22 - 23, 2026');
  assert.equal(body.event!.location, 'Dubai, UAE');
  assert.equal(
    body.event!.venue.name,
    'Dubai International Convention & Exhibition Center',
  );
  assert.equal(body.event!.days.length, 2);
  assert.equal(body.event!.days[0].dateLong, 'Friday, May 22, 2026');
});

test('GET /api/sessions returns all eight catalog sessions', async () => {
  const { response, body } = await getJson('/api/sessions');
  assert.equal(response.status, 200);
  assert.equal(body.sessions!.length, 8);
  assert.equal(body.sessions![0].id, 'opening');
  assert.equal(body.sessions![0].speakerName, 'Congress Committee');
  assert.equal(body.sessions!.at(-1)!.id, 'closing');
});

test('GET /api/sessions filters by day and track', async () => {
  const day = await getJson('/api/sessions?day=day2');
  assert.equal(day.response.status, 200);
  assert.deepEqual(
    day.body.sessions!.map((session) => session.id),
    ['policy', 'translational', 'workshop', 'closing'],
  );

  const track = await getJson('/api/sessions?day=day1&track=nutrition');
  assert.equal(track.response.status, 200);
  assert.equal(track.body.sessions!.length, 1);
  assert.equal(track.body.sessions![0].title, 'Future of Pediatric Nutrition');
});

test('GET /api/sessions rejects unknown query fields', async () => {
  const { response, body } = await getJson('/api/sessions?day=day3');
  assert.equal(response.status, 400);
  assert.equal(body.error, 'Invalid request');
});

test('GET /api/speakers includes listed faculty and committee', async () => {
  const { response, body } = await getJson('/api/speakers');
  assert.equal(response.status, 200);
  assert.equal(body.speakers!.length, 4);
  const sarah = body.speakers!.find((speaker) => speaker.id === 'sarah');
  assert.equal(sarah!.initials, 'SJ');
  assert.equal(sarah!.featured, true);
  const committee = body.speakers!.find((speaker) => speaker.id === 'committee');
  assert.equal(committee!.listed, false);
});

test('GET /api/speakers?listed=true hides the committee host', async () => {
  const { response, body } = await getJson('/api/speakers?listed=true');
  assert.equal(response.status, 200);
  assert.deepEqual(
    body.speakers!.map((speaker) => speaker.id),
    ['sarah', 'hassan', 'ahmed'],
  );
});

test('unknown routes return 404', async () => {
  const { response, body } = await getJson('/api/missing');
  assert.equal(response.status, 404);
  assert.equal(body.error, 'Not found');
});

test('speaker initials skip Dr titles like Flutter', () => {
  assert.equal(speakerInitials('Dr. Sarah Johnson'), 'SJ');
  assert.equal(speakerInitials('Dr. Hassan Ali'), 'HA');
  assert.equal(speakerInitials('Congress Committee'), 'CC');
});
