import { Router } from 'express';
import { z } from 'zod';
import {
  getEvent,
  getSessions,
  getSpeakers,
} from '../services/catalog-service.js';

export const catalogRouter = Router();

const sessionsQuery = z
  .object({
    day: z.enum(['day1', 'day2']).optional(),
    track: z.enum(['keynote', 'nutrition', 'research']).optional(),
  })
  .strict();

const speakersQuery = z
  .object({
    listed: z
      .enum(['true', 'false'])
      .optional()
      .transform((value) => (value === undefined ? undefined : value === 'true')),
  })
  .strict();

catalogRouter.get('/event', (_req, res) => {
  res.json({ event: getEvent() });
});

catalogRouter.get('/sessions', (req, res, next) => {
  try {
    const query = sessionsQuery.parse(req.query);
    res.json({ sessions: getSessions(query) });
  } catch (error) {
    next(error);
  }
});

catalogRouter.get('/speakers', (req, res, next) => {
  try {
    const query = speakersQuery.parse(req.query);
    res.json({ speakers: getSpeakers(query) });
  } catch (error) {
    next(error);
  }
});
