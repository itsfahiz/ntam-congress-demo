import { ZodError } from 'zod';

export function notFoundHandler(_req, res) {
  res.status(404).json({
    error: 'Not found',
  });
}

export function errorHandler(err, _req, res, _next) {
  if (err instanceof ZodError) {
    res.status(400).json({
      error: 'Invalid request',
      details: err.issues.map((issue) => ({
        path: issue.path.join('.'),
        message: issue.message,
      })),
    });
    return;
  }

  const status = err.status ?? 500;
  const message =
    status >= 500 ? 'Internal server error' : (err.message ?? 'Request failed');

  if (status >= 500) {
    console.error(err);
  }

  res.status(status).json({ error: message });
}
