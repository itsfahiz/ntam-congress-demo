# Nestlé Medical Congress (NTAM assessment)

Companion Android app and API for NTAM’s Nestlé Medical Congress technical assessment. It is a demonstration of the requested attendee flows, not an official Nestlé product.

```
root/
  frontend/   Flutter / Dart Android app
  backend/    Node.js + Express + TypeScript API
```

The Flutter UI follows the assessment reference screens. Live behaviour is split: **seeded on-device catalogue** for programme content, and **authenticated backend services** for accounts, voting, Q&A, badge QR, and Congress AI.

The API is documented in [`backend/README.md`](backend/README.md). On Render, set the service root directory to `backend/`.

## What is real vs illustrative

| Area | Implementation |
| --- | --- |
| Email/password auth | **Real.** Supabase Auth. Registration requires email confirmation before sign-in. Session restore on launch; Sign Out clears the session. |
| Attendee profile | **Real.** `GET`/`POST /api/me` persists name, organization, and badge ID in PostgreSQL. |
| Agenda, speakers, venue copy | **Seeded catalogue** in Flutter (`CongressCatalog`) and the API (`backend/data/catalog.ts`). Not a CMS. |
| Live Voting | **Real.** Three PostgreSQL polls, one vote per attendee per poll, server-calculated counts and percentages. |
| Ask Q&A | **Real.** Authenticated questions, likes, and replies in PostgreSQL. No catalogue sample cards in production. |
| Name Tag QR | **Real.** HMAC-signed verification URL from `GET /api/me/badge`. Public `GET /badge/verify`. |
| Congress AI | **Real.** Gemini answers grounded in retrieved catalogue records, with source chips. |
| Google / Apple / forgot-password | **UI only.** Buttons explain they are not connected. Forgot-password does not send email. |
| Resources, exhibitors, venue map | **Illustrative.** On-device summaries, demo booths, static map drawing. |
| Organizer tools | **Not in scope.** No poll authoring, moderation, or certificate issuance. |

Widget tests inject in-memory repositories. `flutter run` / release builds do **not** fall back to that fixture. If `SUPABASE_ANON_KEY` is missing, sign-in is refused.

## Architecture

```
frontend/lib/
  app/           theme, routes, API/Supabase config, MaterialApp
  core/widgets/  shared chrome
  features/
    auth/        login, register, splash, Supabase auth
    assistant/   Congress AI
    congress/    seeded sessions, speakers, venue, resources, exhibitors
    home/        dashboard + Congress AI entry
    voting/      HTTP polls
    qa/          HTTP questions, likes, replies
    name_tag/    signed badge QR
    agenda/ speakers/ venue/ resources/ exhibitors/ profile/ quick_access/

backend/
  src/           Express routes and services
  data/catalog.ts
  db/migrations/ 001–004
```

- Flutter: `go_router` with an auth splash, login/register gates, and a Home/Profile shell.
- Session: `AuthController` + `SupabaseAuthRepository` (`supabase_flutter`). Access token is sent as `Authorization: Bearer` to the API.
- HTTP from Flutter uses `dart:io` `HttpClient` (no extra HTTP package).
- API: Express 5, Zod validation, `pg` against Supabase PostgreSQL. Gemini (`@google/genai`) stays on the server.
- Direct table access from anon/authenticated Supabase clients is revoked; the Express API is the only writer.

## Features

- **Auth:** email/password login and registration, validation, password visibility, email-confirmation success card, login email prefill after verify, session restore, Sign Out. Google/Apple sheets state they are not configured.
- **Home:** greeting from the signed-in attendee, search, track filter, featured event, **Congress AI** entry, Quick Access, upcoming sessions from the catalogue.
- **Agenda / Speakers:** day and track filters, session details, in-memory bookmarks/favorites for the current screen only.
- **Name Tag:** signed-in attendee badge. QR encodes `GET /badge/verify?b=<badgeId>&s=<hmac>`. Print is not connected.
- **Venue:** catalogue name/address, static map preview, facility tiles. Directions do not open a maps app.
- **Live Voting:** loads `GET /api/polls` (three active polls), Previous/Next, one submit per poll via `POST /api/polls/:pollId/vote`. Results are server counts. Duplicate votes return `409`.
- **Ask Q&A:** `GET`/`POST /api/questions`; like/unlike; list/add replies. Popular ranks by real `likeCount`. Answered uses the backend `answered` flag (attendee replies do not set it).
- **Congress AI:** `POST /api/assistant/ask`. Lexical retrieval over the catalogue (sessions, speakers, days), Gemini grounded on those records, source chips. Out-of-catalogue questions skip Gemini.
- **Resources / Exhibitors:** on-device summaries and illustrative booths.
- **Profile:** signed-in name, email, organization, badge ID. Session count is the catalogue size (08). Saved / Certificates stay 00 (unsupported).

## Android identity

| | |
| --- | --- |
| Launcher label | `Nestlé Congress` |
| `applicationId` | `com.muhammedfahiz.ntamcongressdemo` (assessment id, not a Play listing) |
| Icon | Branded adaptive launcher (`frontend/assets/branding/`, generated into `mipmap` / `drawable`) |
| Native splash | Navy congress splash (`flutter_native_splash`, `#0D1D57`) |
| In-app splash | `AuthSplashScreen` while the session is restored |
| Signing | Release APK uses the Android **debug** keystore on purpose |

