# Run-0119 Immediate Flutter Visual And Shared-System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement only the Flutter-owned visual cleanup from `docs/design-critique-run-0119.md`: the immediate screen fixes and the shared visual-system fixes that do not require backend/API changes or new product features.

**Architecture:** Work foundation-first. Add or refine shared UI primitives for route context, photo fallbacks, group labels, action hierarchy, and date/copy formatting, then apply them screen-by-screen to the run-0119 visual defects that are safe to solve with the current Flutter code and current DTOs.

**Tech Stack:** Flutter 3.41, Dart 3.11, Material 3, Riverpod, Dio, shared_preferences, flutter_test

## Follow-up Status After Screenshot-Led Recheck

The original implementation pass was later treated as only partially complete. A stricter follow-up review rechecked the remaining high-priority misses directly against regenerated screenshots instead of trusting prior checkbox state.

Revalidated in focused follow-up runs:

- `shell_discover__run-0121.png`: flatter reason area, calmer placeholder treatment, and `See full profile` no longer crowding the sticky actions.
- `profile_other_user__run-0122.png`: a real dating action is visible in the first viewport.
- `stats__run-0123.png`: faux trend/spark visuals removed in favor of neutral detail affordances.
- `notifications__run-0124.png` and `notifications_dark__run-0124.png`: row actions simplified into one trailing-action slot.
- `standouts__run-0125.png`: rank/score treatment reduced from precise points to softer `Top pick` / `Pick #N` labels.

---

## Scope Boundaries

This plan is intentionally narrower than the critique.

### In scope

- Immediate Flutter-only visual fixes from `docs/design-critique-run-0119.md` section 1.
- Shared-system fixes from `docs/design-critique-run-0119.md` section 2.
- Existing screen layout, copy, button hierarchy, route affordances, shared placeholders, shared headings, and visual-review fixtures when needed.
- Updating existing tests only if current tests fail because the UI structure changes.
- Running `flutter analyze`, relevant existing widget tests, and the visual-review screenshot suite.

### Out of scope

- Backend/API/model contract changes.
- Adding last-message preview support to chats.
- Verifying Java/backend ownership of standout rank or score.
- Wiring real stats trend data.
- Adding metric windows/baselines that the backend does not already provide.
- Building notification settings, chat search, deep links, auth/onboarding, discovery filters, richer chat features, locked-achievement roadmap, location autocomplete, current-location support, premium, safety center, account/help/logout, or brand-presence work.
- Accessibility/RTL/localization/device-hardening audits beyond not breaking obvious tap targets and text fitting during the visual pass.
- Adding new widget/regression tests for UI polish. Use the visual-review workflow instead unless an existing test must be repaired.
- Changing `.env`, API headers, endpoint paths, DTO shape, provider ownership, or backend-owned business rules.

### Thin-client rules

- Do not invent compatibility reasons, recommendation explanations, chat previews, stats trends, moderation states, verification capabilities, notification routing, or hidden product logic in Dart.
- When current data is too thin, either simplify the visual presentation or leave a clearly bounded follow-up note in the final implementation report. Do not create fake data.
- Keep route/navigation behavior imperative as it is today. This plan does not introduce a router package.

---

## Source Inputs

- `docs/design-critique-run-0119.md`
- `docs/design-language.md`
- `docs/visual-review-workflow.md`
- Current screenshots in `visual_review/latest/`
- Current visual fixture sources:
  - `test/visual_inspection/screenshot_test.dart`
  - `test/visual_inspection/fixtures/visual_fixture_catalog.dart`
  - `test/visual_inspection/fixtures/visual_fixture_builders.dart`
  - `test/visual_inspection/fixtures/visual_scenarios.dart`

---

## Files Expected To Change

### Shared visual system

