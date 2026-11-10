# Nestlé Medical Congress (NTAM assessment)

Android Flutter companion app for NTAM’s Nestlé Medical Congress technical assessment. The UI follows the 12-screen PDF mockups. There is no backend and no AI.

## Current features

Implemented:

- Login with validation, password visibility, and simulated forgot-password / social sign-in
- Registration with validation, terms copy, and a local in-memory profile
- Home dashboard: greeting, search, session filter, featured event, Quick Access, upcoming sessions
- Quick Access with category chips and routed shortcuts
- Agenda with day/track filters, session details, and in-memory bookmarks
- Speakers with search, focus chips, local favorites, and session links from the shared catalog
- Name Tag badge using the signed-in attendee, with a local demo QR
- Venue overview with reference copy, a static map preview, and facility tiles
- Live Voting with selectable answers, one vote per poll, and simulated results
- Ask Q&A with validated local question submission and demo discussion cards
- Resources library of on-device summaries (no file downloads)
- Profile with signed-in attendee details and a working Sign Out action
- Exhibitors as a small illustrative booth list, not an official directory

## Architecture

Feature-first Flutter, Android-focused:

```
lib/
  app/           theme, routes, MaterialApp
  core/widgets/  shared chrome (background, fields, buttons, shell)
  features/
    auth/        login, register, mock auth
    congress/    shared catalog (sessions, speakers, venue, polls, Q&A, resources)
    home/        dashboard
    quick_access/
    agenda/
    speakers/
    name_tag/
    venue/
    voting/
    qa/
    resources/
    exhibitors/
    profile/
```

- Navigation: `go_router` with auth redirects and a Home/Profile shell
- Session state: `AuthController` (`ChangeNotifier`) via `AuthScope`
- Screen filters and votes: local `setState`
- Data: `AuthRepository` + `MockAuthRepository`; congress content is `CongressCatalog`

## Dependencies

| Package | Why |
| --- | --- |
| `go_router` | Named routes, auth redirects, two-tab shell |
| `qr_flutter` | Local QR rendering for the demo name-tag badge |
| `flutter_lints` | Analyzer rules (dev) |

No new packages were added in Stage 5. No state-management framework, HTTP client, Firebase, or Maps SDK.

## Demo credentials

Seeded local attendee (in memory only):

- Email: `huda@example.com`
- Password: `congress`
- Badge ID: `NMC-2026-001`

Any newly registered email/password is stored until the process is killed. Sign-in fails for unknown emails.

## Mock services

- Auth is an in-memory map with a short delay. Passwords are not hashed. Nothing is sent to a server.
- Google/Apple buttons open a sheet that states they are not connected, then optionally sign in the seeded attendee.
- Forgot-password only shows a snackbar. No email is sent.
- Sessions, speakers, notices, polls, questions, resources, exhibitors, and venue copy are static local data.
- Registration is not a real Nestlé account.
- Name Tag QR payload is `NMC-DEMO-BADGE:<badge-id>` only. It is not a check-in token and is not verified by a backend.
- Name Tag print control is not connected to a printer or share sheet.
- Venue address text is copied from the assessment PDF. It is not a confirmed booking. The map is a static drawing. Directions are not connected.
- Live Voting stores one answer per poll in memory while the screen is open. Counts are simulated samples, not live attendee votes. Leaving the screen or using Reset clears them.
- Ask Q&A appends questions to a local list on the current screen. They are not sent to speakers, moderation, or a server. Likes are local only. Reply is not connected. Leaving the screen clears submissions and likes.
- Resources open on-device summaries. The app does not download files, request storage permission, or open external URLs. Saved bookmarks exist only while the Resources screen is open.
- Exhibitors are illustrative demo booths, not verified official participants.
- Profile Sign Out clears the in-memory session and returns to Login. Protected routes then redirect to Login.

## Setup

Requires Flutter 3.41+ (Dart 3.11) and an Android emulator or device.

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Limitations

- Session does not persist across app restarts
- Live Voting, Q&A submissions/likes, and Resource bookmarks reset when you leave those screens
- Home greeting uses the signed-in name, not the PDF’s “Dr. Testing” placeholder
- Upcoming sessions may sit near the tab bar on shorter viewports; the list scrolls
- Speaker bios and Ahmed’s country/title are illustrative demo fields
- Agenda bookmarks and speaker favorites are in-memory only and are not shown as a Profile saved count
- Profile stats use the real catalog session count (08) and 00 for Saved / Certificates instead of the PDF’s placeholder 12 / 05 / 03
- Name Tag and Profile org/role come from the signed-in attendee, not the PDF’s “Flutter Developer” placeholder
- Android-only for this assessment; iOS/web are not in scope
