# Flutter Dating App — Project State Review

> Review date: 2026-04-19
> Snapshot: current `main` branch, all source and test files

## Test Results Summary

| Metric | Value |
|--------|-------|
| Tests passing | 56 |
| Tests failing (compilation) | 3 |
| Analyzer errors | 7 |
| Analyzer warnings | 2 |
| Analyzer info | 3 |
| Total source files (lib/) | ~30 |
| Total test files (test/) | ~24 |
| Total models | 13 |

**Test command output:**

```
00:13 +59 -4: Some tests failed.
```

**Analyzer output:**

```
13 issues found. (ran in 3.3s)
```

---

## What Is Good

### 1. Architecture matches the handoff specification

The project structure follows the recommended layout from `FLUTTER_PROJECT_HANDOFF.md` almost exactly:

```
lib/
  api/          — centralized HTTP layer
  app/          — app config, environment, root widget
  features/     — feature-based organization
  models/       — clean DTOs
  shared/       — reusable widgets and persistence
  theme/        — Material 3 theming
```

Feature modules are well-bounded: `auth`, `browse`, `matches`, `chat`, `profile`, `safety`, `settings`, `home`.

### 2. API layer is properly centralized

- `ApiClient` wraps all endpoints with typed Dart methods. No raw string manipulation outside the client.
- `ApiHeaders.build()` centralizes the shared-secret and user-id injection logic in one place, exactly as the handoff mandates.
- `ApiError.fromDioException()` maps backend error bodies, connection failures, and Android emulator URL hints into user-facing messages.
- `ApiEndpoints` is a clean static class matching the backend contract.
- The Dio interceptor injects headers on every request without scattering logic across screens.

### 3. The v0.1 core loop is functionally complete

All six steps from the handoff's first mobile loop are implemented:

| Step | Screen | Endpoint | Status |
|------|--------|----------|--------|
| Select a dev user | `DevUserPickerScreen` | `GET /api/users` | Done |
| Browse candidates | `BrowseScreen` | `GET /api/users/{id}/browse` | Done |
| Like or pass | `BrowseScreen` | `POST /api/users/{id}/like/{targetId}` | Done |
| See matches | `MatchesScreen` | `GET /api/users/{id}/matches` | Done |
| Open a conversation | `ConversationsScreen` | `GET /api/users/{id}/conversations` | Done |
| Send messages | `ConversationThreadScreen` | `POST /api/conversations/{id}/messages` | Done |

### 4. v0.2 features are partially built

| Feature | Status |
|---------|--------|
| Profile view (self and other user) | Done |
| Profile edit screen with form validation | Done |
| Safety actions (block, report, unmatch) with confirmation dialogs | Done |
| Settings with theme switching (system / light / dark) | Done |
| Daily pick card in browse | Done |
| Backend health banner on key screens | Done |

### 5. Solid state management patterns

- Riverpod `FutureProvider` for data fetching, `Provider` for controllers.
- Provider invalidation after mutations triggers UI refresh automatically.
- `SelectedUserStore` persists the dev user choice via `SharedPreferences`.
- `AppPreferencesStore` persists theme mode.
- `BrowseController` correctly invalidates `matchesProvider` and `conversationsProvider` on match.

### 6. UI / UX quality

- Consistent loading / empty / error states via the reusable `AppAsyncState` widget.
- Match notification SnackBar with a "Message now" action button.
- Chat auto-scrolls to latest message.
- Chat polling pauses when the app is backgrounded (`WidgetsBindingObserver` + `AppLifecycleState`).
- Safety action sheet has proper confirmation dialogs for destructive actions.
- Location-missing warning in browse.
- Browse conflict state (409) handled with a dedicated UI state.

### 7. Test coverage breadth

- API layer: `api_headers_test.dart`, `api_error_test.dart`
- Models: 8 model parsing tests covering all major DTOs
- Screens: `browse_screen_test.dart`, `matches_screen_test.dart`, `conversation_thread_screen_test.dart`, `profile_screen_test.dart`, `profile_edit_screen_test.dart`, `settings_screen_test.dart`
- Providers: `browse_provider_test.dart`, `matches_provider_test.dart`, `conversation_thread_provider_test.dart`, `profile_provider_test.dart`
- Auth: `selected_user_store_test.dart`
- Settings: `app_preferences_store_test.dart`
- App root: `app_test.dart`

