import assert from 'node:assert/strict';
import { test } from 'node:test';
import { retrieve } from '../src/services/retrieval-service.js';
import type { RetrievalRecord } from '../src/types/contracts.js';

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
const RESOURCE_IDS = new Set(['programme', 'pediatric-guide', 'keynote-slides', 'session-recap']);

function assertKnownSource(record: RetrievalRecord) {
  const sourceType = record.type;
  if (sourceType === 'session') {
    assert.ok(SESSION_IDS.has(record.id), `unknown session id ${record.id}`);
    return;
  }
  if (sourceType === 'speaker') {
    assert.ok(SPEAKER_IDS.has(record.id), `unknown speaker id ${record.id}`);
    return;
  }
  if (sourceType === 'day') {
    assert.ok(DAY_IDS.has(record.id), `unknown day id ${record.id}`);
    return;
  }
  if (sourceType === 'resource') {
    assert.ok(RESOURCE_IDS.has(record.id), `unknown resource id ${record.id}`);
    return;
  }
  const unexpected: never = sourceType;
  assert.fail(`unknown source type ${unexpected}`);
}

function assertDayHasEventFacts(record: RetrievalRecord) {
  assert.equal(record.type, 'day');
  if (record.type !== 'day') return;
  assert.match(record.payload.eventDateLabel, /May 22/);
  assert.match(record.payload.eventLocation, /Dubai/);
  assert.match(record.payload.venue.name, /Convention/);
}

test('retrieve finds the pediatric session and Sarah Johnson', () => {
  const records = retrieve(
    'Who is speaking at Future of Pediatric Nutrition?',
  );
  assert.ok(records.length > 0);
  records.forEach(assertKnownSource);
  assert.deepEqual(
    records.map((record) => `${record.type}:${record.id}`).sort(),
    ['session:pediatric', 'speaker:sarah'],
  );
});

test('retrieve finds the pediatric nutrition session from a natural speaker question', () => {
  const records = retrieve(
    'Tell me about the pediatric nutrition session and its speaker.',
  );
  assert.ok(records.length > 0);
  records.forEach(assertKnownSource);
  assert.ok(records.some((record) => record.type === 'session' && record.id === 'pediatric'));
  assert.ok(records.some((record) => record.type === 'speaker' && record.id === 'sarah'));
});

test('retrieve finds venue and dates from catalog days', () => {
  const records = retrieve(
    'Where is the Dubai International Convention venue and when is day 1?',
  );
  assert.ok(records.length > 0);
  records.forEach(assertKnownSource);
  assert.ok(records.some((record) => record.type === 'day'));
});

const EVENT_META_QUERIES = [
  'What are the dates and venue of the congress?',
  'When and where is the event?',
  'What date does the congress start?',
  'Where is the congress taking place?',
];

for (const question of EVENT_META_QUERIES) {
  test(`retrieve finds catalog dates and venue for: ${question}`, () => {
    const records = retrieve(question);
    assert.ok(records.length > 0, question);
    records.forEach(assertKnownSource);
    const days = records.filter((record) => record.type === 'day');
    assert.ok(days.length > 0, `expected day evidence for: ${question}`);
    days.forEach(assertDayHasEventFacts);
  });
}

test('retrieve returns nothing when the catalog has no match', () => {
  const records = retrieve(
    'What time does the airport hotel shuttle leave for Terminal 3?',
  );
  assert.deepEqual(records, []);
});

test('retrieval finds grounded downloadable demo resource availability', () => {
  const records = retrieve('What is in the Pediatric Nutrition Guide PDF?');
  const resource = records.find((record) =>
    record.type === 'resource' && record.id === 'pediatric-guide');
  assert.ok(resource && resource.type === 'resource');
  assert.match(resource.payload.availability, /available for download/i);
});
