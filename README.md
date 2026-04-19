# Flutter Dating Application Frontend

This repository is the new Flutter mobile frontend for an existing Java 25 backend.

The backend's Java code lives in a separate repository. This frontend repo itself is a Flutter/Dart project; the only Java-related item here is the Android build target used by the mobile toolchain.

The app is intentionally a **thin client**:

- Flutter owns UI, navigation, local app state, request orchestration, and presentation logic.
- The backend owns matching rules, message persistence, moderation, verification, location logic, and stats.

If something feels like business logic, it probably belongs on the server. The app should render the product, not secretly become the product brain in a trench coat.

## Current scope

The first useful milestone is the real core loop:

1. health check
2. dev user picker
3. browse candidates
4. like or pass
5. matches and conversations
6. send messages

Out of scope for this phase:

- real auth or JWT
- signup / account creation
- payments or subscriptions
- push notifications
- WebSocket chat
- large offline-sync systems

## Stack

- Flutter
- Dart
- Material 3
- Riverpod for state management
- Dio for HTTP
- shared_preferences for local dev-user persistence

## Tooling and dependency inventory

This section records the versions currently pinned or verified for this repo.
The values below come from `flutter --version --machine`, `pubspec.lock`, `.metadata`, `pubspec.yaml`, `analysis_options.yaml`, `devtools_options.yaml`, and the Android Gradle files.

### Languages and SDKs

| Item                       | Exact version                              | Notes                                   |
|----------------------------|--------------------------------------------|-----------------------------------------|
| Flutter SDK                | 3.41.7                                     | stable channel                          |
| Flutter framework revision | `cc0734ac716fbb8b90f3f9db8020958b1553afa7` | matches `.metadata`                     |
| Flutter engine revision    | `59aa584fdf100e6c78c785d8a5b565d1de4b48ab` | from local Flutter toolchain            |
| Dart SDK                   | 3.11.5                                     | also matches the project SDK constraint |
| Flutter DevTools           | 2.54.2                                     | from local Flutter toolchain            |
| Dart language constraint   | `>=3.11.5 <4.0.0`                          | from `pubspec.lock`                     |
| Flutter SDK constraint     | `>=3.35.0`                                 | from `pubspec.lock`                     |
| Android JVM target         | 17                                         | Android build bytecode target, not app source language |
| Kotlin                     | 2.2.20                                     | Android plugin version                  |

### Frameworks and build tooling

| Item                         | Exact version | Notes                                                   |
|------------------------------|---------------|---------------------------------------------------------|
| Material Design              | 3             | enabled with `uses-material-design: true`               |
| Gradle Wrapper               | 8.14          | from `android/gradle/wrapper/gradle-wrapper.properties` |
| Android Gradle Plugin        | 8.11.1        | from `android/settings.gradle.kts`                      |
| Flutter Gradle plugin loader | 1.0.0         | from `android/settings.gradle.kts`                      |

### Direct Dart and Flutter dependencies

| Package              | Exact version      | Purpose                                    |
|----------------------|--------------------|--------------------------------------------|
| `flutter`            | Flutter SDK 3.41.7 | core UI framework                          |
| `cupertino_icons`    | 1.0.9              | iOS-style icon set                         |
| `flutter_riverpod`   | 3.3.1              | state management                           |
| `dio`                | 5.9.2              | HTTP client                                |
| `shared_preferences` | 2.5.5              | local persistence for dev-user state       |
| `flutter_test`       | Flutter SDK 3.41.7 | widget and unit testing                    |
| `flutter_lints`      | 6.0.0              | lint rules used by `analysis_options.yaml` |

### Platform and generated plugin packages

| Package                                 | Exact version | Notes                                       |
|-----------------------------------------|---------------|---------------------------------------------|
| `dio_web_adapter`                       | 2.1.2         | Dio web transport                           |
| `riverpod`                              | 3.2.1         | core Riverpod engine pulled in transitively |
| `shared_preferences_android`            | 2.4.23        | Android backend for `shared_preferences`    |
| `shared_preferences_foundation`         | 2.5.6         | iOS/macOS backend for `shared_preferences`  |
| `shared_preferences_linux`              | 2.4.1         | Linux backend for `shared_preferences`      |
| `shared_preferences_web`                | 2.4.3         | Web backend for `shared_preferences`        |
| `shared_preferences_windows`            | 2.4.1         | Windows backend for `shared_preferences`    |
| `shared_preferences_platform_interface` | 2.4.2         | shared preferences platform contract        |
| `path_provider_linux`                   | 2.2.1         | Linux filesystem helper used transitively   |
| `path_provider_windows`                 | 2.3.0         | Windows filesystem helper used transitively |
| `path_provider_platform_interface`      | 2.1.2         | path provider platform contract             |
| `plugin_platform_interface`             | 2.1.8         | plugin platform abstraction                 |

### DevTools and extensions

