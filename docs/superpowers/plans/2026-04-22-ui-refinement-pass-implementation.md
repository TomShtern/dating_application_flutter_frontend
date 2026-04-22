# UI Refinement Pass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Status:** Completed ✅

**Verification refreshed on 2026-04-22:**
- ✅ `flutter analyze`
- ✅ `flutter test` → `162 passed, 0 failed`
- ✅ `flutter test test/visual_inspection/screenshot_test.dart` → `18 passed, 0 failed`
- ✅ Fresh visual review run captured as `run-0020`

**Goal:** Remove the remaining top-heavy chrome, flatten over-nested utility layouts, reduce repeated metadata, tighten short-list states, and re-run the visual inspection workflow to verify the app feels more content-first and productized.

**Architecture:** Apply a compact-density pass across shared spacing/button tokens first, then simplify the highest-friction screens by removing redundant hero/intro layers and collapsing repeated metadata into fewer, stronger UI elements. Preserve the existing Material 3 visual language and backend contract; this is a presentation and interaction-density pass only.

**Tech Stack:** Flutter 3.41, Dart 3.11, Material 3, Riverpod, flutter_test

---

## Files expected to change

### Shared density and state surfaces
- Modify: `lib/theme/app_theme.dart`
- Modify: `lib/shared/widgets/app_async_state.dart`
- Modify: `lib/shared/widgets/shell_hero.dart`

### Shell and short-list screens
- Modify: `lib/features/browse/browse_screen.dart`
- Modify: `lib/features/matches/matches_screen.dart`
- Modify: `lib/features/chat/conversations_screen.dart`
- Modify: `lib/features/settings/settings_screen.dart`
- Modify: `lib/features/auth/dev_user_picker_screen.dart`
- Modify: `test/features/browse/browse_screen_test.dart`
- Modify: `test/features/matches/matches_screen_test.dart`
- Modify: `test/features/chat/conversations_screen_test.dart`
- Modify: `test/features/settings/settings_screen_test.dart`
- Modify: `test/features/auth/dev_user_picker_screen_test.dart`

### Detail and list-density screens
- Modify: `lib/features/chat/conversation_thread_screen.dart`
- Modify: `lib/features/browse/standouts_screen.dart`
- Modify: `lib/features/browse/pending_likers_screen.dart`
- Modify: `lib/features/safety/blocked_users_screen.dart`
- Modify: `test/features/chat/conversation_thread_screen_test.dart`
- Modify: `test/features/browse/standouts_screen_test.dart`
- Modify: `test/features/browse/pending_likers_screen_test.dart`
- Modify: `test/features/safety/blocked_users_screen_test.dart`

### Utility and form flows
- Modify: `lib/features/notifications/notifications_screen.dart`
- Modify: `lib/features/verification/verification_screen.dart`
- Modify: `lib/features/stats/stats_screen.dart`
- Modify: `lib/features/stats/achievements_screen.dart`
- Modify: `lib/features/location/location_completion_screen.dart`
- Modify: `lib/features/profile/profile_edit_screen.dart`
- Modify: `test/features/notifications/notifications_screen_test.dart`
- Modify: `test/features/verification/verification_screen_test.dart`
- Modify: `test/features/location/location_completion_screen_test.dart`
- Modify: `test/features/stats/stats_screen_test.dart`
- Modify: `test/features/stats/achievements_screen_test.dart`
- Modify: `test/features/profile/profile_edit_screen_test.dart`

### Documentation and visual verification
- Modify: `docs/2026-04-21-ui-post-implementation-review.md`
- Modify: `docs\superpowers\plans\2026-04-22-ui-refinement-pass-implementation.md`
- Create: `docs/2026-04-22-ui-refinement-pass-review.md`

---

### Task 1: Tighten the shared density system

**Files:**
- Modify: `lib/theme/app_theme.dart`
- Modify: `lib/shared/widgets/app_async_state.dart`
- Modify: `lib/shared/widgets/shell_hero.dart`

- [x] ✅ Add failing tests or tighten existing expectations for denser button, hero, and empty-state behavior where it is practical to assert semantically.
- [x] ✅ Reduce shared padding and spacing tokens enough to make utility screens less plush without harming touch targets.
- [x] ✅ Tighten compact hero padding so any remaining `ShellHero` usage consumes less vertical space.
- [x] ✅ Make empty/error states feel a little more intentional on tall screens without reintroducing oversized decorative framing.
- [x] ✅ Run the directly affected widget tests before moving on.

### Task 2: Make shell screens more content-first

**Files:**
- Modify: `lib/features/browse/browse_screen.dart`
- Modify: `lib/features/matches/matches_screen.dart`
- Modify: `lib/features/chat/conversations_screen.dart`
- Modify: `lib/features/settings/settings_screen.dart`
- Modify: `lib/features/auth/dev_user_picker_screen.dart`
- Modify: `test/features/browse/browse_screen_test.dart`
- Modify: `test/features/matches/matches_screen_test.dart`
- Modify: `test/features/chat/conversations_screen_test.dart`
- Modify: `test/features/settings/settings_screen_test.dart`
- Modify: `test/features/auth/dev_user_picker_screen_test.dart`