- Modify: `lib/theme/app_theme.dart`
- Modify: `lib/shared/formatting/date_formatting.dart`
- Modify: `lib/shared/formatting/display_text.dart`
- Modify: `lib/shared/widgets/user_avatar.dart`
- Modify: `lib/shared/widgets/person_media_thumbnail.dart`
- Modify: `lib/shared/widgets/person_photo_card.dart`
- Modify: `lib/shared/widgets/shell_hero.dart`
- Modify: `lib/shared/widgets/section_intro_card.dart`
- Create: `lib/shared/widgets/app_route_header.dart`
- Create: `lib/shared/widgets/app_group_label.dart`

### Primary shell and core dating surfaces

- Modify: `lib/features/auth/dev_user_picker_screen.dart`
- Modify: `lib/features/browse/browse_screen.dart`
- Modify: `lib/features/matches/matches_screen.dart`
- Modify: `lib/features/chat/conversations_screen.dart`
- Modify: `lib/features/profile/profile_screen.dart`
- Modify: `lib/features/settings/settings_screen.dart`

### Pushed and secondary surfaces

- Modify: `lib/features/chat/conversation_thread_screen.dart`
- Modify: `lib/features/browse/standouts_screen.dart`
- Modify: `lib/features/browse/pending_likers_screen.dart`
- Modify: `lib/features/profile/profile_edit_screen.dart`
- Modify: `lib/features/location/location_completion_screen.dart`
- Modify: `lib/features/stats/stats_screen.dart`
- Modify: `lib/features/stats/achievements_screen.dart`
- Modify: `lib/features/verification/verification_screen.dart`
- Modify: `lib/features/safety/blocked_users_screen.dart`
- Modify: `lib/features/notifications/notifications_screen.dart`

### Tests and visual review

- Modify only if needed: existing tests under `test/features/**` and `test/shared/widgets/**`
- Modify only if screenshots need fixture updates: `test/visual_inspection/**`

---

## Implementation Order

1. Shared-system pass.
2. Immediate Flutter-only visual pass on primary shell screens.
3. Immediate Flutter-only visual pass on pushed and secondary screens.
4. Verification and screenshot review.

Do not start screen-by-screen work before the shared route header, placeholder, group-label, and action-hierarchy decisions are available. Reusing those primitives is the point of this pass.

---

### Task 1: Baseline The Current Visual State

**Files:**
- Read: `docs/design-critique-run-0119.md`
- Read: `docs/design-language.md`
- Read: `visual_review/latest/manifest.json`
- Read: affected files listed in this plan

- [x] Inspect `visual_review/latest/index.html` or the PNGs named in the critique.
- [x] Confirm the visual suite still reports 19 expected screenshots in `visual_review/latest/manifest.json`.
- [x] Build a working checklist from this plan only. Do not add backend/data, future-feature, or hardening items from the critique.
- [x] Search the affected Dart files for existing local patterns that already solve route headers, placeholder media, group headings, button hierarchy, date formatting, and chip wrapping.
- [x] If an item from the critique already appears fixed in current code, mark it as "verify in screenshots" instead of reworking it.

Verification:

- [x] No file edits in this task.
- [ ] Record any already-fixed items in the implementation notes or final report.

---

### Task 2: Add Shared Route Context For Pushed Screens

**Files:**
- Create: `lib/shared/widgets/app_route_header.dart`
- Modify: `lib/features/chat/conversation_thread_screen.dart`
- Modify: `lib/features/browse/standouts_screen.dart`
- Modify: `lib/features/browse/pending_likers_screen.dart`
- Modify: `lib/features/profile/profile_edit_screen.dart`
- Modify: `lib/features/location/location_completion_screen.dart`
- Modify: `lib/features/stats/stats_screen.dart`
- Modify: `lib/features/stats/achievements_screen.dart`
- Modify: `lib/features/verification/verification_screen.dart`
- Modify: `lib/features/safety/blocked_users_screen.dart`
- Modify: `lib/features/notifications/notifications_screen.dart`

Intent:

- Give every pushed route a visible in-app back affordance.
- Keep headers compact. Do not turn slim detail screens into bulky app-bar screens.
- Preserve Android/system back behavior and existing `Navigator.pop` flows.

