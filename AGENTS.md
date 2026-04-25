# AGENTS.md

Last reviewed and updated from verified repository and local-toolchain facts on 2026-04-24.

This file is the operating guide for AI coding agents working in this Flutter frontend. Keep it factual. If code, docs, SDKs, or dependencies move, verify the new state before updating this file.

## Project Identity

- Repository path: `C:\Users\tom7s\Desktopp\Claude_Folder_2\New_Flutter_Frontend\flutter_dating_application_1`
- Flutter package name: `flutter_dating_application_1`
- App version in `pubspec.yaml`: `1.0.0+1`
- Product: Flutter frontend for a dating app backed by a separate Java backend.
- Repository boundary: this repo contains only the Flutter frontend. The backend is a separate project.
- User-provided backend context: the backend is mostly pure Java 25 with preview features enabled.
- Client role: thin client. Flutter owns UI, navigation, local state, request orchestration, presentation, and modest polling.
- Backend role: source of truth for matching, messaging, moderation, verification, location resolution, stats, achievements, storage, persistence, and business rules.
- Current app entrypoint: `lib/main.dart`
- Root widget: `DatingApp` in `lib/app/app.dart`
- State management: Riverpod.
- HTTP client: Dio.
- Local persistence: `shared_preferences`.
- UI system: Material 3 plus project-specific theme/widgets.

Do not reimplement backend-owned product logic in Dart. If richer UI requires data the API does not provide, call out the backend contract gap instead of fabricating compatibility, match reasons, moderation state, or metrics on the client.

## Canonical Docs To Read

Read the smallest relevant set before editing:

- `README.md` - current repo overview, dependency inventory, setup, and backend highlights.
- `FLUTTER_PROJECT_HANDOFF.md` - backend/mobile contract details and original product constraints.
- `FLUTTER_FRONTEND_AGENT_GUIDE.md` - broader agent guidance and API cheat sheet.
- `CLAUDE.md` - concise architecture, commands, navigation, visual-review notes, and recent updates.
- `docs/visual-review-workflow.md` - screenshot workflow and visual fixture layout.
- `docs/superpowers/specs/2026-04-23-dating-app-ui-overhaul-design.md` - active in-progress UI-overhaul design brief and user requirements.
- `docs/superpowers/plans/` - historical and active implementation plans. Treat older status claims as historical unless verified against the current code.

## Verified Toolchain And Environment

These values were verified from project files, local SDK metadata, or direct commands on 2026-04-23.

| Item                          | Version / Value                                     | Verification source                                                  |
|-------------------------------|-----------------------------------------------------|----------------------------------------------------------------------|
| Flutter SDK                   | `3.41.7` stable                                     | `.metadata` revision plus local Flutter tag in SDK repo              |
| Flutter revision              | `cc0734ac716fbb8b90f3f9db8020958b1553afa7`          | `.metadata`                                                          |
| Flutter engine                | `59aa584fdf100e6c78c785d8a5b565d1de4b48ab`          | `C:\Users\tom7s\develop\flutter\bin\internal\engine.version`         |
| Dart SDK                      | `3.11.5`                                            | `pubspec.yaml`, `pubspec.lock`, Flutter SDK cache `dart-sdk/version` |
| Dart SDK constraint           | `^3.11.5`                                           | `pubspec.yaml`                                                       |
| Flutter SDK constraint        | `>=3.35.0`                                          | `pubspec.lock`                                                       |
| Flutter SDK path              | `C:\Users\tom7s\develop\flutter`                    | `android/local.properties`                                           |
| Android SDK path              | `C:\Users\tom7s\AppData\Local\Android\sdk`          | `android/local.properties`                                           |
| Android Gradle Plugin         | `8.13.2`                                            | `android/settings.gradle.kts`                                        |
| Kotlin Android plugin         | `2.3.20`                                            | `android/settings.gradle.kts`                                        |
| Flutter Gradle plugin loader  | `1.0.0`                                             | `android/settings.gradle.kts`                                        |
| Gradle wrapper                | `8.14.4`                                            | `android/gradle/wrapper/gradle-wrapper.properties`                   |
| Android Java bytecode target  | `17`                                                | `android/app/build.gradle.kts`                                       |
| Installed Android platforms   | `android-36`, `android-36.1`                        | local Android SDK directories                                        |
| Android build-tools installed | `35.0.0`, `36.1.0`, `37.0.0`                        | local Android SDK directories                                        |
| Android platform-tools        | `37.0.0`                                            | `platform-tools/source.properties`                                   |
| Android emulator              | `36.5.10`                                           | `emulator/source.properties`                                         |
| PowerShell                    | `7.6.1`                                             | `$PSVersionTable.PSVersion`                                          |
| Java commands on PATH         | Oracle Java `25.0.3.0`, Eclipse Adoptium `25.0.2.0` | `Get-Command java -All`                                              |
| Node.js                       | `v24.13.1`                                          | `node --version`                                                     |
| Bun                           | `1.3.13`                                            | `bun --version`                                                      |

