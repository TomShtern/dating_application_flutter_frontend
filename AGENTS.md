# AGENTS.md

Operating guide for AI agents in this Flutter frontend. Single source of truth —
`CLAUDE.md` imports this file. Keep it factual; verify against code before
editing it.

**Derived facts are deliberately not duplicated here.** Versions live in
`pubspec.lock` / `.metadata` / `android/local.properties`, endpoints in
`lib/api/api_endpoints.dart`, widgets in `lib/shared/widgets/`. Copies of those
lists previously drifted and produced false statements — read the source instead.

## Identity and boundary

- Flutter frontend for a dating app; the Java backend is a separate repo.
- **Thin client.** Flutter owns UI, navigation, local state, request
  orchestration, presentation and modest polling. The backend owns matching,
  messaging, moderation, verification, location resolution, stats, achievements,
  storage, persistence and all business rules.
- Do not reimplement backend-owned product logic in Dart. If richer UI needs data
  the API does not provide, call out the backend contract gap rather than
  fabricating compatibility scores, match reasons, moderation state or metrics.
- Entrypoint `lib/main.dart`; root widget `DatingApp` in `lib/app/app.dart`.
- Riverpod for state, Dio for HTTP, `shared_preferences` for local persistence,
  Material 3 plus a project theme for UI.
- Treat backend contract changes as cross-repo coordination, not a Flutter patch.

## Docs to read

Read the smallest relevant set before editing:

- `README.md` — repo overview, dependency inventory, setup.
- `docs/design-language.md` — canonical design-system reference.
- `docs/visual-review-workflow.md` — screenshot workflow.
- `docs/specs/backend-contract-handoff.md` — backend/mobile contract and product constraints.
- `docs/specs/frontend-agent-guide.md` — broader guidance and API cheat sheet.
- `screen-transform-prompts/prompt-<screen>.md` — per-screen design intent.
- `docs/superpowers/plans/` — historical and active plans. Treat status claims
  there as historical unless verified against current code.

## Architecture map

```text
lib/
  main.dart
  app/                  app root, Env, AppConfig
  api/                  Dio client, endpoints, headers, errors, auth token holder
  features/
    auth/               signup, login, refresh, dev-user picker, auth state
    browse/             discover, undo, standouts, pending likers
    chat/               conversations and thread
    home/               startup routing, health banner, signed-in shell
    location/           location completion and providers
    matches/            matches list
    notifications/      list, actions, preferences, OS-channel service
    profile/            profile view/edit, photo management
    safety/             block/report/unmatch/blocked users
    settings/           theme mode and settings
    stats/              stats and achievements
    verification/       verification start/confirm
  models/               hand-written JSON DTOs
  shared/               formatting, media, persistence, providers, widgets
  theme/                Material 3 theme and shared tokens
```

Tests mirror this under `test/`; visual-review tests in `test/visual_inspection/`.

## Navigation

No router package. `main.dart` initializes `SharedPreferences` and injects it via
`sharedPreferencesProvider`. `DatingApp` uses `MaterialApp` with
`AppTheme.light()`, `AppTheme.dark()` and `themeModeProvider`.

`AppHomeScreen` picks the startup flow from `selectedUserProvider` — no user
means `DevUserPickerScreen`, a user means `SignedInShell`, an `IndexedStack` with
five bottom-nav tabs: Discover, Matches, Chats, Profile, Settings. Every other
screen is pushed imperatively.

## Running

Runtime config is centralized: `lib/app/env.dart` reads Dart defines and
`lib/app/app_config.dart` exposes `appConfigProvider`. `.env` is **not**
auto-loaded — pass it explicitly. Keys: `DATING_APP_API_BASE_URL`,
`DATING_APP_SHARED_SECRET`.

```powershell
flutter pub get
flutter analyze
flutter test
flutter test test/visual_inspection/screenshot_test.dart
flutter run -d windows --dart-define-from-file=.env
flutter run -d chrome --dart-define-from-file=.env
flutter run -d emulator-5554 --dart-define-from-file=.env
```