---

## What Is Broken

### Critical: `SelectedUserStore.readSelectedUser()` has a nested method bug

**File:** `lib/features/auth/selected_user_store.dart`, lines 14–36

The `readSelectedUser()` method at line 14 contains a **duplicate nested definition** of itself inside its own body (lines 20–36). The outer method never returns anything — the inner method is defined but never called, and the outer function body completes without a return value.

```dart
// Line 14: outer method opens
Future<UserSummary?> readSelectedUser() async {
  final rawUser = _preferences.getString(storageKey);
  if (rawUser == null || rawUser.isEmpty) {
    return null;
  }

  // Line 20: BUG — inner method redeclared inside the outer one
  Future<UserSummary?> readSelectedUser() async {
    // ... actual parsing logic ...
  }
  // Line 36: outer method closes without returning anything
}
```

The Dart analyzer confirms both issues:

- `body_might_complete_normally_nullable` — function can complete without returning a value.
- `unused_element` — the inner `readSelectedUser` is never referenced.

**Impact:** The selected user persistence is **completely broken**. Any previously saved user will never be read back, so `selectedUserProvider` always resolves to `null`, and the user is forced to re-select on every app launch.

**Test that catches it:** `selected_user_store_test.dart` fails with:

```
Expected: <Instance of 'UserSummary'>
Actual: <null>
```

**Fix:** Remove the inner nested method definition and keep only the outer method body with the parsing logic.

### Test compilation failure: `signed_in_shell_test.dart`

**File:** `test/features/home/signed_in_shell_test.dart`, lines 70 and 115

The tests override `appPreferencesProvider` with:

```dart
appPreferencesProvider.overrideWith((ref) async => const AppPreferences())
```

But `AppPreferencesController` extends `Notifier<AppPreferences>`, not `AsyncNotifier`. The override lambda returns `Future<AppPreferences>` instead of creating an `AppPreferencesController`.

```
The argument type 'Future<AppPreferences> Function(dynamic)' can't be assigned
to the parameter type 'AppPreferencesController Function()'.
```

**Fix:** Change the override to use a synchronous `Notifier` override:

```dart
appPreferencesProvider.overrideWith(() => TestAppPreferencesController())
```

Or mock the preferences store provider instead.

### Test compilation failure: `safety_action_sheet_test.dart`

**File:** `test/features/safety/safety_action_sheet_test.dart`, lines 41, 78, 102

Uses `const MaterialApp(...)` with non-constant expressions like `otherUser.id` and `currentUser.name`. `UserSummary` properties cannot be accessed in a const context.

```
Error: Not a constant expression.
  targetUserId: otherUser.id,
```

**Fix:** Remove `const` from the `MaterialApp` constructor and the surrounding widget tree.

### Test compilation failure: `widget_test.dart`

**File:** `test/widget_test.dart`, lines 38, 91, 210

References `sharedPreferencesProvider` without importing `shared_preferences_provider.dart`.

```
Error: Undefined name 'sharedPreferencesProvider'.
```

**Fix:** Add the missing import:

```dart
import 'package:flutter_dating_application_1/shared/persistence/shared_preferences_provider.dart';
```

### Deprecated API usage

**File:** `lib/features/profile/profile_screen.dart`, line 263

Uses `surfaceVariant` which is deprecated since Flutter 3.18. Should be `surfaceContainerHighest`.

---

## What Is Missing

### From the handoff roadmap — not yet implemented