CLI lookup note: `where.exe flutter` and `where.exe dart` may fail on this machine even when the commands work in an interactive PowerShell. Prefer direct commands first:

```powershell
flutter --version
dart --version
```

If direct command lookup fails too, use the SDK path pinned in `android/local.properties`:

```powershell
& 'C:\Users\tom7s\develop\flutter\bin\flutter.bat' --version
& 'C:\Users\tom7s\develop\flutter\bin\dart.bat' --version
```

Codex-shell caveat: during this file review, sandboxed direct `flutter --version` and `dart --version` timed out, and escalated direct invocations failed to start the SDK batch files with "The file cannot be accessed by the system." Treat that as a Codex execution caveat, not proof that the user's normal PowerShell cannot run Flutter or Dart.

## Local CLI Tools Verified

Prefer these tools when inspecting or refactoring:

| Tool            | Version  |
|-----------------|----------|
| `rg`            | `14.1.0` |
| `fd`            | `10.4.2` |
| `tokei`         | `12.1.2` |
| `sg` / ast-grep | `0.42.1` |
| `bat`           | `0.26.1` |
| `sd`            | `1.0.0`  |
| `jq`            | `1.8.1`  |
| `yq`            | `4.53.2` |

`semgrep --version` failed because the launcher exists but the Python module `semgrep` was missing. Do not rely on Semgrep until that install is repaired and verified.

## Dependencies

Direct dependencies from `pubspec.yaml` and exact locked versions from `pubspec.lock`:

| Package              | Locked version | Role                                        |
|----------------------|----------------|---------------------------------------------|
| `flutter`            | SDK package    | UI framework                                |
| `cupertino_icons`    | `1.0.9`        | icon font                                   |
| `flutter_riverpod`   | `3.3.1`        | app state and dependency injection          |
| `dio`                | `5.9.2`        | HTTP client                                 |
| `shared_preferences` | `2.5.5`        | local selected-user and preferences storage |
| `flutter_test`       | SDK package    | tests                                       |
| `flutter_lints`      | `6.0.0`        | analyzer lint set                           |

Important transitive/platform packages currently locked:

- `riverpod` `3.2.1`
- `dio_web_adapter` `2.1.2`
- `shared_preferences_android` `2.4.23`
- `shared_preferences_foundation` `2.5.6`
- `shared_preferences_linux` `2.4.1`
- `shared_preferences_web` `2.4.3`
- `shared_preferences_windows` `2.4.1`
- `shared_preferences_platform_interface` `2.4.2`
- `path_provider_linux` `2.2.1`
- `path_provider_windows` `2.3.0`
- `plugin_platform_interface` `2.1.8`
- `test` `1.30.0`
- `test_api` `0.7.10`
- `test_core` `0.6.16`

Use `pubspec.lock` as the full package inventory. Do not infer dependency availability from old docs.

## Runtime Configuration

Runtime config is centralized:

- `lib/app/env.dart` reads Dart defines.
- `lib/app/app_config.dart` exposes `appConfigProvider`.
- `.env` contains local values and is not auto-loaded by Flutter.
- Verified `.env` keys: `DATING_APP_API_BASE_URL`, `DATING_APP_SHARED_SECRET`.
- Default base URL in code: `http://127.0.0.1:7070`.
- Default shared secret in code: `lan-dev-secret`.
- App timeouts in `AppConfig`: 10 seconds connect, receive, and send.

Run with `.env` explicitly:

```powershell
flutter run -d windows --dart-define-from-file=.env
flutter run -d chrome --dart-define-from-file=.env
flutter run -d emulator-5554 --dart-define-from-file=.env
```

For Android emulator backend access, use `http://10.0.2.2:7070`. Do not use `localhost` from a physical phone; use the laptop LAN IP instead.

Android debug/profile cleartext HTTP is enabled:

