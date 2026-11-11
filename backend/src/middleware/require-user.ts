import type { RequestHandler } from 'express';
import type { AuthUser } from '../types/contracts.js';
import { publicError } from '../types/http.js';

type FetchImpl = typeof fetch;
type UserResolver = (token: string) => Promise<AuthUser>;

let userResolverOverride: UserResolver | null = null;

export function setUserResolverOverride(fn: UserResolver | null) {
  userResolverOverride = fn;
}

export function bearerToken(req: {
  headers: { authorization?: string | string[] };
}) {
  const header = String(req.headers.authorization ?? '');
  if (!header.toLowerCase().startsWith('bearer ')) return '';
  return header.slice(7).trim();
}

export async function resolveSupabaseUser(
  token: string,
  { fetchImpl }: { fetchImpl?: FetchImpl } = {},
): Promise<AuthUser> {
  if (!token) {
    throw publicError(401, 'Sign in required.', 'unauthorized');
  }
  if (userResolverOverride) {
    return userResolverOverride(token);
  }
  const baseUrl = process.env.SUPABASE_URL?.trim();
  const anonKey = process.env.SUPABASE_ANON_KEY?.trim();
  if (!baseUrl || !anonKey) {
    throw publicError(503, 'Authentication is not configured.', 'not_configured');
  }

  const fetchFn = fetchImpl ?? fetch;
  const response = await fetchFn(`${baseUrl.replace(/\/$/, '')}/auth/v1/user`, {
    headers: {
      Authorization: `Bearer ${token}`,
      apikey: anonKey,
    },
  });
  if (!response.ok) {
    throw publicError(401, 'Session expired. Please sign in again.', 'unauthorized');
  }
  const user = (await response.json()) as AuthUser;
  if (!user?.id) {
    throw publicError(401, 'Session expired. Please sign in again.', 'unauthorized');
  }
  return user;
}

export function requireUser({
  fetchImpl,
}: {
  fetchImpl?: FetchImpl;
} = {}): RequestHandler {
  return async (req, _res, next) => {
    try {
      req.authUser = await resolveSupabaseUser(bearerToken(req), { fetchImpl });
      next();
    } catch (error) {
      next(error);
    }
  };
}