| Item                       | Exact version        | Notes                                                                                   |
|----------------------------|----------------------|-----------------------------------------------------------------------------------------|
| Dart & Flutter DevTools    | 2.54.2               | reported by `flutter --version --machine`                                               |
| Enabled DevTools extension | `shared_preferences` | enabled in `devtools_options.yaml`; no separate extension version is pinned in the repo |

### Full locked pub package inventory

<details>
<summary>Expand the complete <code>pubspec.lock</code> inventory</summary>

- `_fe_analyzer_shared` 93.0.0
- `analyzer` 10.0.1
- `args` 2.7.0
- `async` 2.13.1
- `boolean_selector` 2.1.2
- `characters` 1.4.1
- `cli_config` 0.2.0
- `clock` 1.1.2
- `collection` 1.19.1
- `convert` 3.1.2
- `coverage` 1.15.0
- `crypto` 3.0.7
- `cupertino_icons` 1.0.9
- `dio` 5.9.2
- `dio_web_adapter` 2.1.2
- `fake_async` 1.3.3
- `ffi` 2.2.0
- `file` 7.0.1
- `flutter` 0.0.0 (SDK package provided by Flutter 3.41.7)
- `flutter_lints` 6.0.0
- `flutter_riverpod` 3.3.1
- `flutter_test` 0.0.0 (SDK package provided by Flutter 3.41.7)
- `flutter_web_plugins` 0.0.0 (SDK package provided by Flutter 3.41.7)
- `frontend_server_client` 4.0.0
- `glob` 2.1.3
- `http_multi_server` 3.2.2
- `http_parser` 4.1.2
- `io` 1.0.5
- `leak_tracker` 11.0.2
- `leak_tracker_flutter_testing` 3.0.10
- `leak_tracker_testing` 3.0.2
- `lints` 6.1.0
- `logging` 1.3.0
- `matcher` 0.12.19
- `material_color_utilities` 0.13.0
- `meta` 1.17.0
- `mime` 2.0.0
- `node_preamble` 2.0.2
- `package_config` 2.2.0
- `path` 1.9.1
- `path_provider_linux` 2.2.1
- `path_provider_platform_interface` 2.1.2
- `path_provider_windows` 2.3.0
- `platform` 3.1.6
- `plugin_platform_interface` 2.1.8
- `pool` 1.5.2
- `pub_semver` 2.2.0
- `riverpod` 3.2.1
- `shared_preferences` 2.5.5
- `shared_preferences_android` 2.4.23
- `shared_preferences_foundation` 2.5.6
- `shared_preferences_linux` 2.4.1
- `shared_preferences_platform_interface` 2.4.2
- `shared_preferences_web` 2.4.3
- `shared_preferences_windows` 2.4.1
- `shelf` 1.4.2
- `shelf_packages_handler` 3.0.2
- `shelf_static` 1.1.3
- `shelf_web_socket` 3.0.0
- `sky_engine` 0.0.0 (SDK package provided by Flutter 3.41.7)
- `source_map_stack_trace` 2.1.2
- `source_maps` 0.10.13
- `source_span` 1.10.2
- `stack_trace` 1.12.1
- `state_notifier` 1.0.0
- `stream_channel` 2.1.4
- `string_scanner` 1.4.1
- `term_glyph` 1.2.2
- `test` 1.30.0
- `test_api` 0.7.10
- `test_core` 0.6.16
- `typed_data` 1.4.0
- `vector_math` 2.2.0
- `vm_service` 15.1.0
- `watcher` 1.2.1
- `web` 1.1.1
- `web_socket` 1.0.1
- `web_socket_channel` 3.0.3
- `webkit_inspection_protocol` 1.2.1
- `xdg_directories` 1.1.0
- `yaml` 3.1.3

</details>

### Version notes

- Android `compileSdk`, `minSdk`, `targetSdk`, and `ndkVersion` are inherited from the Flutter Gradle plugin in Flutter 3.41.7 and are not hard-coded in this repository.
- iOS and macOS deployment target versions are not explicitly pinned in the committed project files.
- No project-specific VS Code extension versions are versioned in this repository.

## Outdated packages and upgrade path

After running `flutter upgrade` and `flutter pub upgrade --major-versions`, all **direct** dependencies and Android build tooling are already on the latest stable versions available to this project on Flutter 3.41.7. The only remaining outdated items are transitive packages blocked by the current Flutter SDK dependency graph.

### Outdated transitive packages

| Package               | Current | Latest | Upgrade note                                                                |
|-----------------------|---------|--------|-----------------------------------------------------------------------------|
| `_fe_analyzer_shared` | 93.0.0  | 99.0.0 | Blocked by the current Flutter 3.41.7 / Dart 3.11.5 dependency graph |
| `analyzer`            | 10.0.1  | 12.1.0 | Blocked by the current Flutter 3.41.7 / Dart 3.11.5 dependency graph |
| `meta`                | 1.17.0  | 1.18.2 | Blocked by the current Flutter 3.41.7 / Dart 3.11.5 dependency graph |
| `test`                | 1.30.0  | 1.31.0 | Blocked by the current Flutter test SDK dependency graph |
| `test_api`            | 0.7.10  | 0.7.11 | Blocked by the current Flutter test SDK dependency graph |
| `test_core`           | 0.6.16  | 0.6.17 | Blocked by the current Flutter test SDK dependency graph |
| `vector_math`         | 2.2.0   | 2.3.0  | Blocked by the current Flutter SDK dependency graph |