| Feature | Backend Endpoint | Flutter Status |
|---------|-----------------|----------------|
| Undo last swipe | `POST /api/users/{id}/undo` | No UI button |
| Standouts | `GET /api/users/{id}/standouts` | No screen |
| Pending likers | `GET /api/users/{id}/pending-likers` | No screen |
| Match quality | `GET /api/users/{id}/match-quality/{matchId}` | No UI |
| Blocked users list | `GET /api/users/{id}/blocked-users` | No screen |
| Friend requests | Full CRUD exists | No UI |
| Notifications | Full CRUD exists | No screen |
| Stats | `GET /api/users/{id}/stats` | No screen |
| Achievements | `GET /api/users/{id}/achievements` | No screen |
| Verification flow | Start + confirm endpoints exist | No UI |
| Profile notes | Full CRUD exists | No UI |
| Location search | Countries, cities, resolve endpoints exist | No UI |
| Graceful exit | `POST /api/users/{id}/relationships/{targetId}/graceful-exit` | No UI |

### Infrastructure and quality gaps

| Gap | Detail |
|-----|--------|
| **No router** | Using imperative `Navigator.push` everywhere. The handoff recommends `go_router`. A bottom-nav shell with declarative routes would be more maintainable. |
| **No integration tests** | Only unit and widget tests. No end-to-end smoke test for the full core loop. |
| **No proper swipe cards** | Browse screen uses basic Cards, not the swipe-card UX typical of dating apps. The handoff says "Favor strong visual hierarchy" and "Make the like and pass actions obvious and one-handed." |
| **No image caching** | `Image.network` is used directly in the profile screen. The handoff lists `cached_network_image` as a likely later dependency. |
| **No pagination UI** | Backend supports `limit`/`offset` on matches, conversations, and messages, but there is no "load more" button or infinite scroll. |
| **Duplicate `_requireSelectedUser()` pattern** | Nearly every controller (`BrowseController`, `SafetyController`, `ConversationThreadController`, `MatchesController`, `ProfileController`) has an identical `_requireSelectedUser()` method. Should be extracted to a shared mixin or utility. |
| **No logging** | No debug logging or crash reporting infrastructure. |
| **No connectivity awareness** | The health banner checks backend status, but there is no general connectivity listener. |
| **`_formatDateTime` is duplicated** | The same date formatting function exists in both `conversations_screen.dart` (line 117) and `conversation_thread_screen.dart` (line 359). Should be in `lib/shared/formatting/`. |
| **Empty `shared/formatting/` and `shared/result/` directories** | The handoff recommended these directories but they were never populated. |

---

## What Should Be Done Next — Priority Order

### Immediate: fix broken things first

| # | Task | Files affected | Severity |
|---|------|---------------|----------|
| 1 | Fix `SelectedUserStore.readSelectedUser()` — remove the nested duplicate method | `lib/features/auth/selected_user_store.dart` | Critical |
| 2 | Fix `signed_in_shell_test.dart` — change Notifier override from async lambda to proper override | `test/features/home/signed_in_shell_test.dart` | High |
| 3 | Fix `safety_action_sheet_test.dart` — remove `const` from MaterialApp constructors | `test/features/safety/safety_action_sheet_test.dart` | High |
| 4 | Fix `widget_test.dart` — add missing `sharedPreferencesProvider` import | `test/widget_test.dart` | High |
| 5 | Fix deprecated `surfaceVariant` → `surfaceContainerHighest` | `lib/features/profile/profile_screen.dart` | Low |

### Short-term: polish existing features

| # | Task | Rationale |
|---|------|-----------|
| 6 | Extract `_formatDateTime` into `lib/shared/formatting/date_formatting.dart` | Eliminate duplication across two screens |
| 7 | Extract `_requireSelectedUser` into a shared provider utility | Eliminate copy-paste across 6+ controllers |
| 8 | Add undo button to browse | Backend already supports it, trivial to wire up |
| 9 | Add pagination UI for matches, conversations, messages | Backend supports limit/offset but no UI exposes it |

### Medium-term: next feature set

| # | Task | Rationale |
|---|------|-----------|
| 10 | Add swipe card UX to browse | Dating app should feel like a dating app, not a CRUD list |
| 11 | Add blocked users management screen | Safety feature, backend ready |
| 12 | Add notifications screen | Even a read-only list adds real value |
| 13 | Add stats and achievements screen | Read-only UI, backend ready |
| 14 | Introduce `go_router` | Declarative routing is more maintainable than imperative Navigator |

### Longer-term