- `android/app/src/debug/AndroidManifest.xml`
- `android/app/src/profile/AndroidManifest.xml`
- `android/app/src/main/res/xml/network_security_config.xml`

## Architecture Map

Current source layout:

```text
lib/
  main.dart
  app/                  app root, Env, AppConfig
  api/                  Dio client, endpoints, headers, API errors
  features/
    auth/               dev-user picker and selected-user provider/store
    browse/             discover, undo, standouts, pending likers
    chat/               conversations and thread
    home/               startup routing, health banner, signed-in shell
    location/           location completion and location providers
    matches/            matches list
    notifications/      notifications list/actions
    profile/            profile view/edit
    safety/             block/report/unmatch/blocked users
    settings/           theme mode and settings
    stats/              stats and achievements
    verification/       verification start/confirm
  models/               hand-written JSON DTOs
  shared/
    formatting/         date and display text helpers
    media/              media URL helper
    persistence/        shared_preferences provider
    providers/          selected-user guard
    widgets/            shared UI primitives
  theme/                Material 3 theme and shared tokens
```

Tests mirror the app structure under `test/`. Visual-review tests live under `test/visual_inspection/`.

## Navigation And State

- `main.dart` initializes `SharedPreferences` and injects it through `sharedPreferencesProvider`.
- `DatingApp` uses `MaterialApp`, `AppTheme.light()`, `AppTheme.dark()`, and `themeModeProvider`.
- There is no router package in the current code.
- `AppHomeScreen` chooses startup flow from `selectedUserProvider`.
- No selected user means `DevUserPickerScreen`.
- Selected user means `SignedInShell`.
- `SignedInShell` uses an `IndexedStack` with five bottom-navigation tabs:
  - Discover
  - Matches
  - Chats
  - Profile
  - Settings
- Additional screens are pushed imperatively from feature surfaces.
- Use `FutureProvider` for async API-backed reads, `NotifierProvider` where mutable state is needed, and `Provider` for dependency injection/controllers.
- Providers that require an acting user should use `lib/shared/providers/selected_user_guard.dart`.
- Keep side effects in providers/controllers, not in presentational widget build methods.

## API Rules

The API layer is centralized:

- Endpoints: `lib/api/api_endpoints.dart`
- Header rules: `lib/api/api_headers.dart`
- HTTP calls and JSON parsing: `lib/api/api_client.dart`
- Error mapping: `lib/api/api_error.dart`

Header behavior currently implemented:

- `GET /api/health` does not receive `X-DatingApp-Shared-Secret`.
- Every other path receives `X-DatingApp-Shared-Secret`.
- `X-User-Id` is added when `Options.extra['userId']` is set and the path starts with `/api/users/` or `/api/conversations/`.
- Do not add these headers manually in screen or feature code.

Current endpoint builders in `ApiEndpoints`:

- `GET /api/health`
- `GET /api/users`
- `GET /api/users/{id}`
- `PUT /api/users/{id}/profile`
- `GET /api/users/{id}/browse`
- `POST /api/users/{id}/like/{targetId}`
- `POST /api/users/{id}/pass/{targetId}`
- `POST /api/users/{id}/undo`
- `GET /api/users/{id}/matches`
- `GET /api/users/{id}/conversations`
- `GET /api/conversations/{conversationId}/messages`
- `POST /api/conversations/{conversationId}/messages`
- `GET /api/users/{id}/stats`
- `GET /api/users/{id}/achievements`
- `GET /api/users/{id}/pending-likers`
- `GET /api/users/{id}/standouts`
- `GET /api/users/{id}/notifications`
- `POST /api/users/{id}/notifications/read-all`
- `POST /api/users/{id}/notifications/{notificationId}/read`
- `GET /api/users/{id}/blocked-users`
- `POST /api/users/{id}/block/{targetId}`
- `DELETE /api/users/{id}/block/{targetId}`
- `POST /api/users/{id}/report/{targetId}`
- `POST /api/users/{id}/relationships/{targetId}/unmatch`
- `GET /api/location/countries`
- `GET /api/location/cities`
- `POST /api/location/resolve`
- `POST /api/users/{id}/verification/start`
- `POST /api/users/{id}/verification/confirm`

Known product/API constraints from current docs and code:

- Dev login is a user picker backed by `GET /api/users`.
- No signup, JWT, BCrypt login, WebSocket chat, push notifications, or offline-first sync exists in this frontend.
- Chat is conversation-scoped. Do not invent nested user-scoped message routes.
- Poll chat gently. `ConversationThreadScreen` defaults to a 20-second refresh interval while visible.
- Location UX should be server-driven through the location endpoints.
- If the backend response shape is unclear, add/adjust DTO tests before broad UI changes.

## Current Product Surfaces

Implemented frontend surfaces include:

- Dev-user picker
- Discover/browse with like, pass, daily pick, undo, pending likers, and standouts
- Matches
- Conversations and conversation thread with send-message
- Current-user and other-user profile views
- Profile editing
- Location completion
- Settings with persisted theme mode
- Notifications with read actions
- Stats and achievements
- Verification start/confirm
- Safety actions: block, unblock, report, unmatch, blocked users
- Backend health banner/provider
- Visual inspection fixture and screenshot workflow

This list describes frontend surfaces present in the repo. It does not prove backend availability in a live environment; verify live flows against the backend before claiming end-to-end success.

## UI And Design Rules

Material 3 is enabled through `uses-material-design: true` and `ThemeData(useMaterial3: true)`.

Shared UI primitives:

- `ShellHero` - `lib/shared/widgets/shell_hero.dart`
- `SectionIntroCard` - `lib/shared/widgets/section_intro_card.dart`
- `AppAsyncState` - `lib/shared/widgets/app_async_state.dart`
- `UserAvatar` - `lib/shared/widgets/user_avatar.dart`

Use these where they fit, but follow the active design brief when changing UI. The 2026-04-23 UI overhaul brief specifically calls for:

- people-first dating surfaces
- less purple/lavender dominance
- warmer, more varied visual language
- less redundant bottom/shell chrome
- overflow menus for contextual/safety actions instead of ambiguous shield icons
- compact, information-rich cards and lists
- developer-only controls visually separated and labeled
- no invented compatibility logic or reasons in Dart

For UI work, inspect the latest screenshots after running the visual suite. Do not judge UI quality from widget tests alone.

## Visual Review Workflow

Canonical command:

```powershell
flutter test test/visual_inspection/screenshot_test.dart
```

The suite renders a fixed `412 x 915` phone-sized surface and writes:

- `visual_review/latest/`
- `visual_review/latest/index.html`
- `visual_review/latest/manifest.json`
- archived runs under `visual_review/runs/`

Fixture data is under:

- `test/visual_inspection/fixtures/visual_fixture_catalog.dart`
- `test/visual_inspection/fixtures/visual_fixture_builders.dart`
- `test/visual_inspection/fixtures/visual_scenarios.dart`

After any UI change, run the relevant widget tests and the visual-review suite when feasible, then inspect the generated PNGs or HTML gallery.

## Common Commands

Use the project root as the working directory.

```powershell
flutter pub get
flutter analyze
flutter test
flutter test test/features/browse/browse_provider_test.dart
flutter test test/visual_inspection/screenshot_test.dart
flutter run -d windows --dart-define-from-file=.env
flutter run -d chrome --dart-define-from-file=.env
flutter run -d emulator-5554 --dart-define-from-file=.env
flutter doctor
```

If PATH lookup fails in this environment, run Flutter through:

```powershell
& 'C:\Users\tom7s\develop\flutter\bin\flutter.bat' test
```

## Testing Expectations

- For Dart code changes, run `flutter analyze` and the relevant `flutter test` target.
- For shared providers, models, API methods, or app shell changes, run broader tests because many screens share those layers.
- For UI changes, run screen-specific widget tests and the visual screenshot workflow.
- For API contract changes, add or update API client/model tests.
- Do not claim "fully fixed" or "end-to-end verified" unless you exercised the real path needed for that claim.
- If a Flutter command hangs or cannot run in the sandbox, state that clearly and give the file-level verification you did perform.

## Working Rules For Agents

- Start from current code, not old roadmap assumptions.
- Keep API/header logic centralized in `lib/api/**`.
- Keep request orchestration and state transitions in Riverpod providers/controllers.
- Keep widgets mostly declarative.
- Preserve selected dev user behavior between launches.
- Prefer incremental, focused changes over broad rewrites.
- Do not modify `.env` values or expose secrets.
- Do not clean generated logs, screenshots, or build artifacts unless the user explicitly asks.
- Respect dirty worktrees. Never revert unrelated user changes.
- Update docs when you intentionally change product assumptions, API behavior, or reusable workflows.
- Treat backend contract changes as cross-repo coordination, not a Flutter-only patch.
