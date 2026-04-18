# Flutter Dating Application Frontend

This repository is the new Flutter mobile frontend for an existing Java backend.

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

In this workspace, the starter app was verified successfully on **Windows desktop**. Android is still the intended mobile target, but Android SDK setup is still required on this machine before local Android runs will work.

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

Important note:

- `.env` is ignored by git and is **not** auto-loaded unless you pass `--dart-define-from-file=.env`
- for a physical Android phone, replace `127.0.0.1` with your laptop LAN IP

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

As of 2026-04-18:

- blank Flutter starter verified on Windows
- bootstrap plan written and attached in `docs/superpowers/plans/2026-04-18-mobile-bootstrap-foundation.md`
- app shell, theme, API foundation, Android LAN HTTP config, and dev user picker are in place
- backend health, browse candidates, and like/pass actions are now wired into the app shell
- a signed-in navigation shell now routes between Discover, Matches, and Chats for the selected dev user
- matches and conversations list screens are wired to the backend contract with loading, empty, retry, and refresh states
- conversation threads now load real messages, distinguish incoming/outgoing bubbles, and allow sending messages through the backend contract
- current verification status: `flutter test`, `flutter analyze`, and Windows launches with `--dart-define-from-file=.env` all passed for the latest chat slice
- next feature slice should focus on modest thread refresh/polling, match-to-thread entry refinement, and broader chat UX polish
