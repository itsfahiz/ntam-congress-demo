# Nestlé Medical Congress (NTAM assessment)

Android Flutter companion app for NTAM’s Nestlé Medical Congress technical assessment. The UI follows the 12-screen PDF mockups. There is no backend and no AI.

## Current features

Implemented:

- Login with validation, password visibility, and simulated forgot-password / social sign-in
- Registration with validation, terms copy, and a local in-memory profile
- Home dashboard: greeting, search, session filter, featured event, Quick Access, upcoming sessions

Routed placeholders (not designed yet):

- Quick Access, Agenda, Speakers, Name Tag, Venue, Live Voting, Ask Q&A, Resources, Exhibitors, Profile

## Architecture

Feature-first Flutter, Android-focused:

```
lib/
  app/           theme, routes, MaterialApp
  core/widgets/  shared chrome (background, fields, buttons, shell)
  features/
    auth/        login, register, mock auth
    home/        dashboard and local congress catalog
```

- Navigation: `go_router` with auth redirects and a Home/Profile shell
- Session state: `AuthController` (`ChangeNotifier`) via `AuthScope`
- Home search/filter: local `setState`
- Data: `AuthRepository` + `MockAuthRepository`; Home reads `HomeMockData`

## Dependencies

| Package | Why |
| --- | --- |
| `go_router` | Named routes, auth redirects, two-tab shell |
| `flutter_lints` | Analyzer rules (dev) |

No state-management framework, HTTP client, or Firebase.

## Demo credentials

Seeded local attendee (in memory only):

- Email: `huda@example.com`
- Password: `congress`

Any newly registered email/password is stored until the process is killed. Sign-in fails for unknown emails.

## Mock services

- Auth is an in-memory map with a short delay. Passwords are not hashed. Nothing is sent to a server.
- Google/Apple buttons open a sheet that states they are not connected, then optionally sign in the seeded attendee.
- Forgot-password only shows a snackbar. No email is sent.
- Home sessions, notices, and the featured event are static local data.
- Registration is not a real Nestlé account.

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
- Android-only for this assessment; iOS/web are not in scope
