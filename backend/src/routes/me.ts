import { Router } from 'express';
import { z } from 'zod';
import { requireUser } from '../middleware/require-user.js';
import { getProfile, upsertProfile } from '../services/profile-service.js';

export const meRouter = Router();

const profileBody = z.strictObject({
  fullName: z.string().trim().min(2).max(80),
  organization: z.string().trim().max(80).default(''),
});

meRouter.use('/me', requireUser());

meRouter.get('/me', async (req, res, next) => {
  try {
    const authUser = req.authUser!;
    const profile = await getProfile(authUser.id);
    if (!profile) {
      res.status(404).json({ error: 'Attendee profile not found.' });
      return;
    }
    res.json({
      profile: {
        ...profile,
        email: authUser.email ?? null,
      },
    });
  } catch (error) {
    next(error);
  }
});

meRouter.post('/me', async (req, res, next) => {
  try {
    const authUser = req.authUser!;
    const body = profileBody.parse(req.body ?? {});
    const profile = await upsertProfile({
      userId: authUser.id,
      fullName: body.fullName,
      organization: body.organization,
    });
    res.json({
      profile: {
        ...profile,
        email: authUser.email ?? null,
      },
    });
  } catch (error) {
    next(error);
  }
});
