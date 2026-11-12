import { Router } from 'express';
import { z } from 'zod';
import { rateLimit } from '../middleware/rate-limit.js';
import { requireUser } from '../middleware/require-user.js';
import { askAuthenticatedAssistant } from '../services/assistant-agent.js';

export const assistantRouter = Router();

const askBody = z.strictObject({
  question: z.string().trim().min(2).max(500),
});

// Every AI request requires a verified Supabase JWT. The account ID is NEVER
// accepted from client JSON or from a Gemini tool invocation.
assistantRouter.post(
  '/assistant/ask',
  requireUser(),
  rateLimit(),
  async (req, res, next) => {
    try {
      const { question } = askBody.parse(req.body ?? {});
      const result = await askAuthenticatedAssistant(req.authUser!, question);
      res.json(result);
    } catch (error) {
      next(error);
    }
  },
);
