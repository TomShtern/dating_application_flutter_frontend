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

## Read First

- Start with `AGENTS.md` for the verified repo-wide operating rules and constraints.
- Read `docs/design-language.md` before changing UI structure, visual styling, shared widgets, or any `AppTheme` usage.
- Use `docs/visual-review-workflow.md` when a task changes appearance or layout.
- For per-screen design intent (one-pager per screen: hero choice, layout structure, copy tone, do/don't), see `screen-transform-prompts/prompt-<screen-name>.md`. Consult the matching file before redesigning a covered screen.
- For broader product/visual context, recent visual-lock and design-critique docs live under `docs/` (e.g. `docs/2026-04-30-run-0131-final-visual-lock-review.md`, `docs/design-critique-run-0119.md`).

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
- `ApiError.fromDioException()` produces smart connection error messages that detect loopback URLs and suggest the Android emulator address

When adding new endpoints, use the response parsing helpers in `ApiClient`: `_expectMap()`, `_expectList()`, `_extractWrappedList()`. Never write raw `as Map` / `as List` casts inline.

### Shared Widget System

`lib/shared/widgets/` is the app's design system. **Always use these — do not reinvent equivalent structure in feature code.**

The canonical visual reference now lives in `docs/design-language.md`. Treat that file as the source of truth for spacing tokens, radius tokens, `AppTheme` helpers, hero selection, semantic colours, interaction rules, and shared-widget usage patterns.

**Core layout widgets (required on every new screen):**

| Widget             | File                          | Purpose                                                            |
|--------------------|-------------------------------|--------------------------------------------------------------------|
| `ShellHero`        | `shell_hero.dart`             | Full-width hero header for tab and detail screens                  |
| `AppRouteHeader`   | `app_route_header.dart`       | Pushed-route header: back affordance + title/subtitle + trailing   |
| `SectionIntroCard` | `section_intro_card.dart`     | Framing card for sparse or utility screens                         |
| `AppGroupLabel`    | `app_group_label.dart`        | Sectioned list label with accent rail + optional count/trailing    |
| `AppAsyncState`    | `app_async_state.dart`        | Unified loading / error / empty state renderer                     |

**Person / media display:**

| Widget                 | File                        | Purpose                                                  |
|------------------------|-----------------------------|----------------------------------------------------------|
| `PersonPhotoCard`      | `person_photo_card.dart`    | Person card: avatar circle + name/age/location           |
| `UserAvatar`           | `user_avatar.dart`          | Circular avatar with ring, monogram fallback             |
| `PersonMediaThumbnail` | `person_media_thumbnail.dart` | Rectangular thumbnail (96×128) with gradient fallback  |

**Metadata and interaction:**

| Widget                 | File                          | Purpose                                                 |
|------------------------|-------------------------------|---------------------------------------------------------|
| `CompactContextStrip`  | `compact_context_strip.dart`  | Single-line metadata: icon + label (location, age, …)  |
| `CompactSummaryHeader` | `compact_summary_header.dart` | Name + subtitle + action row for cards/rows            |
| `CompatibilityMeter`   | `compatibility_meter.dart`    | Score bar 0–100 with colour-coded label (green/orange/gray) |
| `HighlightTagRow`      | `highlight_tag_row.dart`      | Horizontally scrollable chip row (match highlights, tags) |
| `ViewModeToggle`       | `view_mode_toggle.dart`       | List / grid segmented button toggle                     |
| `AppOverflowMenuButton`| `app_overflow_menu_button.dart` | Generic kebab (⋮) popup menu                         |
| `DeveloperOnlyCalloutCard` | `developer_only_callout_card.dart` | Amber-tinted dev-only surface; use in dev flows  |

### AppTheme Utility API

`AppTheme` in `lib/theme/app_theme.dart` exposes static helpers used throughout the app. Prefer these over inline `BoxDecoration` / `BoxShadow` literals:

- **Gradients**: `heroGradient(context)`, `accentGradient(context)`, `avatarGradient(context)`
- **Match palette**: `matchAccent(context)`, `matchAccentSecondary(context)`, `matchTintColor(context)`, `activeColor(context)`, `matchTextPrimary/Secondary/Tertiary(context)` — semantic colours for match cards, compatibility, and active states
- **Shadows**: `softShadow(context)`, `floatingShadow(context)`
- **Decorations**: `surfaceDecoration(context, {gradient, prominence})`, `glassDecoration(context)`
- **Spacing**: `screenPadding()`, `sectionPadding()`, `sectionSpacing()`, `listSpacing()` — all have `compact:` variants
- **Bottom-nav-aware scroll padding**: `shellScrollPadding()` for tab screens (clears the bottom nav so list content is never obscured); `bottomActionScrollPadding()` for screens with a fixed bottom action bar. Use these instead of hand-rolling bottom inset math.

Do not introduce magic spacing, radius, or decoration values when an `AppTheme` token already exists. Follow `docs/design-language.md` for the current token set and intended use.

### Selected User Guard

`lib/shared/providers/selected_user_guard.dart` exposes three guards — choose the right one per provider type:

| Guard                         | Use in                               |
|-------------------------------|--------------------------------------|
| `watchSelectedUser(ref)`      | `FutureProvider` body                |
| `requireSelectedUser(ref)`    | Notifier / controller methods        |
| `requireActionableTargetUser(ref, targetId)` | Actions targeting another user |

All three throw a typed error when no user is selected; never bypass or re-implement this check.

### Profile Edit Pattern

Profile edit uses a snapshot / request split:
- Read: `ApiClient.getProfileEditSnapshot()` → `ProfileEditSnapshot` (read-only + editable fields together)
- Write: submit only changed fields via `ProfileUpdateRequest` (partial update)

### Testing

**Do not create widget tests, regression tests, or integration tests during frontend/UI/design work.** The default for any task that touches screens, layouts, visual styling, or design is: no new tests. Only write tests when the user explicitly requests them and the frontend is in a finalized, stable state.

During active frontend iteration, use the visual-review screenshot workflow for quality assurance — not widget assertions. If existing tests break due to a UI refactor, fix the broken tests but do not add new ones.

Non-frontend code (providers, models, API contracts, state logic) follows normal testing judgment.

Tests mirror the `lib/` folder structure under `test/`. Visual/screenshot golden tests live in `test/visual_inspection/` and require font loading via `test/visual_inspection/flutter_test_config.dart`.

**FakeApiClient pattern**: test files extend `ApiClient` and override specific methods to return controlled responses — do not use Mockito or manual mocks. See `test/features/browse/` for examples.

**Provider overrides**: wrap the widget under test in `ProviderScope(overrides: [...])` to inject fake providers.

## Visual Review Workflow

See `docs/visual-review-workflow.md` for the full specification.

The suite runs every covered screen at a fixed 412×915 viewport and writes output to `visual_review/latest/`. Every run gets a monotonic run number (`run-0001`, `run-0002`, …).

**After any UI change, re-check the result against `docs/design-language.md`, then run the visual suite and inspect the PNGs before closing the task.** The HTML gallery at `visual_review/latest/index.html` is the fastest way to review all screens at once.

Covered screens: dev-user picker, Discover, Matches, Chats, Profile, Settings, conversation thread, Standouts, Pending likers, other-user profile, profile edit, location completion, stats, achievements, verification, blocked users, notifications.

## Key Constraints

- **No real signup/auth** — `DevUserPickerScreen` is the only auth flow; it selects from users already in the backend DB
- **Android first** — primary target platform for development and testing
- **HTTP cleartext** is allowed for LAN development (configured in Android manifest)
- **`selectedUserGuard`** — must be used in any provider that requires an authenticated context (see above)
- **Design system** — new screens must use the shared widget system and the rules in `docs/design-language.md` to stay visually consistent with the rest of the app
