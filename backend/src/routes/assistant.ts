import { Router } from 'express';
import { z } from 'zod';
import { rateLimit } from '../middleware/rate-limit.js';
import { askAssistant } from '../services/assistant-service.js';

export const assistantRouter = Router();

const askBody = z.strictObject({
  question: z.string().trim().min(2).max(500),
});

assistantRouter.post('/assistant/ask', rateLimit(), async (req, res, next) => {
  try {
    const { question } = askBody.parse(req.body ?? {});
    const result = await askAssistant(question);
    res.json(result);
  } catch (error) {
    next(error);
  }
});
