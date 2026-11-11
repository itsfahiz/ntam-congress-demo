import type { AssistantReply, AssistantSource, RetrievalRecord } from '../types/contracts.js';
import { generateAnswer } from './gemini-service.js';
import { retrieve } from './retrieval-service.js';

export const UNAVAILABLE_ANSWER =
  'I do not have that information in the congress catalog.';

function uniqueSources(records: RetrievalRecord[]): AssistantSource[] {
  const seen = new Set<string>();
  const sources: AssistantSource[] = [];
  for (const record of records) {
    const key = `${record.type}:${record.id}`;
    if (seen.has(key)) continue;
    seen.add(key);
    sources.push({ type: record.type, id: record.id });
  }
  return sources;
}

export async function askAssistant(question: string): Promise<AssistantReply> {
  const records = retrieve(question);
  if (records.length === 0) {
    return {
      answer: UNAVAILABLE_ANSWER,
      grounded: false,
      sources: [],
    };
  }

  const text = String((await generateAnswer({ question, records })) ?? '').trim();
  if (!text) {
    return {
      answer: UNAVAILABLE_ANSWER,
      grounded: false,
      sources: [],
    };
  }

  return {
    answer: text,
    grounded: true,
    sources: uniqueSources(records),
  };
}
