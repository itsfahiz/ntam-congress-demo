# NTAM pre-freeze review — 12 November 2026

## Scope and evidence
Source review of the Flutter Android application, Express API, Supabase-backed attendee features and the latest pre-freeze search/notifications/resources branch. This review is **not** a substitute for device, release build, or live network verification. It does not certify this as an official Nestlé application.

### Verified previously by assessment developer
- Auth, profile edits, Agenda/Resources/Speakers saved items persisted in Supabase.
- Authenticated Gemini tool calling answered questions about attendee and favourite speaker data.
- Previous branch: 61 Node tests passed, 82 Flutter tests passed, typecheck/build/analyze clean.
- SQL migrations 005, 006, 007 already applied.

### Added in `feat/pre-freeze-ux-polish` (NOT YET VERIFIED ON MAC)
- Cross-catalogue Home search (all event days; sessions, speakers, resource files), dedicated search/filter UI, direct one-tap filter.
- Dedicated Notifications page with links. Items explicitly marked **illustrative programme notices**; not push notifications.
- Real original, locally generated PDFs for Programme and Pediatric Discussion Guide.
- Real original PDF slide presentation; preview/exportable, not a PowerPoint file.
- Bundled original short demo MP4 title card with player and offline export.
- Resource viewer shared by Resources list, Search and Saved Items; local Download (application documents), Export (system share/save sheet) and separate PostgreSQL bookmark.
- Removed fake file sizes and updated Gemini catalogue availability wording.
- Release-demo event label makes the reference's historical event date clearly illustrative.

## Priority findings / freeze gate
| Severity | Finding | Disposition |
| --- | --- | --- |
| P0 | A search bar that only filters the bottom Day-1 tiles cannot discover Day-2 speakers/resources. | Replaced with dedicated search screen; test and device validation pending. |
| P0 | Resource download icons previously opened text-only summaries; the UI showed nonexistent file sizes. | Implemented original PDF/MP4 byte generation, viewer, download and export; device validation pending. |
| P0 | Notifications formerly occupied a small Home bottom sheet. | Dedicated screen; links into Agenda/Q&A/Resources; tests pending. |
| P0 | Unverified new plugin and media integration could prevent APK release build. | Run `flutter pub get && flutter analyze && flutter test && flutter build apk --release --dart-define-from-file=config.local.json`. Do not merge before green. |
| P1 | Demo event dates are May 22–23 2026, now in the past. | Preserve dates from assessment reference; Home card explicitly labeled DEMO EVENT. No claims of live event. |
| P1 | Notification data are seeded locally and do not arrive from FCM or an event-admin service. | Full page labeled illustrative; do not claim real-time push integration. |
| P1 | Slides are PDF slide pages; recap MP4 is an original title-card sample, not actual recorded sessions. | Explicit descriptions on viewer and in AI catalogue. Do not call them official or clinical. |
| P1 | Existing Profile Settings screen says settings are not connected; Certificates reports zero/no issuance. | Transparent demo limitations. Do not demonstrate these as functional features or imply future issuance. Consider hiding nonessential stubs after assessment if design allows. |
| P1 | Uploaded sample event/speaker/exhibitor descriptions are illustrative, not verified faculty bios, venue booking or exhibitor records. | Existing app includes demo qualifications; be transparent during interview. |
| P1 | Gemini tool calling is read-only and scoped to the authenticated user, but chat is not a long-term memory agent. | Demonstrate supported queries; do not claim unrestricted SQL, history memory or real-time event admin. |
| P2 | Public OpenStreetMap tiles have usage limits; PDF default Helvetica reports limited Unicode coverage. | Existing warnings are not failing tests, but deploy with appropriate map tile attribution/access policy; include embedded fonts later if non-ASCII PDFs are needed. |
| P2 | Android release signing uses debug key deliberately for assessment distribution. | Acceptable for assessment APK; not suitable for Play Store/public production. |
| P2 | App currently lacks integration-test coverage for native video/share/download sheets. | Verify on real emulator/phone and check device storage before release. |
| P2 | No true offline database for attendee bookmarks. | Expected architecture: PostgreSQL is canonical, temporary screen state is not offline sync. |

## Required validation script (Mac)
```bash
git fetch origin
git switch feat/pre-freeze-ux-polish
cd backend
npm ci && npm run typecheck && npm test && npm run build
cd ../frontend
flutter pub get
flutter analyze
flutter test
flutter run --dart-define-from-file=config.local.json
# After manual inspection and Render deployment:
flutter build apk --release --dart-define-from-file=config.local.json
```

