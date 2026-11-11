# NTAM Congress API

Node.js + Express backend for the NTAM Nestlé Medical Congress assessment. Phase 1 serves read-only catalog data copied from the Flutter `CongressCatalog`. There is no Gemini, Firebase, or live database access yet.

## Local run

```bash
cp .env.example .env
npm install
npm test
npm start
```

Default URL: `http://localhost:3000`

## Render

Set the service **root directory** to `backend`.

| Setting | Value |
| --- | --- |
| Runtime | Node |
| Build | `npm install` |
| Start | `npm start` |
| Health check | `GET /health` |

Bind `PORT` from Render. Optional: `CORS_ORIGIN`, `DATABASE_URL` (unused in Phase 1).