`.env` currently targets the Android emulator (`http://10.0.2.2:7070`); for
Windows desktop switch to `http://127.0.0.1:7070`. Cleartext HTTP is enabled for
debug and profile builds only, via those two `AndroidManifest.xml` files and
`android/app/src/main/res/xml/network_security_config.xml`.

**PATH gotcha:** `where.exe flutter` and `where.exe dart` can fail on this
machine even when the commands work in an interactive PowerShell. Try
`flutter --version` directly first; if that also fails, use the SDK path pinned
in `android/local.properties`:

```powershell
& 'C:\Users\tom7s\develop\flutter\bin\flutter.bat' --version
```

Sandboxed agent shells have separately seen `flutter` and `dart` time out or fail
to start those batch files. That is an agent-execution caveat, not proof the
user's own PowerShell is broken. `semgrep` is installed as a launcher but its
Python module is missing — do not rely on it until that is repaired.

## Verified constraints

- **No WebSocket and no server push.** No Firebase or FCM anywhere — verified in
  `pubspec.yaml` and the Gradle config.
- **Local notifications *are* implemented** — `flutter_local_notifications`, OS
  channel definitions in
  `lib/features/notifications/notification_platform_service.dart`, and
  `POST_NOTIFICATIONS` in the main manifest. Do not rebuild this; extend it.
- **Chat is polled and conversation-scoped.** `ConversationThreadScreen`
  refreshes every 20 s while visible. Poll gently. Do not invent nested
  user-scoped message routes.
- **Two auth entry points** — the dev user picker and the real
  email+password+DOB signup / login flow with JWT access and refresh tokens. Both
  end at a `selectedUserProvider` value; downstream code must not branch on which
  one ran.
- **No offline-first sync** exists in this frontend.
- Photo management (list, upload, delete, reorder) is wired through
  `image_picker` and the photo endpoints.
- Location UX is server-driven through the location endpoints.
- **Native media permissions** — camera and photo-library usage strings in
  `ios/Runner/Info.plist`; `READ_MEDIA_IMAGES`, `READ_EXTERNAL_STORAGE`
  (SDK 32 and below) and `CAMERA` in `AndroidManifest.xml`. Disable the cleartext
  `network_security_config.xml` permission before any production build.
- **Android first** — the primary target for development and testing.

## Testing policy

### No new tests during frontend or UI work

**Do not create widget, regression or integration tests when the task involves
frontend UI, design, visual polish, layout or screen-level changes.** The default
for frontend work is: no new tests. Create them only when the user explicitly
asks and the frontend is finalized — active iteration is by definition not a
finalized state.

Use the visual-review screenshot workflow for quality assurance instead. If
existing tests break from a UI refactor, repair them to match the new structure,
but add nothing beyond that repair.

Non-frontend code — providers, models, API contracts, state logic, guards, DTOs —
follows normal testing judgment.

### General

- For Dart changes run `flutter analyze` plus the relevant `flutter test` target.
- Judge UI from screenshots, not from widget assertions.
- For `com.example.flutter_dating_application_1`, use Dart MCP for runtime state
  and Maestro MCP (`list_devices` -> `inspect_screen` -> `run`) for semantic UI
  evidence; use `scrcpy` for human review. Do not persist new Maestro flows
  during UI iteration unless the user explicitly requests tests.
- Never claim "fully fixed" or "end-to-end verified" without exercising the real
  path. If a command cannot run in your sandbox, say so and state what
  file-level verification you did perform instead.

## Working rules

- Start from current code, not old roadmap assumptions.
- Keep API and header logic in `lib/api/**`; keep request orchestration and state
  transitions in Riverpod providers and controllers; keep widgets declarative.
- Prefer incremental, focused changes over broad rewrites.
- Preserve the selected dev user between launches.
- Do not modify `.env` values or expose secrets.
- Do not clean generated logs, screenshots or build artifacts unless asked.
- Respect dirty worktrees; never revert unrelated user changes.
- Update docs when you intentionally change product assumptions, API behaviour or
  reusable workflows.
