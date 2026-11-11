import type { ErrorRequestHandler, RequestHandler } from 'express';
import { ZodError } from 'zod';
import type { AppError } from '../types/http.js';

export const notFoundHandler: RequestHandler = (_req, res) => {
  res.status(404).json({
    error: 'Not found',
  });
};

function isZodError(error: unknown): error is ZodError {
  if (error instanceof ZodError) return true;
  if (typeof error !== 'object' || error === null) return false;
  const candidate = error as { name?: string; issues?: unknown };
  return (
    (candidate.name === 'ZodError' || candidate.name === '$ZodError') &&
    Array.isArray(candidate.issues)
  );
}

export const errorHandler: ErrorRequestHandler = (err, _req, res, _next) => {
  if (isZodError(err)) {
    const issues = err.issues ?? [];
    res.status(400).json({
      error: 'Invalid request',
      details: issues.map((issue) => ({
        path: Array.isArray(issue.path) ? issue.path.join('.') : '',
        message: issue.message,
      })),
    });
    return;
  }

  const error = err as AppError;

  if (error.type === 'entity.too.large') {
    res.status(413).json({ error: 'Request body too large' });
    return;
  }

  if (error instanceof SyntaxError && 'body' in error) {
    res.status(400).json({ error: 'Invalid JSON' });
    return;
  }

  const status = error.status ?? 500;
  const message =
    status < 500 || error.public
      ? (error.message ?? 'Request failed')
      : 'Internal server error';

  if (status >= 500 && !error.public) {
    console.error(error);
  }

  const payload: { error: string; code?: string } = { error: message };
  if (typeof error.code === 'string' && /^[a-z_]+$/.test(error.code)) {
    payload.code = error.code;
  }
  res.status(status).json(payload);
};