| # | Task |
|---|------|
| 15 | Add verification flow UI |
| 16 | Add location search and resolve UI |
| 17 | Add standouts and match quality screens |
| 18 | Add `cached_network_image` for profile photos |
| 19 | Write integration tests for the full core loop |
| 20 | Add friend requests UI |
| 21 | Add graceful exit relationship action |

---

## File Inventory

### Source files (`lib/`)

```
lib/
  main.dart
  app/
    app.dart                         — root MaterialApp with theme
    app_config.dart                  — AppConfig with baseUrl, sharedSecret, timeouts
    env.dart                         — compile-time env vars (base URL, shared secret)
  api/
    api_client.dart                  — centralized ApiClient wrapping all endpoints
    api_endpoints.dart               — static endpoint path builder
    api_error.dart                   — ApiError with DioException mapping
    api_headers.dart                 — shared-secret and user-id header injection
  features/
    auth/
      dev_user_picker_screen.dart    — dev user selection screen
      selected_user_provider.dart    — Riverpod providers for user selection
      selected_user_store.dart       — SharedPreferences persistence (HAS BUG)
    browse/
      browse_screen.dart             — candidate browsing screen
      browse_provider.dart           — browse data and action controllers
    matches/
      matches_screen.dart            — matches list screen
      matches_provider.dart          — matches data controller
    chat/
      conversations_screen.dart      — conversation list screen
      conversations_provider.dart    — conversation data controller
      conversation_thread_screen.dart — chat thread screen with polling
      conversation_thread_provider.dart — thread data and send controller
    profile/
      profile_screen.dart            — profile view (self + other)
      profile_edit_screen.dart       — profile edit form
      profile_provider.dart          — profile data and update controller
    safety/
      safety_action_sheet.dart       — bottom sheet with block/report/unmatch
      safety_provider.dart           — safety actions controller
    settings/
      settings_screen.dart           — settings screen
      app_preferences_provider.dart  — theme mode provider and controller
      app_preferences_store.dart     — preferences persistence
    home/
      app_home_screen.dart           — routing between picker and shell
      signed_in_shell.dart           — bottom navigation shell
      backend_health_provider.dart   — health check provider
      backend_health_banner.dart     — health status banner widget
  models/
    app_preferences.dart
    browse_candidate.dart
    browse_response.dart
    conversation_summary.dart
    daily_pick.dart
    health_status.dart
    like_result.dart
    match_summary.dart
    matches_response.dart
    message_dto.dart
    profile_update_request.dart
    user_detail.dart
    user_summary.dart
  shared/
    widgets/
      app_async_state.dart           — reusable loading/empty/error states
    persistence/
      shared_preferences_provider.dart — Riverpod provider for SharedPreferences
  theme/
    app_theme.dart                   — Material 3 theme with seed color
```

### Test files (`test/`)

```
test/
  widget_test.dart                   — BROKEN (missing import)
  api/
    api_error_test.dart              — passing
    api_headers_test.dart            — passing
  app/
    app_test.dart                    — passing
  models/
    app_preferences_test.dart        — passing
    browse_response_test.dart        — passing
    conversation_summary_test.dart   — passing
    like_result_test.dart            — passing
    matches_response_test.dart       — passing
    message_dto_test.dart            — passing
    profile_update_request_test.dart — passing
    user_detail_test.dart            — passing
  features/
    auth/
      selected_user_store_test.dart  — FAILING (nested method bug)
    browse/
      browse_screen_test.dart        — passing
      browse_provider_test.dart      — passing
    chat/
      conversation_thread_screen_test.dart — passing
      conversation_thread_provider_test.dart — passing
    home/
      signed_in_shell_test.dart      — BROKEN (compilation error)
    matches/
      matches_screen_test.dart       — passing
      matches_provider_test.dart     — passing
    profile/
      profile_screen_test.dart       — passing
      profile_edit_screen_test.dart  — passing
      profile_provider_test.dart     — passing
    safety/
      safety_action_sheet_test.dart  — BROKEN (compilation error)
      safety_provider_test.dart      — passing
    settings/
      settings_screen_test.dart      — passing
      app_preferences_store_test.dart — passing
```
