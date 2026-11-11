import { event, sessions, speakers } from '../../data/catalog.js';
import type {
  DayPayload,
  RetrievalRecord,
  SessionPayload,
  SpeakerPayload,
} from '../types/contracts.js';

const TOP_K = 3;
const MIN_SCORE = 3;

const STOPWORDS = new Set([
  'a',
  'an',
  'the',
  'is',
  'are',
  'was',
  'were',
  'be',
  'been',
  'at',
  'on',
  'in',
  'of',
  'for',
  'to',
  'and',
  'or',
  'but',
  'it',
  'its',
  'this',
  'that',
  'with',
  'from',
  'as',
  'by',
  'please',
  'tell',
  'me',
  'about',
  'can',
  'you',
  'i',
  'we',
  'do',
  'does',
  'did',
  'will',
  'would',
  'should',
  'could',
  'just',
  'any',
  'all',
  'also',
  'into',
  'who',
  'what',
  'which',
]);

type RetrievalDocument =
  | { type: 'day'; id: string; tokens: Set<string>; payload: DayPayload }
  | { type: 'speaker'; id: string; tokens: Set<string>; payload: SpeakerPayload }
  | { type: 'session'; id: string; tokens: Set<string>; payload: SessionPayload };

type RankedRecord = RetrievalRecord & { score: number };

function normalize(text: string) {
  return String(text)
    .toLowerCase()
    .replace(/wi-?fi/gi, 'wifi')
    .replace(/paediatric/gi, 'pediatric')
    .replace(/centre/gi, 'center');
}

export function tokenize(text: string) {
  return normalize(text)
    .replace(/[^a-z0-9]+/g, ' ')
    .trim()
    .split(/\s+/)
    .filter((token) => token.length >= 2 && !STOPWORDS.has(token));
}

function uniqueTokens(text: string) {
  return new Set(tokenize(text));
}

function buildDocuments(): RetrievalDocument[] {
  const dayDocs: RetrievalDocument[] = event.days.map((day) => {
    const payload: DayPayload = {
      type: 'day',
      id: day.id,
      shortLabel: day.shortLabel,
      dateShort: day.dateShort,
      headline: day.headline,
      dateLong: day.dateLong,
      eventTitle: event.title,
      eventDateLabel: event.dateLabel,
      eventLocation: event.location,
      venue: event.venue,
    };
    const text = [
      'venue',
      event.title,
      event.dateLabel,
      event.location,
      day.shortLabel,
      day.dateShort,
      day.headline,
      day.dateLong,
      event.venue.name,
      event.venue.dateLabel,
      event.venue.address,
      event.venue.facilities.join(' '),
    ].join(' ');
    return { type: 'day', id: day.id, tokens: uniqueTokens(text), payload };
  });

  const speakerDocs: RetrievalDocument[] = speakers.map((speaker) => {
    const payload: SpeakerPayload = { type: 'speaker', ...speaker };
    const text = [speaker.fullName, speaker.title, speaker.country].join(' ');
    return {
      type: 'speaker',
      id: speaker.id,
      tokens: uniqueTokens(text),
      payload,
    };
  });

  const sessionDocs: RetrievalDocument[] = sessions.map((session) => {
    const speaker = speakers.find((item) => item.id === session.speakerId);
    const day = event.days.find((item) => item.id === session.day);
    const payload: SessionPayload = {
      type: 'session',
      ...session,
      speakerName: speaker?.fullName ?? null,
      dayLabel: day?.dateLong ?? session.day,
    };
    const text = [
      session.title,
      session.summary,
      session.location,
      session.timeLabel,
      session.track,
    ].join(' ');
    return {
      type: 'session',
      id: session.id,
      tokens: uniqueTokens(text),
      payload,
    };
  });

  return [...dayDocs, ...speakerDocs, ...sessionDocs];
}

const DOCUMENTS = buildDocuments();

function tokenScore(queryTokens: string[], docTokens: Set<string>) {
  let score = 0;
  for (const token of queryTokens) {
    if (docTokens.has(token)) score += 2;
  }
  return score;
}

function phraseBonus(question: string, doc: RetrievalDocument) {
  const q = normalize(question);
  if (doc.type === 'session') {
    const title = normalize(doc.payload.title);
    if (title.length >= 8 && q.includes(title)) return 14;
  }
  if (doc.type === 'speaker') {
    const name = normalize(doc.payload.fullName).replace(/^dr\.?\s+/, '');
    if (name.length >= 6 && q.includes(name)) return 14;
  }
  if (doc.type === 'day') {
    const venue = normalize(doc.payload.venue?.name ?? '');
    if (venue.length >= 10 && q.includes(venue)) return 8;
  }
  return 0;
}

/**
 * Lightweight lexical retrieval over the static congress catalog.
 * Source IDs are only catalog ids: sessions, speakers, and days.
 */
export function retrieve(
  question: string,
  { limit = TOP_K, minScore = MIN_SCORE }: { limit?: number; minScore?: number } = {},
): RetrievalRecord[] {
  const queryTokens = tokenize(question);
  if (queryTokens.length === 0) return [];

  const ranked: RankedRecord[] = DOCUMENTS.map((doc) => ({
    type: doc.type,
    id: doc.id,
    payload: doc.payload,
    score: tokenScore(queryTokens, doc.tokens) + phraseBonus(question, doc),
  } as RankedRecord))
    .filter((doc) => doc.score >= minScore)
    .sort(
      (a, b) =>
        b.score - a.score ||
        a.type.localeCompare(b.type) ||
        a.id.localeCompare(b.id),
    );

  if (ranked.length === 0) return [];

  const cutoff = Math.max(minScore, ranked[0].score * 0.75);
  const selected: Array<RetrievalRecord & { score?: number }> = ranked
    .filter((doc) => doc.score >= cutoff)
    .slice(0, limit);

  const bestSession =
    selected.find((doc) => doc.type === 'session') ??
    ranked.find((doc) => doc.type === 'session' && doc.score >= cutoff);
  const speakerId =
    bestSession?.type === 'session' ? bestSession.payload.speakerId : undefined;
  if (speakerId && !selected.some((doc) => doc.type === 'speaker' && doc.id === speakerId)) {
    const speakerDoc = DOCUMENTS.find(
      (doc): doc is Extract<RetrievalDocument, { type: 'speaker' }> =>
        doc.type === 'speaker' && doc.id === speakerId,
    );
    if (speakerDoc) {
      selected.push({
        type: 'speaker',
        id: speakerDoc.id,
        payload: speakerDoc.payload,
      });
    }
  }

  return selected.map(({ type, id, payload }) => ({ type, id, payload }) as RetrievalRecord);
}
