import type { NextFunction, Request, RequestHandler, Response } from 'express';
import type { AppError } from '../types/http.js';

const hitsByKey = new Map<string, number[]>();

export function resetRateLimit() {
  hitsByKey.clear();
}

function clientKey(req: Request) {
  return req.ip || req.socket?.remoteAddress || 'unknown';
}

export function rateLimit({
  max = Number.parseInt(process.env.ASSISTANT_RATE_LIMIT_MAX ?? '10', 10),
  windowMs = Number.parseInt(
    process.env.ASSISTANT_RATE_LIMIT_WINDOW_MS ?? '60000',
    10,
  ),
}: {
  max?: number;
  windowMs?: number;
} = {}): RequestHandler {
  const limit = Number.isFinite(max) && max > 0 ? max : 10;
  const window = Number.isFinite(windowMs) && windowMs > 0 ? windowMs : 60_000;

  return (req: Request, _res: Response, next: NextFunction) => {
    const now = Date.now();
    const key = clientKey(req);
    const recent = (hitsByKey.get(key) ?? []).filter((at) => now - at < window);
    if (recent.length >= limit) {
      const error = new Error('Too many requests. Try again shortly.') as AppError;
      error.status = 429;
      next(error);
      return;
    }
    recent.push(now);
    hitsByKey.set(key, recent);
    next();
  };
}
