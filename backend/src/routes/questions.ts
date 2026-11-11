import { Router } from 'express';
import { z } from 'zod';
import { requireUser } from '../middleware/require-user.js';
import { getProfile } from '../services/profile-service.js';
import { createQuestion, listQuestions } from '../services/questions-service.js';

export const questionsRouter = Router();

const createBody = z.strictObject({
  body: z.string().trim().min(12).max(240),
  topic: z.enum(['general', 'nutrition', 'research', 'clinical']),
});

questionsRouter.use('/questions', requireUser());

questionsRouter.get('/questions', async (_req, res, next) => {
  try {
    res.json({ questions: await listQuestions() });
  } catch (error) {
    next(error);
  }
});

questionsRouter.post('/questions', async (req, res, next) => {
  try {
    const authUser = req.authUser!;
    const payload = createBody.parse(req.body ?? {});
    const profile = await getProfile(authUser.id);
    const metadata = authUser.user_metadata ?? {};
    const authorName =
      profile?.fullName ||
      String(metadata.full_name ?? metadata.fullName ?? '').trim() ||
      String(authUser.email ?? 'Attendee');
    const question = await createQuestion({
      userId: authUser.id,
      body: payload.body,
      topic: payload.topic,
      authorName,
    });
    res.status(201).json({ question });
  } catch (error) {
    next(error);
  }
});
