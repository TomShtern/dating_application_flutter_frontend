# UI Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Status:** Completed ✅

**Verification refreshed on 2026-04-22:**
- ✅ `flutter analyze`
- ✅ `flutter test` → `00:41 +161: All tests passed!`
- ✅ `flutter test test/visual_inspection/screenshot_test.dart` → 17 screenshot checks passed
- ✅ Fresh visual review run captured as `run-0016`

**Goal:** Implement the expanded UI review in `docs/2026-04-21-ui-visual-review.md` by tightening shell chrome, normalizing copy and labels, improving action hierarchy, densifying sparse utility screens, and validating the results with tests plus a fresh visual review.

**Architecture:** Add a small shared UI foundation first: spacing tokens, user-facing formatting helpers, and reusable header/intro widgets. Migrate shell screens and detail/utility surfaces onto those primitives, then validate with focused widget/unit tests, `flutter analyze`, `flutter test`, and the visual inspection suite.

**Tech Stack:** Flutter 3.41, Dart 3.11, Material 3, Riverpod, flutter_test

---

## Files expected to change

### Foundation and shared primitives
- Modify: `lib/theme/app_theme.dart`
- Create: `lib/shared/formatting/display_text.dart`
- Modify: `lib/shared/formatting/date_formatting.dart`
- Create: `lib/shared/widgets/shell_hero.dart`
- Create: `lib/shared/widgets/section_intro_card.dart`
- Create: `test/shared/formatting/display_text_test.dart`
- Create: `test/shared/formatting/date_formatting_test.dart`

### Shell chrome and core tabs
- Modify: `lib/features/home/signed_in_shell.dart`
- Modify: `lib/features/auth/dev_user_picker_screen.dart`
- Modify: `lib/features/browse/browse_screen.dart`
- Modify: `lib/features/matches/matches_screen.dart`
- Modify: `lib/features/chat/conversations_screen.dart`
- Modify: `lib/features/profile/profile_screen.dart`
- Modify: `lib/features/settings/settings_screen.dart`
- Modify: `test/features/home/signed_in_shell_test.dart`
- Modify: `test/features/browse/browse_screen_test.dart`
- Modify: `test/features/matches/matches_screen_test.dart`
- Modify: `test/features/chat/conversations_screen_test.dart`
- Modify: `test/features/profile/profile_screen_test.dart`
- Modify: `test/features/settings/settings_screen_test.dart`

### Detail screens and person-first flows
- Modify: `lib/features/chat/conversation_thread_screen.dart`
- Modify: `lib/features/profile/profile_edit_screen.dart`
- Modify: `lib/features/location/location_completion_screen.dart`
- Modify: `lib/features/browse/standouts_screen.dart`
- Modify: `lib/features/browse/pending_likers_screen.dart`
- Modify: `test/features/chat/conversation_thread_screen_test.dart`
- Modify: `test/features/profile/profile_edit_screen_test.dart`

### Utility surfaces
- Modify: `lib/features/stats/stats_screen.dart`
- Modify: `lib/features/stats/achievements_screen.dart`
- Modify: `lib/features/verification/verification_screen.dart`
- Modify: `lib/features/safety/blocked_users_screen.dart`
- Modify: `lib/features/notifications/notifications_screen.dart`
- Modify: `test/features/stats/stats_screen_test.dart`
- Create: `test/features/notifications/notifications_screen_test.dart`
- Create: `test/features/verification/verification_screen_test.dart`

### Verification and reporting
- Modify: `docs/superpowers/plans/2026-04-21-ui-polish-implementation.md`
- Create: `docs/2026-04-21-ui-post-implementation-review.md`

---

### Task 1: Build the shared UI foundation

**Files:**
- Modify: `lib/theme/app_theme.dart`
- Create: `lib/shared/formatting/display_text.dart`
- Modify: `lib/shared/formatting/date_formatting.dart`
- Create: `lib/shared/widgets/shell_hero.dart`
- Create: `lib/shared/widgets/section_intro_card.dart`
- Create: `test/shared/formatting/display_text_test.dart`
- Create: `test/shared/formatting/date_formatting_test.dart`

- [x] ✅ Add focused failing tests for human-readable enum/copy mapping and relative timestamp formatting.
- [x] ✅ Implement reusable display helpers for profile/status labels, readable list copy, and friendlier timestamps.
- [x] ✅ Add spacing and density tokens to `app_theme.dart` and tighten shared button/icon/list defaults where appropriate.
- [x] ✅ Create a reusable `ShellHero` widget for shell/detail headers with compact and expanded density presets.
- [x] ✅ Create a reusable `SectionIntroCard` widget for sparse utility/detail surfaces.
- [x] ✅ Run the new formatting tests and fix any failures before moving on.

### Task 2: Tighten shell chrome and main entry surfaces