### How to upgrade everything that can move

1. Upgrade the Flutter SDK first when a newer stable release exists:
   - `flutter upgrade`
2. Refresh package resolution:
   - `flutter pub upgrade --major-versions`
3. Re-check what is still pinned:
   - `flutter pub outdated`
4. Verify the app still works:
   - `flutter test`
   - `flutter analyze`

If the transitive packages above stay on the old versions after `flutter pub upgrade --major-versions`, they are being held by the current Flutter SDK. In this repo's current state, that is exactly what happened on Flutter 3.41.7.

## Backend contract highlights

- The app talks to the backend over **REST/JSON only**.
- `GET /api/health` does **not** require the shared secret.
- All other LAN requests should send `X-DatingApp-Shared-Secret`.
- User-scoped requests should also send `X-User-Id`.
- The current dev login flow is a picker backed by `GET /api/users`.
- Use `GET /api/users/{id}/browse`, not the deprecated `/candidates` route.
- Chat messages are conversation-scoped via `/api/conversations/{conversationId}/messages`.

## Local setup

### Prerequisites

- Flutter SDK installed
- `flutter doctor` clean enough for your target platform
- backend running locally and reachable
- Android SDK installed if you want to run on Android

### Verify the app toolchain

Run the usual Flutter checks and make sure at least one target is available.

In this workspace, the app has been verified successfully on **Windows desktop** and an **Android emulator**. The current local Android flow uses an emulator talking to the host backend over `10.0.2.2`.

### Start the backend

This frontend depends on the existing Java backend being available over LAN or localhost. The detailed startup flow lives in `FLUTTER_PROJECT_HANDOFF.md`.

Your first connectivity success check should be:

- the chosen device can reach `GET /api/health`

### Important LAN warnings

- Do **not** use `localhost` from a physical phone.
- Use your laptop LAN IP such as `http://192.168.x.x:7070`.
- For Android emulator, use `http://10.0.2.2:7070`.
- Phase 3 development uses plain HTTP over LAN, so Android needs debug cleartext support enabled.

## Configuration

The app keeps backend configuration centralized.

Local development values live in `.env`:

- `DATING_APP_API_BASE_URL`
- `DATING_APP_SHARED_SECRET`

The app reads these values through Dart defines in `lib/app/env.dart`, so launch it with `.env` explicitly:

- `flutter run -d windows --dart-define-from-file=.env`
- `flutter run -d chrome --dart-define-from-file=.env`
- `flutter run -d emulator-5554 --dart-define-from-file=.env`

Important note:

- `.env` is ignored by git and is **not** auto-loaded unless you pass `--dart-define-from-file=.env`
- for an Android emulator, use `http://10.0.2.2:7070`
- for a physical Android phone, replace loopback or emulator hosts with your laptop LAN IP

The Flutter client keeps header injection centralized so request rules do not get scattered across screens.

## Implementation order

Recommended build order:

1. app shell and theme
2. centralized config and API client
3. dev user picker
4. browse flow
5. matches and conversations
6. chat

## Key docs

- `FLUTTER_PROJECT_HANDOFF.md` — source of truth for backend contract, routes, headers, and startup assumptions
- `docs/superpowers/plans/2026-04-18-mobile-bootstrap-foundation.md` — bootstrap implementation plan for this repo
- `docs/superpowers/plans/2026-04-18-health-browse-like-slice.md` — health, browse, like, and pass implementation plan
- `docs/superpowers/plans/2026-04-18-matches-conversations-shell.md` — signed-in shell, matches, and conversations implementation plan
- `docs/superpowers/plans/2026-04-18-chat-thread-send-message-slice.md` — chat thread and send-message implementation plan

## Current status

As of 2026-04-19:

- blank Flutter starter verified on Windows
- bootstrap plan written and attached in `docs/superpowers/plans/2026-04-18-mobile-bootstrap-foundation.md`
- app shell, theme, API foundation, Android LAN HTTP config, and dev user picker are in place
- backend health, browse candidates, and like/pass actions are now wired into the app shell
- a signed-in navigation shell now routes between Discover, Matches, and Chats for the selected dev user
- matches and conversations list screens are wired to the backend contract with loading, empty, retry, and refresh states
- conversation threads now load real messages, distinguish incoming/outgoing bubbles, allow sending messages through the backend contract, poll while visible, and auto-scroll to the latest message
- match cards now open the conversation thread directly using the backend's canonical pair ID contract
- Discover now offers a direct `Message now` handoff when a like becomes a mutual match, and matching also refreshes the Matches and Chats data sources
- current verification status: `flutter test`, `flutter analyze`, debug APK builds, and emulator-to-backend connectivity have all been verified in this workspace
- next feature slice should focus on broader chat UX polish and richer conversation list/thread quality-of-life details
