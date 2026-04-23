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

# Visual review — captures fresh screenshots of every covered screen
flutter test test/visual_inspection/screenshot_test.dart
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
└── shared/       # Cross-feature utilities (formatting, media URLs, guards, widgets)
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

Additional non-tab screens pushed from within the shell: Standouts, Pending likers, Conversation thread, Profile edit, Location completion, Stats, Achievements, Verification, Blocked users, Notifications.

### State Management (Riverpod)

| Pattern            | Used for                                                  |
|--------------------|-----------------------------------------------------------|
| `FutureProvider`   | Async data fetches (browse candidates, matches, messages) |
| `NotifierProvider` | Mutable state with methods (app preferences)              |
| `Provider`         | DI and sync derived values (ApiClient, SharedPreferences) |

Controllers handle side effects (API calls, `ref.invalidate`). Screens only read/watch providers.

### API Layer

- Base URL defaults to `http://127.0.0.1:7070`; override via `DATING_APP_API_BASE_URL` dart-define
- Shared secret defaults to `lan-dev-secret`; override via `DATING_APP_SHARED_SECRET` dart-define
- Android emulator: use `http://10.0.2.2:7070` (not `127.0.0.1`)
- All request headers (`X-DatingApp-Shared-Secret`, `X-User-Id`) are injected centrally in `lib/api/api_headers.dart` — never add them ad hoc in feature code
- No real authentication. The "selected user" (stored in SharedPreferences) is injected as `X-User-Id` on every request

### Shared Widget System

Three shared widgets establish the app's visual design system. **Always use them — do not reinvent equivalent structure in feature code.**

| Widget             | File                                         | Purpose                                           |
|--------------------|----------------------------------------------|---------------------------------------------------|
| `ShellHero`        | `lib/shared/widgets/shell_hero.dart`         | Full-width hero header for tab and detail screens |
| `SectionIntroCard` | `lib/shared/widgets/section_intro_card.dart` | Framing card for sparse or utility screens        |
| `AppAsyncState`    | `lib/shared/widgets/app_async_state.dart`    | Unified loading / error / empty state renderer    |

### Testing

Tests mirror the `lib/` folder structure under `test/`. Visual/screenshot golden tests live in `test/visual_inspection/` and require font loading via `test/visual_inspection/flutter_test_config.dart`.

## Visual Review Workflow

See `docs/visual-review-workflow.md` for the full specification.

The suite runs every covered screen at a fixed 412×915 viewport and writes output to `visual_review/latest/`. Every run gets a monotonic run number (`run-0001`, `run-0002`, …).

**After any UI change, run the visual suite and inspect the PNGs before closing the task.** The HTML gallery at `visual_review/latest/index.html` is the fastest way to review all screens at once.

Covered screens: dev-user picker, Discover, Matches, Chats, Profile, Settings, conversation thread, Standouts, Pending likers, other-user profile, profile edit, location completion, stats, achievements, verification, blocked users, notifications.

## Key Constraints

- **No real signup/auth** — `DevUserPickerScreen` is the only auth flow; it selects from users already in the backend DB
- **Android first** — primary target platform for development and testing
- **HTTP cleartext** is allowed for LAN development (configured in Android manifest)
- **`selectedUserGuard`** (`lib/shared/providers/selected_user_guard.dart`) must be used in any provider that requires an authenticated context — it throws a typed error if no user is selected
- **Design system** — new screens must use `ShellHero`, `SectionIntroCard`, and `AppAsyncState` to stay visually consistent with the rest of the app

## Recent Updates (2026-04-22)

- **Full UI polish system** — two successive polish passes established a shared design language across all screens. The shared widget system (`ShellHero`, `SectionIntroCard`, `AppAsyncState`) is now the source of truth for headers, intro framing, and async states.
- **New features wired up end-to-end** — Standouts, Pending likers, Notifications, Location completion, Blocked users, and Verification now have real providers and API calls (previously stub or partial).
- **New models** — `BlockedUserSummary`, `LocationCountry`, `LocationCity`, `ResolvedLocation`, `NotificationItem`, `PendingLiker`, `Standout`, `VerificationResult` added to `lib/models/`.
- **Location API** — `ApiClient` now exposes `getLocationCountries()`, `getLocationCities()`, and `resolveLocation()`.
- **Visual review workflow** — observability-first screenshot suite established. Run `flutter test test/visual_inspection/screenshot_test.dart` to produce a fresh set of PNGs and an HTML gallery. See `docs/visual-review-workflow.md`.