**Files:**
- Modify: `lib/features/home/signed_in_shell.dart`
- Modify: `lib/features/auth/dev_user_picker_screen.dart`
- Modify: `lib/features/browse/browse_screen.dart`
- Modify: `lib/features/matches/matches_screen.dart`
- Modify: `lib/features/chat/conversations_screen.dart`
- Modify: `lib/features/profile/profile_screen.dart`
- Modify: `lib/features/settings/settings_screen.dart`
- Modify: `test/features/home/signed_in_shell_test.dart`
- Modify: `test/features/browse/browse_screen_test.dart`
- Modify: `test/features/matches/matches_screen_test.dart`
- Modify: `test/features/chat/conversations_screen_test.dart`
- Modify: `test/features/profile/profile_screen_test.dart`
- Modify: `test/features/settings/settings_screen_test.dart`

- [x] ✅ Add or update failing widget tests for the most important shell-surface behavioral changes: friendlier shell copy, user-friendly profile labels, and preserved navigation interactions.
- [x] ✅ Reduce signed-in shell chrome height and simplify the redundant footer/session strip without breaking tab navigation.
- [x] ✅ Replace per-screen private hero cards with the shared `ShellHero` where it improves consistency.
- [x] ✅ Make Discover, Matches, Chats, Profile, and Settings more content-first by tightening vertical padding, reducing redundant pills, and clarifying CTA hierarchy.
- [x] ✅ Make the dev-user picker rows more cohesive and more obviously selectable.
- [x] ✅ Run the affected shell/widget tests and fix regressions before moving on.

### Task 3: Refine detail flows and person-first screens

**Files:**
- Modify: `lib/features/chat/conversation_thread_screen.dart`
- Modify: `lib/features/profile/profile_screen.dart`
- Modify: `lib/features/profile/profile_edit_screen.dart`
- Modify: `lib/features/location/location_completion_screen.dart`
- Modify: `lib/features/browse/standouts_screen.dart`
- Modify: `lib/features/browse/pending_likers_screen.dart`
- Modify: `test/features/chat/conversation_thread_screen_test.dart`
- Modify: `test/features/profile/profile_edit_screen_test.dart`

- [x] ✅ Add or update failing tests for conversation-thread copy/structure changes and profile-edit humanized input behavior.
- [x] ✅ Rework the conversation thread so it wastes less space, removes duplicate identity text, and clarifies the composer/refresh model.
- [x] ✅ Normalize other-user profile labels and reduce repetitive settings-row styling where possible.
- [x] ✅ Replace developer-facing profile-edit and location-completion copy with user-facing guidance and clearer controls.
- [x] ✅ Make Standouts and People-who-liked-you feel more intentional by improving intro framing, card action affordances, and supporting copy.
- [x] ✅ Run the affected detail/widget tests and fix regressions before moving on.

### Task 4: Densify the utility surfaces

**Files:**
- Modify: `lib/features/stats/stats_screen.dart`
- Modify: `lib/features/stats/achievements_screen.dart`
- Modify: `lib/features/verification/verification_screen.dart`
- Modify: `lib/features/safety/blocked_users_screen.dart`
- Modify: `lib/features/notifications/notifications_screen.dart`
- Modify: `test/features/stats/stats_screen_test.dart`
- Create: `test/features/notifications/notifications_screen_test.dart`
- Create: `test/features/verification/verification_screen_test.dart`

- [x] ✅ Add failing tests for utility-surface formatting changes that are easy to assert semantically, especially relative timestamps and user-facing verification copy.
- [x] ✅ Add stronger intro framing, denser layout structure, and richer value hierarchy to Stats and Achievements.
- [x] ✅ Turn Verification into a clearer guided flow with less developer-facing language and safer dev-only disclosure styling.
- [x] ✅ Improve Blocked Users and Notifications with denser layouts, more consistent trailing states, and clearer read/unread/action affordances.
- [x] ✅ Run the affected utility/widget tests and fix regressions before moving on.

### Task 5: Verify, document, and visually review the finished implementation

**Files:**
- Modify: `docs/superpowers/plans/2026-04-21-ui-polish-implementation.md`
- Create: `docs/2026-04-21-ui-post-implementation-review.md`

- [x] ✅ Format every changed Dart file.
- [x] ✅ Run `flutter analyze` and fix all analyzer errors introduced by the polish work.
- [x] ✅ Run `flutter test` and fix failing tests.
- [x] ✅ Run `flutter test test/visual_inspection/screenshot_test.dart` to generate a fresh visual run.
- [x] ✅ Review the new screenshots, compare them against the review goals, and write a new post-implementation report describing what improved, what still needs work, and the next refinements to consider.
- [x] ✅ Update this implementation plan so every completed item is marked with green checkmarks.

---

## Execution notes

- Start with the shared foundation so the rest of the screen edits can reuse it.
- Prefer semantic/user-facing assertions in widget tests over brittle layout-size assertions.
- Use the screenshot workflow as the main validation tool for density and hierarchy changes.
- Keep the backend contract untouched; this pass is UI/copy/state presentation only.
