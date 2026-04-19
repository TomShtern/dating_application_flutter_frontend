# Frontend Functional Surfaces Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the next functional frontend surfaces in the requested order: profile view, profile edit, settings, then safety actions.

**Architecture:** Extend the existing Riverpod + Dio structure with focused profile, preferences, and safety feature folders. Keep network behavior centralized in `lib/api/api_client.dart`, keep widgets declarative, and refresh dependent providers with `ref.invalidate(...)` after mutations.

**Tech Stack:** Flutter, Dart, Material 3, Riverpod, Dio, SharedPreferences, flutter_test

---

## File map

### New files
- `lib/models/user_detail.dart` — read-side profile DTO for `GET /api/users/{id}`.
- `lib/models/profile_update_request.dart` — write-side DTO for `PUT /api/users/{id}/profile`.
- `lib/models/app_preferences.dart` — local app settings DTO.
- `lib/features/profile/profile_provider.dart` — profile read/write providers and controller.
- `lib/features/profile/profile_screen.dart` — current-user and other-user profile view.
- `lib/features/profile/profile_edit_screen.dart` — profile edit form.
- `lib/features/settings/app_preferences_store.dart` — SharedPreferences persistence for settings.
- `lib/features/settings/app_preferences_provider.dart` — preferences providers and controller.
- `lib/features/settings/settings_screen.dart` — settings UI with switch-user and theme controls.
- `lib/features/safety/safety_provider.dart` — block/report/unmatch controller and blocked-users provider.
- `lib/features/safety/safety_action_sheet.dart` — reusable safety menu UI.
- `test/models/user_detail_test.dart` — user detail DTO parsing tests.
- `test/models/profile_update_request_test.dart` — profile update request serialization tests.
- `test/models/app_preferences_test.dart` — preferences serialization tests.
- `test/features/profile/profile_provider_test.dart` — profile provider/controller tests.
- `test/features/profile/profile_screen_test.dart` — profile screen widget tests.
- `test/features/profile/profile_edit_screen_test.dart` — profile edit widget tests.
- `test/features/settings/app_preferences_store_test.dart` — preferences persistence tests.
- `test/features/settings/settings_screen_test.dart` — settings UI tests.
- `test/features/safety/safety_provider_test.dart` — safety mutation tests.
- `test/features/safety/safety_action_sheet_test.dart` — safety sheet widget tests.

### Modified files
- `lib/api/api_client.dart` — add profile, profile-update, preferences-adjacent, and safety request methods.
- `lib/api/api_endpoints.dart` — add missing profile and safety endpoint helpers.
- `lib/app/app.dart` — read theme preference from provider.
- `lib/features/home/signed_in_shell.dart` — add Profile and Settings destinations or routing hooks.
- `lib/features/browse/browse_screen.dart` — add candidate profile navigation and safety entry point.
- `lib/features/matches/matches_screen.dart` — add profile navigation and safety entry point.
- `lib/features/chat/conversation_thread_screen.dart` — add profile/safety app-bar actions.
- `pubspec.yaml` — only update if a dependency is truly required for profile rendering.

---

### Task 1: Profile view foundation

**Files:**
- Create: `lib/models/user_detail.dart`
- Create: `lib/features/profile/profile_provider.dart`
- Create: `lib/features/profile/profile_screen.dart`
- Test: `test/models/user_detail_test.dart`
- Test: `test/features/profile/profile_provider_test.dart`
- Test: `test/features/profile/profile_screen_test.dart`
- Modify: `lib/api/api_client.dart`
- Modify: `lib/api/api_endpoints.dart`
- Modify: `lib/features/home/signed_in_shell.dart`
- Modify: `lib/features/browse/browse_screen.dart`
- Modify: `lib/features/matches/matches_screen.dart`
- Modify: `lib/features/chat/conversation_thread_screen.dart`

- [ ] **Step 1: Write failing DTO and provider tests**
  - Add `UserDetail.fromJson` coverage for `id`, `name`, `age`, `bio`, `gender`, `interestedIn`, `approximateLocation`, `maxDistanceKm`, `photoUrls`, and `state`.
  - Add provider test verifying `profileProvider` loads current-user detail and `otherUserProfileProvider(userId)` loads another user's detail through the API client.
  - Add widget test verifying the profile screen shows loading, profile content, and retry state.

- [ ] **Step 2: Run focused tests to verify they fail**
  - Run the new model and feature tests only.
  - Expected: compile or runtime failures because `UserDetail`, profile providers, and profile screen do not exist yet.

- [ ] **Step 3: Add minimal implementation**
  - Implement `UserDetail`.
  - Add `ApiClient.getUserDetail({required String userId})` using `ApiEndpoints.userDetail(userId)`.
  - Implement read-only profile providers.
  - Build `ProfileScreen` that renders full profile data using `AppAsyncState` and supports retry.
  - Add navigation hooks so current-user profile is reachable from the shell and other-user profiles are reachable from browse, matches, and chat.

- [ ] **Step 4: Run focused tests to verify they pass**
  - Re-run the DTO and profile tests.
  - Expected: all Task 1 tests pass.