## Manual device walkthrough (freeze checklist)
1. Home search opens full-screen Search; type "pediatric" and see session, speaker and PDF guide. Filter Day 2 / Nutrition and clear.
2. Home filter icon opens Search filters immediately. Change and reset filters without stale results.
3. Bell opens Notifications page. Each notice links to the correct real screen; copy clearly says *illustrative*.
4. Resources: open Programme PDF, page through it, use Download, verify local saved file; use Export/Save to Files to make an external copy and open it.
5. Repeat for Pediatric Guide PDF and multi-page PDF slide deck.
6. Video: press Play/Pause on real MP4; Download, Export and confirm actual MP4 plays outside the app.
7. Bookmark a resource in PostgreSQL; confirm Saved Items > Resources opens same viewer. Distinguish bookmark from offline downloaded file.
8. Login, Profile Editing, Agenda bookmarks, Speaker Favorites, polls, Q&A, badge QR, Gemini personal queries and Resource catalogue questions still behave as before.
9. Test on phone-sized and tablet-sized viewports, including keyboard/dismissal/back navigation and offline/error states.
10. Verify release APK install on actual Android phone, permissions, Supabase, Render network, Gemini quota/latency and video decoding.
11. After the branch is merged, change the Render service's deployment branch back to `main` and confirm expected commit is Live; no SQL migration is needed for these UX/media changes.
12. Capture final screenshots and 90–120-second demo and rehearse an accurate architecture explanation.

## Final submission positioning
Flutter/Dart UI, Supabase Auth, Node.js/Express REST API, PostgreSQL user data, authenticated Gemini tool calling, lightweight catalogue retrieval, original demo media, real saved bookmarks and interactive Q&A/polls. This is an **assessment demonstration**, not an official Nestlé deployment.


## Device feedback follow-up — Search navigation / playable demo / Downloads
Changes committed on `feat/pre-freeze-ux-polish` after the first device walkthrough:
- Tapping a Search session result now opens **Agenda** with the exact session's detail sheet; speaker results open **Speakers** with that speaker's detail, and resource results open their resource viewer.
- Search results use consistent elevated cards, subtitles, category counts and a clear empty state.
- Recap player now shows seekable playback position and programme captions that change with the timecode. The MP4 is still the original short illustrative title-card clip, not recorded event footage. Confirm `00:00` advances and Play/Pause work during real-device tests.
- On Android 10+, Download now writes through MediaStore to **Files → Downloads → NTAM Congress**, instead of only private app documents. Export uses the system share/save interface. On Android 9 and older, use Export to Save to Files; no broad storage permission is requested.
- Android native code changed in `MainActivity.kt`; a full app rebuild is required, not just hot reload.

Extra tests before PR #7 merge:
1. `flutter analyze && flutter test`, then `flutter run --dart-define-from-file=config.local.json`.
2. Search → Opening Ceremony must navigate to Agenda and display its detail; a speaker result must navigate to Speakers and display its detail.
3. Download PDF/MP4 and confirm visible files in Files/Downloads/NTAM Congress. Do not mistake a PostgreSQL bookmark for a local file.
4. Verify video playback time advances, slides/seek work and the short illustrative captions change.
5. Run `flutter build apk --release --dart-define-from-file=config.local.json` before freezing. New Android MediaStore integration is not covered by Dart widget tests.

## Updated external educational video
Stanford Introduction to Food & Health (official course trailer): https://www.youtube.com/watch?v=z7x1aaZ03xU
- External YouTube link, with clear Stanford attribution and not a congress recording.
- The saved resource ID remains `session-recap` so existing PostgreSQL bookmarks stay valid.
- PDF documents still use Android Save/Share; external video uses Watch Video.
- Re-run backend and Flutter tests and verify external YouTube app/browser launch on Android.

## In-app educational video follow-up
Updated per user requirement: tapping the Stanford resource opens its existing NTAM Resource detail screen, and **Play Video** starts the official YouTube iframe player inline. No launch to the YouTube app/browser. The resource row play icon also navigates to the internal detail screen. The iframe uses youtube_player_iframe ^6.0.2, requiring Flutter >=3.38. Publisher-side embed restrictions, connectivity and Android WebView runtime must be verified on emulator. The original PDF Save/Share path and existing PostgreSQL bookmark ID remain unchanged.

**Corrected user requirement:** video playback must remain inside NTAM. Library video card routes to the Resource detail screen, and the embedded iframe starts when Play Video is tapped. No external app or browser launching. The publisher may disallow embedding; this must be tested on Android. If this particular video blocks embedding, select another publisher-embeddable educational video rather than routing out of the app.