- [x] ✅ Update tests to reflect a more compact shell: fewer redundant hero layers, clearer single-card states, and flatter settings composition.
- [x] ✅ Reduce duplicated metadata and supporting chrome in `Discover` so the candidate card and actions dominate sooner.
- [x] ✅ Remove or substantially collapse unnecessary hero framing in `Matches` and `Chats`.
- [x] ✅ Flatten `Settings` quick links so the page feels like one settings surface instead of nested feature cards.
- [x] ✅ Tighten the dev-user picker so the current-user summary and selectable rows start faster and read more clearly.
- [x] ✅ Run the affected shell/widget tests before moving on.

### Task 3: Tighten detail flows and repeated-card metadata

**Files:**
- Modify: `lib/features/chat/conversation_thread_screen.dart`
- Modify: `lib/features/browse/standouts_screen.dart`
- Modify: `lib/features/browse/pending_likers_screen.dart`
- Modify: `lib/features/safety/blocked_users_screen.dart`
- Modify: `test/features/chat/conversation_thread_screen_test.dart`
- Modify: `test/features/browse/standouts_screen_test.dart`
- Modify: `test/features/browse/pending_likers_screen_test.dart`
- Modify: `test/features/safety/blocked_users_screen_test.dart`

- [x] ✅ Update tests for a tighter chat composer, more intentional short-thread composition, and denser list-card metadata.
- [x] ✅ Make the conversation thread feel less staged by shrinking the composer chrome and making sparse threads feel more inhabited.
- [x] ✅ Compress standout metadata so curation leads and scoring supports.
- [x] ✅ Move repeated pending-liker explanation up to the screen level and simplify each liker card.
- [x] ✅ Reduce blocked-user row repetition so the screen intro explains the consequence and rows focus on person + state + action.
- [x] ✅ Run the affected detail/widget tests before moving on.

### Task 4: Flatten utility flows and form-heavy screens

**Files:**
- Modify: `lib/features/notifications/notifications_screen.dart`
- Modify: `lib/features/verification/verification_screen.dart`
- Modify: `lib/features/stats/stats_screen.dart`
- Modify: `lib/features/stats/achievements_screen.dart`
- Modify: `lib/features/location/location_completion_screen.dart`
- Modify: `lib/features/profile/profile_edit_screen.dart`
- Modify: `test/features/notifications/notifications_screen_test.dart`
- Modify: `test/features/verification/verification_screen_test.dart`
- Modify: `test/features/location/location_completion_screen_test.dart`
- Modify: `test/features/stats/stats_screen_test.dart`
- Modify: `test/features/stats/achievements_screen_test.dart`
- Modify: `test/features/profile/profile_edit_screen_test.dart`

- [x] ✅ Update tests for flatter notification controls, a tighter verification flow, reduced redundant intros on stats/achievements, and denser edit/setup forms.
- [x] ✅ Collapse notifications into a quicker control + feed structure with fewer metadata chips per item.
- [x] ✅ Tighten verification so it reads as one guided task rather than several separate modules.
- [x] ✅ Remove redundant explanatory framing from stats and achievements while preserving clarity.
- [x] ✅ Shorten helper-copy and spacing overhead in location completion and profile edit.
- [x] ✅ Run the affected utility/widget tests before moving on.

### Task 5: Verify, visually inspect, fix any final issues, and document the result

**Files:**
- Modify: `docs\superpowers\plans\2026-04-22-ui-refinement-pass-implementation.md`
- Create: `docs/2026-04-22-ui-refinement-pass-review.md`

- [x] ✅ Format every changed Dart file.
- [x] ✅ Run `flutter analyze` and fix any analyzer issues.
- [x] ✅ Run the full `flutter test` suite and fix regressions.
- [x] ✅ Run `flutter test test/visual_inspection/screenshot_test.dart` to generate a fresh visual run.
- [x] ✅ Inspect the fresh screenshots, identify the last obvious polish misses, and apply follow-up fixes to `Matches`, `Chats`, and `Location completion`.
- [x] ✅ Re-run the relevant verification after that follow-up fix.
- [x] ✅ Write a new review report describing what improved, what still needs work, and what changed after the final screenshot pass.
- [x] ✅ Update this plan so every completed item is marked with green checkmarks.

---

## Execution notes

- Prefer removing redundant surface layers over inventing new decorative ones.
- Preserve touch targets and readability while tightening density.
- Use existing shared widgets and theme tokens rather than adding new bespoke patterns unless reuse is immediate.
- Keep the backend contract untouched; this pass is UI structure, copy placement, and interaction hierarchy only.
