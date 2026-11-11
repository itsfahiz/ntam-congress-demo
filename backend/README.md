# NTAM Congress API

Node.js + Express + TypeScript backend for the NTAM Nestlé Medical Congress assessment. Phase 1 serves read-only catalog data copied from the Flutter `CongressCatalog`. Phase 2 adds `POST /api/assistant/ask` with lexical retrieval over that catalog and the official `@google/genai` SDK.

Source lives in TypeScript (`src/`, `data/`, `tests/`). `npm start` runs the compiled JavaScript in `dist/`.

## Local run

```bash
cp .env.example .env
# Set GEMINI_API_KEY, DATABASE_URL, SUPABASE_URL and SUPABASE_ANON_KEY.
npm install
npm run typecheck
npm test
npm run build
npm start
```

Development (no compile step): `npm run dev`

Default URL: `http://localhost:3000`

`npm test` runs the TypeScript tests with `tsx` and mocks Gemini. It does not need a real key.

## Endpoints

| Method | Path | Notes |
| --- | --- | --- |
| `GET` | `/health` | Liveness |
| `GET` | `/api/event` | Featured event, days, venue |
| `GET` | `/api/sessions` | Optional `day`, `track` |
| `GET` | `/api/speakers` | Optional `listed=true\|false` |
| `POST` | `/api/assistant/ask` | Body `{ "question": "..." }` (2–500 chars) |
| `GET`/`POST` | `/api/me` | Bearer token. Attendee profile |
| `GET`/`POST` | `/api/questions` | Bearer token. Persistent Q&A |

Assistant JSON: `{ "answer": string, "grounded": boolean, "sources": [{ "type": "session\|speaker\|day", "id": string }] }`. Source IDs are catalog IDs only.

Default model is `gemini-3.5-flash-lite` (override with `GEMINI_MODEL`). Thinking is off (`GEMINI_THINKING_BUDGET=0`). Failures return `error` plus a safe `code` and never include the API key.

## Supabase

1. Create a project. Copy the URL, anon key, and database connection string into `backend/.env`.
2. Do **not** put the service-role key in this repo or the Flutter app.
3. Authentication → Providers: Email enabled. Decide whether to require email confirmation.
4. Run `backend/db/migrations/001_attendee_profiles_and_questions.sql` in the SQL editor (or `psql "$DATABASE_URL" -f db/migrations/001_attendee_profiles_and_questions.sql`).

The API verifies access tokens with `GET /auth/v1/user` and uses `req.authUser.id` for inserts. Clients cannot supply a user id.

## Render

Set the service **root directory** to `backend`.

| Setting | Value |
| --- | --- |
| Runtime | Node |
| Build | `npm install --include=dev && npm run build` |
| Start | `npm start` (`node dist/src/index.js`) |
| Health check | `GET /health` |

`--include=dev` is required so TypeScript is available during the compile step even when `NODE_ENV=production`. Bind `PORT` from Render. Set `GEMINI_API_KEY`, `DATABASE_URL`, `SUPABASE_URL`, and `SUPABASE_ANON_KEY` in the dashboard.
