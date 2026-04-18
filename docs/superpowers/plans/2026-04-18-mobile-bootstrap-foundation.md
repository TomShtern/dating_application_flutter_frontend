# Mobile Bootstrap Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the blank Flutter starter into a small but real mobile client foundation for the dating app backend, including project docs, configuration, HTTP plumbing, and a working dev user picker entry flow.

**Architecture:** Keep the app a thin client. Use a small `app/` shell, a focused `api/` layer built on Dio, Riverpod providers for state and app wiring, and feature-first folders starting with `auth/`. Defer browse, matches, and chat implementation, but shape the project so those features can slot in without refactoring the app root.

**Tech Stack:** Flutter, Dart, Material 3, flutter_riverpod, dio, shared_preferences, flutter_test

---

## File map

### Modify
- `README.md` — replace generic Flutter starter text with project-specific onboarding
- `pubspec.yaml` — add Riverpod, Dio, and shared_preferences
- `lib/main.dart` — replace counter app entry point with ProviderScope app bootstrap
- `test/widget_test.dart` — replace counter test with app-shell/dev-user-picker smoke test
- `android/app/src/main/AndroidManifest.xml` — keep main app config aligned with networking needs
- `android/app/src/debug/AndroidManifest.xml` — allow cleartext HTTP during debug LAN development
- `android/app/src/profile/AndroidManifest.xml` — optional parity for profile LAN development
- `.gitignore` — ignore local `.env`

### Create
- `.env` — local placeholders for backend base URL and shared secret
- `android/app/src/main/res/xml/network_security_config.xml` — debug/profile cleartext LAN support
- `lib/app/app.dart`
- `lib/app/app_config.dart`
- `lib/app/env.dart`
- `lib/api/api_client.dart`
- `lib/api/api_endpoints.dart`
- `lib/api/api_error.dart`
- `lib/api/api_headers.dart`
- `lib/features/auth/dev_user_picker_screen.dart`
- `lib/features/auth/selected_user_provider.dart`
- `lib/features/auth/selected_user_store.dart`
- `lib/models/user_summary.dart`
- `lib/shared/widgets/app_async_state.dart`
- `lib/theme/app_theme.dart`

## Task 1: Verify the starter baseline
- [x] Run the starter test suite before changing code
- [x] Launch the untouched starter app on an available local target (Windows or web if Android SDK is unavailable)
- [x] Record any environment blockers in the README notes

## Task 2: Replace the project README
- [x] Rewrite `README.md` so it explains project purpose, scope, stack, setup, backend assumptions, and near-term roadmap
- [x] Keep `FLUTTER_PROJECT_HANDOFF.md` as the detailed backend/mobile contract and reference it from the README
- [x] Add warnings about LAN IP usage, shared-secret requirements, and current lack of real auth

## Task 3: Add core dependencies and local config placeholders
- [x] Add `flutter_riverpod`, `dio`, and `shared_preferences` to `pubspec.yaml`
- [x] Keep the dependency set intentionally small
- [x] Add `.env` with local development keys for `DATING_APP_API_BASE_URL` and `DATING_APP_SHARED_SECRET`
- [x] Ignore `.env` in `.gitignore`

## Task 4: Build the app shell
- [x] Replace the default counter app with a `ProviderScope` bootstrap
- [x] Create `App` and Material 3 theme wiring under `lib/app/` and `lib/theme/`
- [x] Route the initial experience to the dev user picker screen
- [x] Add a shared loading/error/empty-state helper widget for first-pass UX

## Task 5: Wire the API foundation
- [x] Centralize compile-time/runtime config in `app_config.dart` and `env.dart`
- [x] Add endpoint constants and request-header helpers
- [x] Build a Dio API client with consistent base URL, timeouts, and API error mapping
- [x] Add Android debug/profile cleartext support for HTTP LAN development

## Task 6: Implement the dev user picker vertical slice
- [x] Add `UserSummary` model for `GET /api/users`
- [x] Add a `SelectedUserStore` for persistence via `shared_preferences`
- [x] Add Riverpod providers for loading users, hydrating selected user, and saving user selection
- [x] Build a dev user picker screen with loading, empty, error, retry, and select states
- [x] Make selection persistence visible in the UI so the app has a clear “current user” state

## Task 7: Re-test and validate
- [x] Update `test/widget_test.dart` so it exercises the new app shell instead of the deleted counter app
- [x] Run Flutter tests after the rewrite
- [x] Run a lightweight analysis/build validation pass
- [x] Verify the new app boots on the currently available local target

## Notes
- Android SDK is not installed in this environment yet, so baseline verification and post-change boot validation should use Windows desktop or web unless that toolchain changes.
- Android LAN HTTP support still matters because the intended mobile target is Android; debug/profile manifests should explicitly allow cleartext traffic for Phase 3 development.
- The app should not implement real authentication or server business rules in this bootstrap phase.