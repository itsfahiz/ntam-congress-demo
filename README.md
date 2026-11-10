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

Routed placeholders (not designed yet):

- Live Voting, Ask Q&A, Resources, Exhibitors, Profile

## Architecture

Feature-first Flutter, Android-focused:

```
lib/
  app/           theme, routes, MaterialApp
  core/widgets/  shared chrome (background, fields, buttons, shell)
  features/
    auth/        login, register, mock auth
    congress/    shared catalog (sessions, speakers, venue, shortcuts)
    home/        dashboard
    quick_access/
    agenda/
    speakers/
    name_tag/
    venue/
```

- Navigation: `go_router` with auth redirects and a Home/Profile shell
- Session state: `AuthController` (`ChangeNotifier`) via `AuthScope`
- Screen filters: local `setState`
- Data: `AuthRepository` + `MockAuthRepository`; congress content is `CongressCatalog`

## Dependencies

| Package | Why |
| --- | --- |
| `go_router` | Named routes, auth redirects, two-tab shell |
| `qr_flutter` | Local QR rendering for the demo name-tag badge |
| `flutter_lints` | Analyzer rules (dev) |

No state-management framework, HTTP client, Firebase, or Maps SDK.

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
- Sessions, speakers, notices, and venue copy are static local data.
- Registration is not a real Nestlé account.
- Name Tag QR payload is `NMC-DEMO-BADGE:<badge-id>` only. It is not a check-in token and is not verified by a backend.
- Name Tag print control is not connected to a printer or share sheet.
- Venue address text is copied from the assessment PDF. It is not a confirmed booking. The map is a static drawing. Directions are not connected.

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
- Remaining congress screens are placeholders
- Home greeting uses the signed-in name, not the PDF’s “Dr. Testing” placeholder
- Upcoming sessions may sit near the tab bar on shorter viewports; the list scrolls
- Speaker bios and Ahmed’s country/title are illustrative demo fields
- Agenda bookmarks and speaker favorites are in-memory only
- Android-only for this assessment; iOS/web are not in scope
