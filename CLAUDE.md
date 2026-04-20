# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Dependencies
flutter pub get

# Run (Android emulator — needs backend on LAN)
flutter run --dart-define=DATING_APP_API_BASE_URL=http://10.0.2.2:7070 --dart-define=DATING_APP_SHARED_SECRET=lan-dev-secret

# Run all tests
flutter test

# Run a single test file
flutter test test/features/browse/browse_provider_test.dart

# Static analysis
flutter analyze
```

## Architecture

**Thin client.** The Java backend owns all business logic and validation. This client owns only presentation. Never reimplement server-side rules in Dart.

### Layer Overview

```
lib/
├── app/          # App shell, Env (dart-defines), AppConfig provider
├── api/          # Dio client, endpoints, headers, error types
├── models/       # JSON-deserialised DTOs (immutable data classes)
├── theme/        # AppTheme.light() / AppTheme.dark(), shared constants
├── features/     # One folder per product feature (see below)
└── shared/       # Cross-feature utilities (formatting, media URLs, guards)
```

### Feature Structure

Each feature under `lib/features/<name>/` contains:
- `*_provider.dart` — Riverpod providers (FutureProvider, NotifierProvider, or Provider)
- `*_screen.dart` — ConsumerWidget/ConsumerStatefulWidget UI
- Controllers are plain classes returned by a `Provider`

### Navigation

No router package. `AppHomeScreen` watches `selectedUserProvider`:
- No user selected → `DevUserPickerScreen` (dev-only auth flow)
- User selected → `SignedInShell` (IndexedStack with 5 bottom-nav tabs: Discover, Matches, Chats, Profile, Settings)

### State Management (Riverpod)

| Pattern | Used for |
|---|---|
| `FutureProvider` | Async data fetches (browse candidates, matches, messages) |
| `NotifierProvider` | Mutable state with methods (app preferences) |
| `Provider` | DI and sync derived values (ApiClient, SharedPreferences) |

Controllers handle side effects (API calls, `ref.invalidate`). Screens only read/watch providers.

### API Layer

- Base URL defaults to `http://127.0.0.1:7070`; override via `DATING_APP_API_BASE_URL` dart-define
- Shared secret defaults to `lan-dev-secret`; override via `DATING_APP_SHARED_SECRET` dart-define
- Android emulator: use `http://10.0.2.2:7070` (not `127.0.0.1`)
- All request headers (`X-DatingApp-Shared-Secret`, `X-User-Id`) are injected centrally in `lib/api/api_headers.dart` — never add them ad hoc in feature code
- No real authentication. The "selected user" (stored in SharedPreferences) is injected as `X-User-Id` on every request

### Testing

Tests mirror the `lib/` folder structure under `test/`. Visual/screenshot golden tests live in `test/visual/` and require font loading via `flutter_test_config.dart`.

## Key Constraints

- **No real signup/auth** — `DevUserPickerScreen` is the only auth flow; it selects from users already in the backend DB
- **Android first** — primary target platform for development and testing
- **HTTP cleartext** is allowed for LAN development (configured in Android manifest)
- **`selectedUserGuard`** (`lib/shared/providers/selected_user_guard.dart`) must be used in any provider that requires an authenticated context — it throws a typed error if no user is selected
