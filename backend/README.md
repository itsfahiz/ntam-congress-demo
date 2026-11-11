# NTAM Congress API

Node.js + Express + TypeScript backend for the NTAM Nestlé Medical Congress assessment. Phase 1 serves read-only catalog data copied from the Flutter `CongressCatalog`. Phase 2 adds `POST /api/assistant/ask` with lexical retrieval over that catalog and the official `@google/genai` SDK.

Source lives in TypeScript (`src/`, `data/`, `tests/`). `npm start` runs the compiled JavaScript in `dist/`.

## Local run

```bash
cp .env.example .env
# Set GEMINI_API_KEY, DATABASE_URL, SUPABASE_URL, SUPABASE_ANON_KEY,
# BADGE_SIGNING_SECRET, and PUBLIC_BASE_URL.
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
| `GET` | `/auth/confirmed` | Public email-verified landing page |
| `GET` | `/api/event` | Featured event, days, venue |
| `GET` | `/api/sessions` | Optional `day`, `track` |
| `GET` | `/api/speakers` | Optional `listed=true\|false` |
| `POST` | `/api/assistant/ask` | Body `{ "question": "..." }` (2–500 chars) |
| `GET`/`POST` | `/api/me` | Bearer token. Attendee profile |
| `GET` | `/api/me/badge` | Bearer token. Signed QR verification URL |
| `GET` | `/badge/verify` | Public HTML. Query `b` (badge id) and `s` (HMAC hex) |
| `GET`/`POST` | `/api/questions` | Bearer token. Persistent Q&A with like/reply counts |
| `POST`/`DELETE` | `/api/questions/:questionId/like` | Bearer token. Idempotent like / unlike |
| `GET`/`POST` | `/api/questions/:questionId/replies` | Bearer token. List or add a reply |
| `GET` | `/api/polls/active` | Bearer token. First active poll, counts, caller’s vote |
| `GET` | `/api/polls` | Bearer token. All active polls, ordered, with counts |
| `POST` | `/api/polls/:pollId/vote` | Bearer token. Body `{ "optionId": "<uuid>" }` |

Assistant JSON: `{ "answer": string, "grounded": boolean, "sources": [{ "type": "session\|speaker\|day", "id": string }] }`. Source IDs are catalog IDs only.

Default model is `gemini-3.5-flash-lite` (override with `GEMINI_MODEL`). Thinking is off (`GEMINI_THINKING_BUDGET=0`). Failures return `error` plus a safe `code` and never include the API key.

## Supabase

1. Create a project. Copy the URL, anon key, and database connection string into `backend/.env`.
2. Do **not** put the service-role key in this repo or the Flutter app.
3. Authentication → Providers: Email enabled. Keep email confirmation on for reviewers.
4. Authentication → URL Configuration:

   | Setting | Value |
   | --- | --- |
   | Site URL | `https://ntam-congress-api.onrender.com/auth/confirmed` |
   | Redirect URLs | `https://ntam-congress-api.onrender.com/auth/confirmed` |

   Do **not** use `http://localhost:3000`. Confirmation emails follow Site URL because the Flutter app does not set `emailRedirectTo`.
5. Run `backend/db/migrations/001_attendee_profiles_and_questions.sql`, then `002_live_polls.sql`, then `003_add_congress_polls.sql`, then `004_qa_interactions.sql` in the SQL editor. `003` only seeds polls 2 and 3. `004` adds likes and replies without changing existing questions.

The API verifies access tokens with `GET /auth/v1/user` and uses `req.authUser.id` for inserts. Clients cannot supply a user id. `GET /auth/confirmed` is a public HTML page only; it does not read tokens or user data.

## Render

Set the service **root directory** to `backend`.

| Setting | Value |
| --- | --- |
| Runtime | Node |
| Build | `npm install --include=dev && npm run build` |
| Start | `npm start` (`node dist/src/index.js`) |
| Health check | `GET /health` |

`--include=dev` is required so TypeScript is available during the compile step even when `NODE_ENV=production`. Bind `PORT` from Render. Set `GEMINI_API_KEY`, `DATABASE_URL`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `BADGE_SIGNING_SECRET` in the dashboard. Do **not** put `BADGE_SIGNING_SECRET` in Git.

### Attendee badge QR

`GET /api/me/badge` requires a Supabase access token. It signs the attendee’s existing `badge_id` with HMAC-SHA256 (`nmc-badge:v1:<badgeId>`) and returns:

```json
{
  "badgeId": "NMC-1BAC3BF0",
  "verifyUrl": "https://ntam-congress-api.onrender.com/badge/verify?b=NMC-1BAC3BF0&s=<64-hex-hmac>"
}
```

`GET /badge/verify?b=<badgeId>&s=<signature>` is public and read-only. It checks the HMAC, looks up the badge in PostgreSQL, and shows only valid/invalid, name, and badge ID. Invalid, malformed, or tampered tokens show an invalid page. This route does not create or update badges.

Set these Render environment variables, then redeploy:

| Key | Value |
| --- | --- |
| `BADGE_SIGNING_SECRET` | 32+ random bytes as hex. Generate locally with `node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"`. Mark as secret. |
| `PUBLIC_BASE_URL` | `https://ntam-congress-api.onrender.com` |

Keep the same `BADGE_SIGNING_SECRET` across deploys so already-issued QR codes keep verifying.

### Live polling

`GET /api/polls`, `GET /api/polls/active`, and `POST /api/polls/:pollId/vote` require a Supabase access token. Votes are stored in PostgreSQL. Unique `(poll_id, user_id)` prevents a second or changed vote on that poll, including concurrent requests (`409` / `already_voted`). Invalid `optionId` returns `400`. One vote is allowed per poll.

`GET /api/polls` returns every active poll, ordered by `id`:

```json
{
  "polls": [
    {
      "id": "7a1c0001-0000-4000-8000-000000000001",
      "question": "Which innovation will have the greatest impact on healthcare?",
      "topicLabel": "Healthcare innovation",
      "totalVotes": 1,
      "myOptionId": "7a1c0001-0000-4000-8000-000000000011",
      "options": [
        {
          "id": "7a1c0001-0000-4000-8000-000000000011",
          "label": "Artificial Intelligence",
          "voteCount": 1,
          "percent": 100
        }
      ]
    }
  ]
}
```

`GET /api/polls/active` still returns `{ "poll": … }` for the first poll in that order. Apply `002_live_polls.sql` then `003_add_congress_polls.sql` in Supabase. Do not expose `DATABASE_URL` to Flutter.

### Q&A likes and replies

Authenticated `GET /api/questions` includes `likeCount`, `replyCount` and `likedByMe`. `POST`/`DELETE /api/questions/:questionId/like` are idempotent. `GET`/`POST /api/questions/:questionId/replies` list and add replies; author name comes from the session profile, never from the client body. Attendee replies do not set `answered`. Apply `004_qa_interactions.sql` after the earlier migrations.