Implementation steps:

- [x] Create `AppRouteHeader` as a small reusable header with:
  - required `title`
  - optional `subtitle`
  - optional `trailing`
  - optional `onBack`, defaulting to `Navigator.maybePop(context)`
  - a minimum 48 px tap target for the back button
  - a compact layout that works at the visual-review width
- [x] Use `Icons.chevron_left_rounded` or `Icons.arrow_back_rounded` consistently.
- [x] Replace bespoke top back buttons where they exist and add the header where run-0119 showed no route affordance.
- [x] Keep `ConversationThreadScreen` slim: show the route affordance near the existing participant header without adding a large hero.
- [x] Keep `VerificationScreen` green CTA unchanged.
- [x] Do not add deep-link routing, origin restoration, new routes, or navigation packages.

Verification:

- [ ] Run existing screen tests for any screens whose widget hierarchy broke.
- [ ] Later visual review must show visible route affordances on conversation thread, standouts, pending likers, profile edit, location completion, stats, achievements, verification, blocked users, and notifications.

---

### Task 3: Define The Shared Photo Placeholder System

**Files:**
- Modify: `lib/shared/widgets/user_avatar.dart`
- Modify: `lib/shared/widgets/person_media_thumbnail.dart`
- Modify: `lib/shared/widgets/person_photo_card.dart`
- Modify as needed: `lib/features/browse/browse_screen.dart`
- Modify as needed: `lib/features/profile/profile_screen.dart`
- Modify as needed: `lib/features/profile/profile_edit_screen.dart`
- Modify as needed: `lib/features/browse/standouts_screen.dart`
- Modify as needed: `lib/features/auth/dev_user_picker_screen.dart`

Intent:

- Replace loud, muddy, inconsistent no-photo states with one calm placeholder recipe.
- Fix the largest photo plates first, then align smaller avatars.

Implementation steps:

- [x] Make the large media placeholder in `PersonMediaThumbnail` use a softer tinted surface instead of saturated gradient-heavy fallback.
- [x] Keep a high-contrast monogram or icon centered in the placeholder.
- [x] Keep "Photo pending" copy only where the surface is large enough and the copy helps; avoid repeating it in dense rows.
- [x] Align `UserAvatar` and `PersonPhotoCard` fallbacks with the same color and monogram logic where practical.
- [x] In Discover, make the "photo pending" treatment belong to the candidate photo plate instead of reading like a floating badge.
- [x] In other-user profile and profile edit photo areas, rely on the shared placeholder instead of feature-local duplicate treatments where practical.
- [x] Do not invent fake photo URLs, generated profile images, media states, or photo moderation states.

Verification:

- [ ] Run `flutter test test/shared/widgets/user_avatar_test.dart` if existing assertions are affected.
- [ ] Run relevant existing screen tests only if changed structure breaks them.
- [ ] Later visual review must show calmer no-photo states in Discover, Standouts, other-user profile, profile edit, and dev-user picker rows.

---

### Task 4: Add Shared Group Labels And Action Hierarchy

**Files:**
- Modify: `lib/theme/app_theme.dart`
- Create: `lib/shared/widgets/app_group_label.dart`
- Modify: `lib/shared/widgets/view_mode_toggle.dart`
- Modify: `lib/features/settings/settings_screen.dart`
- Modify: `lib/features/stats/stats_screen.dart`
- Modify: `lib/features/stats/achievements_screen.dart`
- Modify: `lib/features/notifications/notifications_screen.dart`
- Modify: `lib/features/profile/profile_screen.dart`
- Modify: `lib/features/matches/matches_screen.dart`
- Modify: `lib/features/browse/browse_screen.dart`
- Modify: `lib/features/profile/profile_edit_screen.dart`
- Modify: `lib/features/browse/standouts_screen.dart`

Intent:

- Make group headings and comparable actions read consistently without flattening every screen into the same layout.
- Fix accidental hierarchy differences, especially action pairs and toggle rows.

