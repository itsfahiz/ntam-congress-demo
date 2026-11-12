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
