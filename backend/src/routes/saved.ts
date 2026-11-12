import { Router } from 'express';
import { z } from 'zod';
import { requireUser } from '../middleware/require-user.js';
import {
  listSavedItems,
  removeItem,
  saveItem,
} from '../services/saved-items-service.js';

export const savedRouter = Router();
savedRouter.use('/saved', requireUser());

const itemType = z.enum(['session', 'resource']);
const itemId = z.string().regex(/^[a-z0-9-]{1,80}$/);
const saveBody = z.strictObject({ itemType, itemId });

savedRouter.get('/saved', async (req, res, next) => {
  try {
    res.json({ items: await listSavedItems(req.authUser!.id) });
  } catch (error) {
    next(error);
  }
});

savedRouter.post('/saved', async (req, res, next) => {
  try {
    const item = saveBody.parse(req.body ?? {});
    await saveItem(req.authUser!.id, item.itemType, item.itemId);
    res.json({ saved: true });
  } catch (error) {
    next(error);
  }
});

savedRouter.delete('/saved/:type/:id', async (req, res, next) => {
  try {
    const type = itemType.parse(String(req.params.type ?? ''));
    const id = itemId.parse(String(req.params.id ?? ''));
    await removeItem(req.authUser!.id, type, id);
    res.json({ removed: true });
  } catch (error) {
    next(error);
  }
});