Implementation steps:

- [x] Create `AppGroupLabel` for labels between cards:
  - small accent mark or rule
  - compact title text
  - optional trailing widget
  - no outer card shell
- [x] Keep plain `Text` titles inside a card; do not replace every local title with `AppGroupLabel`.
- [x] Update Settings Quick access so its title reads as a group label, not as another navigation row.
- [x] Apply the same between-card group-label pattern to Stats, Achievements, Notifications, and Profile where the current screen has a true group boundary.
- [x] Make `ViewModeToggle` or local segmented controls maintain a visible unselected state at 412 px width.
- [x] Normalize action hierarchy:
  - primary action: filled or visually strongest
  - secondary action: outlined/tonal/text treatment with real button affordance
  - tertiary action: low-emphasis link/icon when the action is not primary
  - destructive action: clear but not alarmist unless irreversible
- [x] In Matches, make `Message` primary and demote `View profile`.
- [x] In Discover, make `Pass` and `Like` the same height and keep `Pass` visibly enabled.
- [x] In Notifications, choose one clear trailing-action pattern for mark-read vs row navigation.
- [x] Keep the Verification green CTA as an approved exception.

Verification:

- [ ] Run affected existing widget tests if they assert labels/buttons.
- [ ] Later visual review must show stronger All/New toggle contrast, clearer Matches action hierarchy, matched Discover action heights, and a clearer Settings Quick access heading.

---

### Task 5: Standardize Current-Year Dates And Ambiguous Copy

**Files:**
- Modify: `lib/shared/formatting/date_formatting.dart`
- Modify: `lib/shared/formatting/display_text.dart`
- Modify: `lib/features/matches/matches_screen.dart`
- Modify: `lib/features/chat/conversations_screen.dart`
- Modify: `lib/features/browse/pending_likers_screen.dart`
- Modify: `lib/features/browse/browse_screen.dart`
- Modify: `lib/features/settings/settings_screen.dart`
- Modify: `lib/features/safety/blocked_users_screen.dart`
- Modify: `lib/features/notifications/notifications_screen.dart`

Intent:

- Reduce repeated body text and unclear pills using current available data only.
- Keep backend/dev infrastructure language out of user-facing surfaces where possible.

Implementation steps:

- [x] Add or refine a date formatter that omits the year for dates in the current local year and keeps the year for older dates.
- [x] Use the formatter in conversation rows, notification rows, message day labels, and any visible current-year date text that currently feels noisy.
- [x] Rewrite Matches hero copy so `5 matches ready` and `No new matches yet` do not appear contradictory. Use a single signal such as `5 matches ready · 0 new this week` when both values are available.
- [x] Rename or replace `Profile first` in Pending likers with clearer copy that explains the user opens the profile before deciding.
- [x] Clarify `Daily pick live` only if the current wording reads like backend/system status in screenshots.
- [x] Reduce blocked-users row copy by moving shared consequence text to the intro and removing `Can unblock` where the `Unblock` button already explains the action.
- [x] For Chats, do not invent last-message previews. If repeated `N messages exchanged in this conversation` remains the only honest body text, either reduce its prominence or replace it with a neutral current-data summary that does not pretend to be a preview.

Verification:

- [ ] Run affected existing widget tests if they assert exact copy.
- [ ] Later visual review must show no mid-word Quick access subtitle truncation, less repeated blocked-users copy, clearer pending-liker next-step copy, and non-contradictory Matches hero text.

---

### Task 6: Primary Shell Screen Visual Pass

**Files:**
- Modify: `lib/features/auth/dev_user_picker_screen.dart`
- Modify: `lib/features/browse/browse_screen.dart`
- Modify: `lib/features/matches/matches_screen.dart`
- Modify: `lib/features/chat/conversations_screen.dart`
- Modify: `lib/features/profile/profile_screen.dart`
- Modify: `lib/features/settings/settings_screen.dart`

Intent:

- Apply the shared system to the six primary shell captures from run-0119.

