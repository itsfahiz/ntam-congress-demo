# NMC 2026 — Medical Congress Companion
**NTAM Group technical assessment | Flutter Android + Node.js/Express + Supabase/PostgreSQL + Gemini**

A working, Android-first congress attendee application built against the provided Nestlé Medical Congress reference screens. This is an **independent assessment demonstration**, **not** an official Nestlé application, event service, or confirmed event announcement. The programme, speaker biographies, resources and exhibitor descriptions are illustrative.

## Repository layout

```text
frontend/  Flutter / Dart Android app (NMC 2026)
backend/   Node.js / Express 5 / TypeScript REST API
           PostgreSQL migrations and backend tests
```

The main source branch is `main`. A tested Android APK and narrated product-demo video are delivered **separately to the assessment reviewers**; neither file is committed to this source repository.

## Features and data ownership

| Feature | Implementation |
| --- | --- |
| Registration, email confirmation, sign-in, sign-out | Real Supabase email/password authentication, protected routes and session restoration |
| Attendee profile | Read/update name, organization and optional phone through an authenticated Express API; PostgreSQL persistence |
| Home, global search, agenda, speakers, quick access | Real Flutter functionality using an **illustrative, seeded congress catalogue**; day/track/category filters and grid/list navigation |
| Notifications | Three **sample programme notices**, each linked to a related screen; **not push notifications** |
| Session bookmarks, speaker favorites, saved resources | Authenticated REST API and PostgreSQL; available again after signing in on another device |
| Digital attendee name tag | Stable attendee badge ID, server-issued HMAC-signed QR verification URL and public read-only verification page; working print/PDF flow |
| Audience polls / Live Voting | Three backend polls; PostgreSQL results and unique vote constraint: one vote per authenticated attendee per poll |
| Ask Q&A | PostgreSQL-backed questions, topic categories, likes/unlikes and replies accessible across devices |
| Congress AI | Authenticated, rate-limited Express endpoint using Google Gemini with **server-controlled read-only function tools** and catalogue retrieval; source references and personalized attendee context |
| Resources | Original illustrative PDFs and slide-style documents generated in-app; preview, print, download/share chooser and persistent resource saves |
| Educational video | Embedded third-party Stanford University YouTube course trailer; Internet and YouTube embedding availability required |
| Venue | Interactive OpenStreetMap map and external directions to Dubai World Trade Centre; **not** a confirmation of actual venue booking |
| Exhibitors | Illustrative catalogue entries; no live exhibitor feed |

### Congress AI implementation

`POST /api/assistant/ask` **requires a valid Supabase Bearer token**. The server calls Gemini using its own `GEMINI_API_KEY`; the key never enters Flutter. Gemini may request only allowlisted, read-only functions:

- `search_congress`: lexical retrieval over the seeded programme, speakers, venue and resources, with source references.
- `get_my_profile_field`: one field from the **signed-in** attendee's profile.
- `get_my_saved_items`: saved sessions/resources/speakers, including a favorite speaker's session schedule.
- `get_my_questions`: the attendee's own Q&A submissions.
- `get_active_polls`: poll information and the attendee's vote status.

Tool calls are validated and executed by Express using the authenticated user's ID; the model cannot select a user ID or perform arbitrary database queries. This is **lightweight retrieval-grounded AI**, not an embeddings/vector-database architecture. Gemini responses and their source chips are presented in the Flutter app.

## Running the Android app

Requirements: Flutter compatible with Dart 3.11.5+, Android emulator/device, and a configured Supabase project and backend. Example local config file `frontend/config.local.json` (gitignored):

```json
{
  "API_BASE_URL": "https://ntam-congress-api.onrender.com",
  "SUPABASE_URL": "https://YOUR_PROJECT.supabase.co",
  "SUPABASE_ANON_KEY": "YOUR_SUPABASE_PUBLISHABLE_OR_ANON_KEY"
}
```

```bash
cd frontend
flutter pub get
flutter analyze
flutter test
flutter run --dart-define-from-file=config.local.json
```

Build the reviewer-installable APK:

```bash
cd frontend
flutter build apk --release --dart-define-from-file=config.local.json
# output: build/app/outputs/flutter-apk/app-release.apk
```

