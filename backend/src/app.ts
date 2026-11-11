import express from 'express';
import { errorHandler, notFoundHandler } from './middleware/error-handler.js';
import { assistantRouter } from './routes/assistant.js';
import { catalogRouter } from './routes/catalog.js';
import { healthRouter } from './routes/health.js';
import { meRouter } from './routes/me.js';
import { questionsRouter } from './routes/questions.js';

export function createApp() {
  const app = express();
  const corsOrigin = process.env.CORS_ORIGIN ?? '*';

  app.disable('x-powered-by');
  app.set('trust proxy', 1);
  app.use(express.json({ limit: '16kb' }));
  app.use(express.urlencoded({ extended: false, limit: '16kb' }));
  app.use((req, res, next) => {
    res.setHeader('Access-Control-Allow-Origin', corsOrigin);
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader(
      'Access-Control-Allow-Headers',
      'Content-Type, Authorization',
    );
    if (req.method === 'OPTIONS') {
      res.status(204).end();
      return;
    }
    next();
  });

  app.use(healthRouter);
  app.use('/api', catalogRouter);
  app.use('/api', assistantRouter);
  app.use('/api', meRouter);
  app.use('/api', questionsRouter);
  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
