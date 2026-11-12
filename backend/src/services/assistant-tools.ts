import { z } from 'zod';

import { sessions, speakers } from '../../data/catalog.js';
import { resources } from '../../data/resources.js';
import type { AssistantSource, AuthUser } from '../types/contracts.js';
import { getProfile } from './profile-service.js';
import { listSavedItems } from './saved-items-service.js';
import { listQuestions } from './questions-service.js';
import { listActivePolls } from './poll-service.js';
import { retrieve } from './retrieval-service.js';

/**
 * Read-only, allowlisted tools exposed to Gemini.
 * Never let the model choose an account id, SQL statement, URL or database table.
 */
export const assistantToolDeclarations = [
  {
    name: 'search_congress',
    description: 'Retrieve factual programme, session, speaker, resource and venue records for a congress question. Use for any event information, including session times, available resource files, speakers, facilities and dates.',
    parametersJsonSchema: {
      type: 'object',
      properties: {
        query: { type: 'string', description: 'Natural-language query to search the congress catalogue.' },
      },
      required: ['query'],
      additionalProperties: false,
    },
  },
  {
    name: 'get_my_profile_field',
    description: 'Read only ONE field from the signed-in attendee profile in PostgreSQL. Use for my name, my email, my phone/mobile, my organization or my badge/attendee ID. Never guess personal data.',
    parametersJsonSchema: {
      type: 'object',
      properties: {
        field: {
          type: 'string',
          enum: ['name', 'email', 'phone', 'organization', 'badge_id'],
          description: 'The single profile field required to answer the question.',
        },
      },
      required: ['field'],
      additionalProperties: false,
    },
  },
  {
    name: 'get_my_saved_items',
    description: "Read the signed-in attendee's saved sessions, resources and favorite speakers from PostgreSQL, including speaker sessions and titles. Useful for my saved items, favorite speakers and combined questions.",
    parametersJsonSchema: { type: 'object', properties: {}, additionalProperties: false },
  },
  {
    name: 'get_my_questions',
    description: 'Read only congress Q&A questions submitted by the signed-in attendee, including their topic, answered status and recent entries.',
    parametersJsonSchema: { type: 'object', properties: {}, additionalProperties: false },
  },
  {
    name: 'get_active_polls',
    description: 'Read the current congress polls and aggregated results. Indicates whether the signed-in attendee voted, and their selected option. Read only; never submit a vote.',
    parametersJsonSchema: { type: 'object', properties: {}, additionalProperties: false },
  },
] as const;

export type AssistantToolCall = {
  name: string;
  args?: Record<string, unknown>;
  id?: string;
};

export type AssistantToolResult = {
  data: Record<string, unknown>;
  sources: AssistantSource[];
  evidence: boolean;
};

const noArgs = z.strictObject({});
const searchArgs = z.strictObject({ query: z.string().trim().min(2).max(500) });
const fieldArgs = z.strictObject({
  field: z.enum(['name', 'email', 'phone', 'organization', 'badge_id']),
});

export async function executeAssistantTool(
  user: AuthUser,
  call: AssistantToolCall,
): Promise<AssistantToolResult> {
  const args = call.args ?? {};
  try {
    switch (call.name) {
      case 'search_congress': {
        const { query } = searchArgs.parse(args);
        const records = retrieve(query, { limit: 5 });
        return {
          data: {
            records: records.map((item) => item.payload),
            matches: records.length,
            ...(records.length === 0 ? { note: 'No matching congress catalogue facts.' } : {}),
          },
          sources: records.map(({ type, id }) => ({ type, id })),
          evidence: records.length > 0,
        };
      }
      case 'get_my_profile_field': {
        const { field } = fieldArgs.parse(args);
        const profile = await getProfile(user.id);
        const values: Record<typeof field, string | null> = {
          name: profile?.fullName ?? null,
          email: user.email ?? null,
          phone: profile?.phone || null,
          organization: profile?.organization || null,
          badge_id: profile?.badgeId ?? null,
        };
        const value = values[field];
        return {
          data: { field, value, available: value !== null },
          sources: [],
          evidence: true,
        };
      }
      case 'get_my_saved_items': {
        noArgs.parse(args);
        const saved = await listSavedItems(user.id);
        const items = saved.slice(0, 50).map((item) => {
          const session = item.itemType === 'session'
            ? sessions.find((row) => row.id === item.itemId)
            : undefined;
          const speaker = session
            ? speakers.find((person) => person.id === session.speakerId)
            : undefined;
          const resource = item.itemType === 'resource'
            ? resources.find((row) => row.id === item.itemId)
            : undefined;
          const favoriteSpeaker = item.itemType === 'speaker'
            ? speakers.find((person) => person.id === item.itemId && person.listed)
            : undefined;
          const presenterSessions = favoriteSpeaker
            ? sessions.filter((row) => row.speakerId === favoriteSpeaker.id)
            : [];
          return {
            type: item.itemType,
            id: item.itemId,
            title: session?.title ?? resource?.title ?? favoriteSpeaker?.fullName ?? 'Unknown catalogue item',
            ...(session ? {
              day: session.day,
              time: session.timeLabel,
              location: session.location,
              speaker: speaker?.fullName ?? null,
            } : {}),
            ...(favoriteSpeaker ? {
              role: favoriteSpeaker.title,
              country: favoriteSpeaker.country,
              sessions: presenterSessions.map((row) => ({
                id: row.id,
                title: row.title,
                day: row.day,
                time: row.timeLabel,
                location: row.location,
              })),
            } : {}),
          };
        });
        return {
          data: { count: saved.length, items, truncated: saved.length > items.length },
          sources: items.map((item) => ({ type: item.type, id: item.id })),
          evidence: true,
        };
      }
      case 'get_my_questions': {
        noArgs.parse(args);
        const all = await listQuestions(user.id);
        // The generic Q&A listing is public; restrict this tool to the caller's posts.
        const mine = all.filter((item) => item.userId === user.id);
        return {
          data: {
            count: mine.length,
            questions: mine.slice(0, 10).map((item) => ({
              body: item.body,
              topic: item.topic,
              answered: item.answered,
              likes: item.likeCount,
              replies: item.replyCount,
            })),
            truncated: mine.length > 10,
          },
          sources: [],
          evidence: true,
        };
      }
      case 'get_active_polls': {
        noArgs.parse(args);
        const polls = await listActivePolls(user.id);
        return {
          data: {
            count: polls.length,
            polls: polls.slice(0, 10).map((poll) => ({
              question: poll.question,
              topic: poll.topicLabel,
              totalVotes: poll.totalVotes,
              myOptionId: poll.myOptionId,
              options: poll.options.map((option) => ({
                id: option.id,
                label: option.label,
                votes: option.voteCount,
                percent: option.percent,
              })),
            })),
          },
          sources: [],
          evidence: true,
        };
      }
      default:
        return {
          data: { error: 'This tool is not allowed.' },
          sources: [],
          evidence: false,
        };
    }
  } catch (error) {
    if (error instanceof z.ZodError) {
      return {
        data: { error: 'Invalid tool parameters.' },
        sources: [],
        evidence: false,
      };
    }
    // Do not send database errors, credentials or internal stack traces to Gemini.
    throw error;
  }
}