The release Android launcher label is **NMC 2026**; application ID is `com.muhammedfahiz.ntamcongressdemo`. The assessment APK uses a **debug signing key for convenience**; this is not a production/Play Store signing configuration. Icon and splash generation configs are at `frontend/flutter_launcher_icons.yaml` and `frontend/flutter_native_splash.yaml`.

### Reviewer sign-in

Registration requires a real email address and email confirmation. The submission contact may provide a **dedicated, pre-confirmed demo attendee account through a private channel**. No credentials are stored in this repository. If registering a new account, complete the email verification link before signing in.

## Backend setup

See [backend/README.md](backend/README.md) for configuration, API routes, Supabase email-confirmation URLs, the Render deployment and badge verification.

```bash
cd backend
cp .env.example .env
# Set DATABASE_URL, SUPABASE_URL, SUPABASE_ANON_KEY,
# GEMINI_API_KEY, BADGE_SIGNING_SECRET and PUBLIC_BASE_URL
npm install
npm run typecheck
npm test
npm run build
npm start
```

Apply **all seven** PostgreSQL migrations in numeric order from `backend/db/migrations/`:

1. `001_attendee_profiles_and_questions.sql`
2. `002_live_polls.sql`
3. `003_add_congress_polls.sql`
4. `004_qa_interactions.sql`
5. `005_saved_items.sql`
6. `006_editable_attendee_phone.sql`
7. `007_saved_speaker_favorites.sql`

The deployed reference API is `https://ntam-congress-api.onrender.com` (`GET /health` is public). Hosting on a free/limited tier can introduce a wake-up delay.

### API overview

| Access | Methods / route | Purpose |
| --- | --- | --- |
| Public | `GET /health` | Health status |
| Public | `GET /auth/confirmed` | Email confirmation landing page |
| Public | `GET /api/event`, `/api/sessions`, `/api/speakers` | Seeded event catalogue |
| Public | `GET /badge/verify?b=...&s=...` | Signed attendee badge verification |
| Authenticated | `GET/POST /api/me` | Read/update attendee profile |
| Authenticated | `GET /api/me/badge` | Issue signed badge verification URL |
| Authenticated | `GET /api/polls`, `/api/polls/active`; `POST /api/polls/:pollId/vote` | Polls and voting |
| Authenticated | `GET/POST /api/questions`; `POST/DELETE /api/questions/:id/like`; `GET/POST /api/questions/:id/replies` | Q&A |
| Authenticated | `GET/POST /api/saved`; `DELETE /api/saved/:type/:id` | Saved sessions, resources and speakers |
| Authenticated | `POST /api/assistant/ask` | Gemini-assisted grounded answers and authorized personal context |

All authenticated API requests use `Authorization: Bearer <Supabase access token>`. Express verifies the token and derives the user ID server-side. PostgreSQL records cannot be assigned to arbitrary client-supplied users.

## Tests and quality checks

```bash
cd frontend && flutter analyze && flutter test
cd ../backend && npm run typecheck && npm test && npm run build
```

Flutter widget tests use isolated test repositories. Backend tests mock Gemini; they do not replace real-device validation. The final release build was additionally exercised on physical Android devices by the developer, including cross-device interaction.

## Scope, limitations and security

- **Assessment demonstration only:** seeded event days, session data, speaker profiles, venue copy and illustrative exhibitors are not official or live organizer records.
- **No live push notifications**, Google/Apple OAuth, forgot-password email delivery, certificate issuance, organizer dashboard or live CMS.
- **Educational video is third-party content**, not congress footage. Its playback may depend on network access and YouTube restrictions.
- **No medical advice** is provided by this app; demonstration PDFs are original illustrative documents, not clinical guidance.
- No production app-store signing, iOS build or web release is provided.
- Never commit `backend/.env`, `frontend/config.local.json`, PostgreSQL credentials, Gemini keys, service-role credentials or `BADGE_SIGNING_SECRET`. Only the public Supabase publishable/anon key belongs in a client build.

For a feature-by-feature walkthrough, refer to the accompanying NMC 2026 technical demo video supplied with the assessment.