No unlicensed Nestlé trademark artwork is claimed as an official mark; branding here is assessment chrome.

## Requirements

- Flutter 3.41+ (Dart 3.11)
- Android emulator or device (this assessment is Android-only)
- Node.js 20+ (22+ recommended for `@google/genai`)
- Supabase project (Auth + PostgreSQL) and a Gemini API key for Congress AI

Never commit `.env`, `frontend/config.local.json`, service-role keys, or `BADGE_SIGNING_SECRET`.

## Flutter setup

```bash
cd frontend
flutter pub get
flutter analyze
flutter test
```

Create gitignored `frontend/config.local.json` (string values only):

```json
{
  "API_BASE_URL": "https://ntam-congress-api.onrender.com",
  "SUPABASE_URL": "https://YOUR_PROJECT.supabase.co",
  "SUPABASE_ANON_KEY": "YOUR_SUPABASE_ANON_KEY"
}
```

Local emulator against a machine-local API:

```bash
flutter run --dart-define-from-file=config.local.json \
  --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

Physical device: use `http://<LAN-IP>:3000` instead of `10.0.2.2`. Debug builds allow cleartext HTTP; release builds do not.

Equivalent flags without the JSON file:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:3000 \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

Release APK (debug-keystore signed, not a Play Store build):

```bash
cd frontend
flutter build apk --release --dart-define-from-file=config.local.json
```

Or pass the three `--dart-define` values explicitly. Output: `frontend/build/app/outputs/flutter-apk/app-release.apk`.

If `API_BASE_URL` is omitted, debug defaults to `http://10.0.2.2:3000` and release defaults to `https://ntam-congress-api.onrender.com`. `SUPABASE_ANON_KEY` has no production fallback; without it the app will not authenticate.

There are no shared demo logins. Register a real email, confirm it, then sign in.

## API setup

```bash
cd backend
cp .env.example .env
# Set DATABASE_URL, SUPABASE_URL, SUPABASE_ANON_KEY,
# GEMINI_API_KEY, BADGE_SIGNING_SECRET, PUBLIC_BASE_URL.
npm install
npm test
npm start
```

Apply migrations in order in the Supabase SQL editor: `001_attendee_profiles_and_questions.sql`, `002_live_polls.sql`, `003_add_congress_polls.sql`, `004_qa_interactions.sql`. `003` only seeds polls 2 and 3. `004` adds likes and replies.

Keep email confirmation enabled. Site URL / Redirect URLs should be the API’s `/auth/confirmed` page (see [`backend/README.md`](backend/README.md)).

### Authenticated API (Bearer token)

| Method | Path |
| --- | --- |
| `GET`/`POST` | `/api/me` |
| `GET` | `/api/me/badge` |
| `GET` | `/api/polls`, `/api/polls/active` |
| `POST` | `/api/polls/:pollId/vote` |
| `GET`/`POST` | `/api/questions` |
| `POST`/`DELETE` | `/api/questions/:questionId/like` |
| `GET`/`POST` | `/api/questions/:questionId/replies` |

### Public

| Method | Path |
| --- | --- |
| `GET` | `/health` |
| `GET` | `/auth/confirmed` |
| `GET` | `/api/event`, `/api/sessions`, `/api/speakers` |
| `POST` | `/api/assistant/ask` `{ "question": "..." }` |
| `GET` | `/badge/verify?b=&s=` |

Assistant JSON: `{ "answer", "grounded", "sources": [{ "type": "session\|speaker\|day", "id" }] }`. Default model `gemini-3.5-flash-lite`. Keys never leave the server.

## Tests

```bash
cd frontend && flutter test
cd backend && npm test
```

Flutter tests cover auth gates, catalogue consistency, Agenda/Quick Access, Speakers/Name Tag/Venue, live voting UI, Q&A likes/replies, Congress AI parsing and bold answer rendering, badge QR, resources/profile/exhibitors, and protected routes. They use mock repositories, not production credentials.

API tests cover catalog, retrieval, assistant grounding, polls, questions, and badge HMAC verification, with Gemini mocked.

## Limitations

- Programme content is a **seeded assessment catalogue**, not live event operations data. Speaker bios and Ahmed’s country/title are illustrative.
- Google/Apple sign-in and password reset are not connected.
- Agenda bookmarks, speaker favorites, and resource bookmarks are screen-local only.
- Venue address text is copied from the assessment PDF. It is not a verified pin or booking. The map is a static drawing.
- Resources are on-device summaries. No PDFs, decks, or videos are bundled; tapping a card does not download a file.
- Exhibitors are illustrative demo booths, not an official directory.
- Profile Saved / Certificates are unsupported (shown as 00). Phone is stored as “Not provided”; location is catalogue copy (`Dubai, UAE`).
- No organizer console (poll authoring, Q&A moderation, check-in hardware).
- Release APK is signed with the Android **debug** keystore. Not a production signing identity.
- Android-only; iOS/web are out of scope.

## Flutter packages

| Package | Why |
| --- | --- |
| `go_router` | Named routes, auth redirects, Home/Profile shell |
| `supabase_flutter` | Email/password Auth and session restore |
| `qr_flutter` | Name Tag QR rendering |
| `flutter_lints` | Analyzer rules (dev) |
| `flutter_launcher_icons` / `flutter_native_splash` | Android icon and native splash (dev) |
