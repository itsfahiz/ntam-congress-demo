import type { GenerateContentFn, RetrievalRecord } from '../types/contracts.js';
import { publicError, type AppError } from '../types/http.js';

export const DEFAULT_GEMINI_MODEL = 'gemini-3.5-flash-lite';
export const FALLBACK_GEMINI_MODEL = 'gemini-3.8-flash';

const SYSTEM_INSTRUCTION = `You are the NTAM Nestlé Medical Congress assistant.
Answer only from the retrieved JSON records in the user message.
Do not invent sessions, speakers, times, rooms, dates, venues, or other event details.
If the records do not contain the answer, say you do not have that information in the congress catalog.
Do not give medical advice, diagnoses, dosages, or treatment recommendations. Programme copy is demo content, not clinical guidance.
Keep the answer concise and factual.`;

let generateContentOverride: GenerateContentFn | null = null;

export function setGenerateContentOverride(fn: GenerateContentFn | null) {
  generateContentOverride = fn;
}

type ProviderError = AppError & {
  statusCode?: number;
};

function asProviderError(error: unknown): ProviderError {
  return (error ?? {}) as ProviderError;
}

export function providerStatus(error: unknown) {
  const err = asProviderError(error);
  return Number(err.status ?? err.statusCode ?? err.code ?? 0);
}

export function looksLikeTimeout(error: unknown) {
  const err = asProviderError(error);
  const name = String(err.name ?? '');
  const message = String(err.message ?? '').toLowerCase();
  return (
    name === 'AbortError' ||
    name === 'TimeoutError' ||
    err.code === 'timeout' ||
    message.includes('aborted') ||
    message.includes('timeout') ||
    message.includes('timed out') ||
    message.includes('deadline')
  );
}

function looksLikeQuota(error: unknown) {
  const status = providerStatus(error);
  const message = String(asProviderError(error).message ?? '').toLowerCase();
  return (
    status === 429 ||
    message.includes('resource exhausted') ||
    message.includes('quota') ||
    message.includes('rate limit')
  );
}

function looksLikeInvalidArgument(error: unknown) {
  const status = providerStatus(error);
  const message = String(asProviderError(error).message ?? '').toLowerCase();
  return (
    status === 400 ||
    message.includes('invalid argument') ||
    message.includes('unknown name') ||
    message.includes('thinking')
  );
}

export function shouldFallback(error: unknown) {
  const err = asProviderError(error);
  if (looksLikeQuota(error) || err.public) return false;
  if (looksLikeTimeout(error) || looksLikeInvalidArgument(error)) return true;
  const status = providerStatus(error);
  const message = String(err.message ?? '').toLowerCase();
  return (
    status === 404 ||
    status === 500 ||
    status === 503 ||
    message.includes('not found') ||
    message.includes('not supported') ||
    message.includes('unavailable')
  );
}

export function mapProviderError(error: unknown) {
  if (looksLikeTimeout(error)) {
    return publicError(504, 'The assistant timed out.', 'timeout');
  }
  if (looksLikeQuota(error)) {
    return publicError(429, 'The assistant is busy. Try again shortly.', 'quota');
  }
  return publicError(
    503,
    'The assistant is temporarily unavailable.',
    'unavailable',
  );
}

function logProviderIssue({
  model,
  attempt,
  error,
}: {
  model: string;
  attempt: string;
  error: unknown;
}) {
  console.warn(
    JSON.stringify({
      event: 'gemini_provider',
      model,
      attempt,
      status: providerStatus(error) || undefined,
      timeout: looksLikeTimeout(error),
      quota: looksLikeQuota(error),
    }),
  );
}

function contextRecords(records: RetrievalRecord[]) {
  return records.map((record) => record.payload);
}

function buildUserPrompt(question: string, records: RetrievalRecord[]) {
  return [
    `Question: ${question}`,
    '',
    'Retrieved congress records (JSON):',
    JSON.stringify(contextRecords(records), null, 2),
  ].join('\n');
}

export function configuredModels() {
  const primary = process.env.GEMINI_MODEL?.trim() || DEFAULT_GEMINI_MODEL;
  const fallback =
    process.env.GEMINI_FALLBACK_MODEL?.trim() || FALLBACK_GEMINI_MODEL;
  return { primary, fallback };
}

function timeoutMs() {
  const parsed = Number.parseInt(process.env.GEMINI_TIMEOUT_MS ?? '25000', 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : 25000;
}

function thinkingConfig() {
  const raw = process.env.GEMINI_THINKING_BUDGET;
  if (raw === 'omit') return undefined;
  const budget = Number.parseInt(raw ?? '0', 10);
  if (!Number.isFinite(budget) || budget < 0) return { thinkingBudget: 0 };
  return { thinkingBudget: budget };
}

type GeminiCallArgs = {
  question: string;
  records: RetrievalRecord[];
  timeout: number;
};

async function callGemini(
  model: string,
  apiKey: string,
  { question, records, timeout }: GeminiCallArgs,
  { omitThinking = false }: { omitThinking?: boolean } = {},
) {
  const { GoogleGenAI } = await import('@google/genai');
  const ai = new GoogleGenAI({ apiKey });
  const signal = AbortSignal.timeout(timeout);
  const config: {
    systemInstruction: string;
    temperature: number;
    maxOutputTokens: number;
    abortSignal: AbortSignal;
    httpOptions: { timeout: number };
    thinkingConfig?: { thinkingBudget: number };
  } = {
    systemInstruction: SYSTEM_INSTRUCTION,
    temperature: 0.2,
    maxOutputTokens: 512,
    abortSignal: signal,
    httpOptions: { timeout },
  };
  const thinking = omitThinking ? undefined : thinkingConfig();
  if (thinking) {
    config.thinkingConfig = thinking;
  }

  const response = await ai.models.generateContent({
    model,
    contents: buildUserPrompt(question, records),
    config,
  });
  return String(response.text ?? '').trim();
}

function rethrowMapped(error: unknown): never {
  throw asProviderError(error).public ? error : mapProviderError(error);
}

async function callWithThinkingRetry(
  model: string,
  apiKey: string,
  args: GeminiCallArgs,
  attempt: string,
) {
  try {
    return await callGemini(model, apiKey, args);
  } catch (error) {
    if (looksLikeInvalidArgument(error) && thinkingConfig()) {
      logProviderIssue({ model, attempt: `${attempt}_no_thinking`, error });
      return callGemini(model, apiKey, args, { omitThinking: true });
    }
    throw error;
  }
}

export async function generateAnswer({
  question,
  records,
}: {
  question: string;
  records: RetrievalRecord[];
}) {
  if (generateContentOverride) {
    try {
      return await generateContentOverride({ question, records });
    } catch (error) {
      rethrowMapped(error);
    }
  }

  const apiKey = process.env.GEMINI_API_KEY?.trim();
  if (!apiKey) {
    throw publicError(503, 'The assistant is not configured.', 'not_configured');
  }

  const { primary, fallback } = configuredModels();
  const timeout = timeoutMs();
  const args = { question, records, timeout };

  try {
    return await callWithThinkingRetry(primary, apiKey, args, 'primary');
  } catch (error) {
    logProviderIssue({ model: primary, attempt: 'primary', error });
    if (asProviderError(error).public) throw error;
    if (shouldFallback(error) && fallback && fallback !== primary) {
      try {
        return await callWithThinkingRetry(fallback, apiKey, args, 'fallback');
      } catch (fallbackError) {
        logProviderIssue({
          model: fallback,
          attempt: 'fallback',
          error: fallbackError,
        });
        rethrowMapped(fallbackError);
      }
    }
    rethrowMapped(error);
  }
}