### Task 2: Profile edit flow

**Files:**
- Create: `lib/models/profile_update_request.dart`
- Create: `lib/features/profile/profile_edit_screen.dart`
- Test: `test/models/profile_update_request_test.dart`
- Test: `test/features/profile/profile_edit_screen_test.dart`
- Modify: `lib/api/api_client.dart`
- Modify: `lib/api/api_endpoints.dart`
- Modify: `lib/features/profile/profile_provider.dart`
- Modify: `lib/features/profile/profile_screen.dart`

- [ ] **Step 1: Write failing edit tests**
  - Add request serialization coverage for the editable profile payload.
  - Add provider test verifying `updateProfile` calls the API client and invalidates current profile data.
  - Add widget test verifying the edit screen loads initial values, validates empty required fields, and saves successfully.

- [ ] **Step 2: Run focused tests to verify they fail**
  - Expected: failures because the edit request model, update API method, and edit screen do not exist yet.

- [ ] **Step 3: Add minimal implementation**
  - Add `ApiEndpoints.updateProfile(userId)`.
  - Add `ApiClient.updateProfile(...)`.
  - Implement `ProfileUpdateRequest` with `toJson()`.
  - Add edit controller method that invalidates current and visible profile providers after save.
  - Build a functional edit form using existing Material 3 input patterns with only fields that are documented and safe to send now.
  - Add entry from `ProfileScreen` when the viewed profile belongs to the selected user.

- [ ] **Step 4: Run focused tests to verify they pass**
  - Re-run edit-related model/provider/widget tests.
  - Expected: all Task 2 tests pass.

### Task 3: Settings and preferences

**Files:**
- Create: `lib/models/app_preferences.dart`
- Create: `lib/features/settings/app_preferences_store.dart`
- Create: `lib/features/settings/app_preferences_provider.dart`
- Create: `lib/features/settings/settings_screen.dart`
- Test: `test/models/app_preferences_test.dart`
- Test: `test/features/settings/app_preferences_store_test.dart`
- Test: `test/features/settings/settings_screen_test.dart`
- Modify: `lib/app/app.dart`
- Modify: `lib/features/home/signed_in_shell.dart`

- [ ] **Step 1: Write failing preferences tests**
  - Add model/store tests for local theme mode and other app-level preferences.
  - Add widget test verifying the settings screen renders the selected user, theme controls, and switch-user action.

- [ ] **Step 2: Run focused tests to verify they fail**
  - Expected: failures because preferences model/store/providers/settings screen do not exist yet.

- [ ] **Step 3: Add minimal implementation**
  - Implement local `AppPreferences` and persistence store using `SharedPreferences`.
  - Add providers that expose theme mode and settings actions.
  - Update `DatingApp` to read theme mode from Riverpod instead of hardcoding light theme.
  - Add `SettingsScreen` to the shell and consolidate switch-user behavior there.

- [ ] **Step 4: Run focused tests to verify they pass**
  - Re-run settings-related tests.
  - Expected: all Task 3 tests pass.

### Task 4: Safety actions

**Files:**
- Create: `lib/features/safety/safety_provider.dart`
- Create: `lib/features/safety/safety_action_sheet.dart`
- Test: `test/features/safety/safety_provider_test.dart`
- Test: `test/features/safety/safety_action_sheet_test.dart`
- Modify: `lib/api/api_client.dart`
- Modify: `lib/api/api_endpoints.dart`
- Modify: `lib/features/profile/profile_screen.dart`
- Modify: `lib/features/matches/matches_screen.dart`
- Modify: `lib/features/chat/conversation_thread_screen.dart`
- Modify: `lib/features/browse/browse_screen.dart`

- [ ] **Step 1: Write failing safety tests**
  - Add controller tests for block, unblock, report, and unmatch invalidation behavior.
  - Add widget test verifying the safety action sheet exposes the correct actions for another user and disables self-actions.

- [ ] **Step 2: Run focused tests to verify they fail**
  - Expected: failures because safety endpoints, controller, and action sheet do not exist yet.

- [ ] **Step 3: Add minimal implementation**
  - Add safety endpoint helpers to `ApiEndpoints`.
  - Add safety methods to `ApiClient` using centralized headers.
  - Implement `SafetyController` with targeted invalidation of browse, matches, conversations, and profile providers.
  - Add reusable safety action sheet and hook it into profile, matches, browse, and chat.

- [ ] **Step 4: Run focused tests to verify they pass**
  - Re-run safety-related tests.
  - Expected: all Task 4 tests pass.

### Task 5: Full verification

**Files:**
- Test: `test/models/**/*.dart`
- Test: `test/features/**/*.dart`
- Modify: only files needed to fix regressions found during verification

- [ ] **Step 1: Run the affected targeted tests again**
  - Run all newly added tests for profile, settings, and safety.

- [ ] **Step 2: Run the broader Flutter test suite**
  - Run the full `flutter test` suite.
  - Expected: existing browse, matches, chat, auth, api, and model tests remain green.

- [ ] **Step 3: Fix regressions if needed and re-run verification**
  - Only address failures introduced by this implementation.