Implementation steps:

- [x] Dev sign-in:
  - Rework development sign-in, backend health, and no-profile state into one clear developer-only card.
  - Keep the available profile list below it.
  - Align avatar/accent color treatment after the card restructure.
- [x] Discover:
  - Apply the shared large no-photo placeholder.
  - Make undo and refresh visually/semantically distinct, or keep only the action that is needed in the hero.
  - Remove card-in-card chrome from "Why this profile is shown"; keep the content as a lighter inline reason area.
  - Improve reason tags with simple consistent color/icon treatment without adding new logic.
  - Match `Pass` and `Like` heights.
  - Add a candidate stack/progress cue using only current list position/count data if it is already available in the provider state; otherwise use a subtle visual stack hint that does not claim a fake count.
  - Follow-up revalidated in `shell_discover__run-0121.png`.
- [x] Matches:
  - Make `Message` the primary action and `View profile` secondary.
  - Rewrite hero count/new-copy into one clear signal.
  - Strengthen the unselected All/New filter chip.
  - Treat the third-card cutoff only as density/spacing polish.
- [x] Chats:
  - Clarify avatar overlay and row chevron meaning.
  - Calm row colors if they do not fit the chat surface.
  - Do not create fake last-message preview content.
- [x] Profile:
  - Keep only one readiness display.
  - Move the Profile hero away from rose-heavy treatment toward lavender or sky blue while keeping warmth.
  - Make profile-detail mini-card tints more intentional or simplify them.
  - Confirm important profile actions remain discoverable.
  - Follow-up revalidated for other-user action visibility in `profile_other_user__run-0122.png`.
- [x] Settings:
  - Fix Quick access subtitle truncation with two-line subtitles or shorter copy.
  - Apply shared group label treatment to Quick access.
  - Fix the theme segmented control wrapping at the visual-review width by resizing, shortening labels, or restructuring the control.
  - Do not add new entry points for profile-related or notification-related surfaces in this pass.

Verification:

- [ ] Run affected existing widget tests only if needed after structure/copy changes.
- [x] Run `flutter analyze` after this phase if many shared imports changed.

---

### Task 7: Pushed And Secondary Screen Visual Pass

**Files:**
- Modify: `lib/features/chat/conversation_thread_screen.dart`
- Modify: `lib/features/browse/standouts_screen.dart`
- Modify: `lib/features/browse/pending_likers_screen.dart`
- Modify: `lib/features/profile/profile_edit_screen.dart`
- Modify: `lib/features/location/location_completion_screen.dart`
- Modify: `lib/features/stats/stats_screen.dart`
- Modify: `lib/features/stats/achievements_screen.dart`
- Modify: `lib/features/verification/verification_screen.dart`
- Modify: `lib/features/safety/blocked_users_screen.dart`
- Modify: `lib/features/notifications/notifications_screen.dart`

Intent:

- Apply route context and shared visual fixes to the secondary run-0119 captures without pulling in future product work.

Implementation steps:

- [x] Conversation thread:
  - Add the visible route affordance.
  - Keep the slim header.
  - Keep per-message timestamps.
- [x] Standouts:
  - Apply the shared photo placeholder.
  - Add route affordance.
  - Make tint/color rules feel explainable for top-ranked, normal, selected, and fallback states.
  - Do not verify or change backend ownership of `rank` and `score` in this pass.
  - Follow-up revalidated in `standouts__run-0125.png` after de-emphasizing point-like score precision.
- [x] Pending likers:
  - Add route affordance.
  - Make hero and row copy explain the profile-first flow.
  - Rename or replace `Profile first`.
- [x] Other-user profile:
  - Bring the primary action into the first viewport or use a floating/sticky action area if the existing structure supports it cleanly.
  - Let reason chips wrap cleanly or cap visible chips with a clear `+N more` affordance.
  - Treat duplicate placeholders through the shared placeholder system.
  - Follow-up revalidated in `profile_other_user__run-0122.png`.
