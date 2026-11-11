import { Router } from 'express';
import { z } from 'zod';
import { requireUser } from '../middleware/require-user.js';
import {
  getActivePoll,
  listActivePolls,
  voteOnPoll,
} from '../services/poll-service.js';

export const pollsRouter = Router();

const voteBody = z.strictObject({
  optionId: z.string().uuid(),
});

const pollIdParam = z.string().uuid();

pollsRouter.use('/polls', requireUser());

pollsRouter.get('/polls/active', async (req, res, next) => {
  try {
    const poll = await getActivePoll(req.authUser!.id);
    if (!poll) {
      res.status(404).json({ error: 'No active poll.' });
      return;
    }
    res.json({ poll });
  } catch (error) {
    next(error);
  }
});

pollsRouter.get('/polls', async (req, res, next) => {
  try {
    const polls = await listActivePolls(req.authUser!.id);
    res.json({ polls });
  } catch (error) {
    next(error);
  }
});

pollsRouter.post('/polls/:pollId/vote', async (req, res, next) => {
  try {
    const pollId = pollIdParam.parse(String(req.params.pollId ?? ''));
    const body = voteBody.parse(req.body ?? {});
    const poll = await voteOnPoll(req.authUser!.id, pollId, body.optionId);
    res.json({ poll });
  } catch (error) {
    next(error);
  }
});
