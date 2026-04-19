# AGENTS.md

This repository is the Flutter frontend for the dating app. It is a **thin client** over a Java backend, so keep the server as the source of truth for business rules, matching, messaging, moderation, verification, stats, and storage.

## Start here

Read these docs first when you need product or contract context:

- [`README.md`](README.md)
- [`FLUTTER_PROJECT_HANDOFF.md`](FLUTTER_PROJECT_HANDOFF.md)
- [`FLUTTER_FRONTEND_AGENT_GUIDE.md`](FLUTTER_FRONTEND_AGENT_GUIDE.md)
- [`docs/superpowers/plans/`](docs/superpowers/plans/)
- [`docs/2026-04-19-project-state-review.md`](docs/2026-04-19-project-state-review.md)

## Working rules

- Keep Flutter focused on UI, navigation, local app state, and HTTP orchestration.
- Prefer the existing stack: Flutter, Material 3, Riverpod, Dio, and `shared_preferences`.
- Keep API/header logic centralized in `lib/api/**`; do not scatter `X-DatingApp-Shared-Secret` or `X-User-Id` handling across screens.
- Use the dev-user picker flow; do not assume signup, JWT auth, or WebSocket chat exist.
- Respect the current product reality: Android-first, iOS later, REST/JSON only, and gentle polling for chat.
- Treat `lib/features/**` as screen and feature code, `lib/api/**` as HTTP code, `lib/models/**` as DTOs, `lib/shared/**` as reusable utilities, and `lib/theme/**` as app styling.
- Keep widgets mostly declarative; put request orchestration and state transitions in Riverpod providers or notifiers.
- Make changes incrementally and preserve the selected dev user between launches.
- If you change product assumptions or API behavior, update the linked docs instead of duplicating the whole contract here.

## Local development reminders

- Local values live in `.env` and must be passed explicitly with `--dart-define-from-file=.env`.
- The app reads `DATING_APP_API_BASE_URL` and `DATING_APP_SHARED_SECRET` through `lib/app/env.dart`.
- `GET /api/health` does not require the shared secret.
- Android emulator should use `http://10.0.2.2:7070`; physical devices should use the laptop LAN IP.
- Do not use `localhost` from a real phone.

## Useful commands

- `flutter run -d windows --dart-define-from-file=.env`
- `flutter run -d chrome --dart-define-from-file=.env`
- `flutter run -d emulator-5554 --dart-define-from-file=.env`
- `flutter test`
- `flutter analyze`
- `flutter doctor`

## Before you finish

- Run the relevant Flutter tests and analyzer checks for the files you changed.
- Prefer the existing docs and plans over guessing.
- Keep the core loop in mind: pick a user, browse, like/pass, see matches, open a conversation, send messages.