- [x] Profile edit:
  - Add route affordance.
  - Fix gender/interested-in orphaned chip rows with a 2x2 grid, smaller chips, or a clearer option layout.
  - Rebalance identity chip row.
  - Do not add new editable backend fields.
  - Do not add new photo upload behavior.
- [x] Location completion:
  - Add route affordance.
  - Standardize Country, City, ZIP, and CTA treatment.
  - Do not add current-location or inline autocomplete.
- [x] Stats:
  - If sparkbars are not backed by real trend data, replace them with a non-data decorative treatment or remove the data-like shape.
  - Improve labels only where current data supports the meaning.
  - Do not invent trend windows or benchmarks.
  - Follow-up revalidated in `stats__run-0123.png`.
- [x] Achievements:
  - Reduce redundant completed-progress chips on already-unlocked cards.
  - Keep `Still building`.
  - Do not add locked/to-unlock roadmap.
- [x] Verification:
  - Add route affordance.
  - Keep green CTA unchanged.
  - Do not add resend timer, cooldown, or photo-verification path.
- [x] Blocked users:
  - Move shared explanation to intro.
  - Remove redundant `Can unblock` cue.
  - Make `Unblock` read as a real action while preserving confirmation.
- [x] Notifications:
  - Clarify check, chevron, and row-tap behavior with one consistent trailing action pattern unless two actions are unmistakably communicated.
  - Do not add notification settings.
  - Follow-up revalidated in `notifications__run-0124.png` and `notifications_dark__run-0124.png`.

Verification:

- [ ] Run affected existing widget tests only if needed after structure/copy changes.
- [x] Run `flutter analyze` after this phase.

---

### Task 8: Visual Review, Fixups, And Final Verification

**Files:**
- Modify only if needed: `test/visual_inspection/screenshot_test.dart`
- Modify only if needed: `test/visual_inspection/fixtures/visual_fixture_catalog.dart`
- Modify only if needed: `test/visual_inspection/fixtures/visual_fixture_builders.dart`
- Modify only if needed: `test/visual_inspection/fixtures/visual_scenarios.dart`
- Create only if useful: a short dated review note under `docs/`

Implementation steps:

- [x] Format changed Dart files.
- [x] Run `flutter analyze`.
- [x] Run the existing widget tests for screens that were materially changed, using the smallest meaningful set first.
- [x] Run `flutter test test/visual_inspection/screenshot_test.dart`.
- [ ] Open `visual_review/latest/index.html` and inspect all 19 captures.
- [ ] Confirm the requested visual outcomes:
  - developer sign-in is compact and developer-only
  - large no-photo placeholders are calm
  - route affordances are visible on pushed screens
  - group labels are consistent
  - primary/secondary actions read correctly
  - current-year dates and repeated copy are less noisy
  - no text truncates mid-word in Settings
  - no fake backend data or future product behavior was added
- Focused follow-up evidence is currently limited to Discover (`run-0121`), other-user profile (`run-0122`), Stats (`run-0123`), Notifications light/dark (`run-0124`), and Standouts (`run-0125`).
- [x] Apply focused fixups only for issues introduced by this plan or obvious misses from the requested pass.
- [x] Re-run the relevant verification after fixups.

Final report requirements:

- [x] List files changed.
- [x] List verification commands and results.
- [x] List any critique items intentionally left out because they require backend/data, future product, or hardening work.
- [x] Do not claim end-to-end product completeness.

---

## Implementation Notes For The Agent

- Prefer existing shared widgets and theme tokens over new feature-local patterns.
- Add a new shared widget only when at least two screens use it in this pass.
- Keep UI copy plain and user-facing. Developer-only backend status belongs only in developer-only surfaces.
- Do not add new tests for visual polish. Repair existing tests only if changed UI breaks them.
- Use visual screenshots as the main quality gate for this plan.
- Keep the plan focused. If work starts needing backend fields, new product decisions, or non-visual infrastructure, stop that item and report it as out of scope.
