import { Router } from 'express';
import { z } from 'zod';
import { requireUser } from '../middleware/require-user.js';
import {
  createQuestion,
  createQuestionReply,
  likeQuestion,
  listQuestionReplies,
  listQuestions,
  resolveQuestionAuthor,
  unlikeQuestion,
} from '../services/qa-service.js';

export const questionsRouter = Router();

const createBody = z.strictObject({
  body: z.string().trim().min(12).max(240),
  topic: z.enum(['general', 'nutrition', 'research', 'clinical']),
});

const replyBody = z.strictObject({
  body: z.string().trim().min(2).max(240),
});

const questionIdParam = z.string().uuid();

questionsRouter.use('/questions', requireUser());

questionsRouter.get('/questions', async (req, res, next) => {
  try {
    res.json({ questions: await listQuestions(req.authUser!.id) });
  } catch (error) {
    next(error);
  }
});

questionsRouter.post('/questions', async (req, res, next) => {
  try {
    const authUser = req.authUser!;
    const payload = createBody.parse(req.body ?? {});
    const question = await createQuestion({
      userId: authUser.id,
      body: payload.body,
      topic: payload.topic,
      authorName: await resolveQuestionAuthor(authUser),
    });
    res.status(201).json({ question });
  } catch (error) {
    next(error);
  }
});

questionsRouter.get('/questions/:questionId/replies', async (req, res, next) => {
  try {
    const questionId = questionIdParam.parse(String(req.params.questionId ?? ''));
    res.json({ replies: await listQuestionReplies(questionId) });
  } catch (error) {
    next(error);
  }
});

questionsRouter.post('/questions/:questionId/replies', async (req, res, next) => {
  try {
    const authUser = req.authUser!;
    const questionId = questionIdParam.parse(String(req.params.questionId ?? ''));
    const payload = replyBody.parse(req.body ?? {});
    const reply = await createQuestionReply({
      userId: authUser.id,
      questionId,
      body: payload.body,
      authorName: await resolveQuestionAuthor(authUser),
    });
    res.status(201).json({ reply });
  } catch (error) {
    next(error);
  }
});

questionsRouter.post('/questions/:questionId/like', async (req, res, next) => {
  try {
    const questionId = questionIdParam.parse(String(req.params.questionId ?? ''));
    const question = await likeQuestion(req.authUser!.id, questionId);
    res.json({ question });
  } catch (error) {
    next(error);
  }
});

questionsRouter.delete('/questions/:questionId/like', async (req, res, next) => {
  try {
    const questionId = questionIdParam.parse(String(req.params.questionId ?? ''));
    const question = await unlikeQuestion(req.authUser!.id, questionId);
    res.json({ question });
  } catch (error) {
    next(error);
  }
});
