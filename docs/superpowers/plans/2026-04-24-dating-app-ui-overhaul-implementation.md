# Dating App UI Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Status:** Revised after accepted Stage A backend contract response on 2026-04-25. Ready for frontend foundation execution; Stage B backend-dependent integrations remain gated.

**Design input:** `docs/superpowers/specs/2026-04-23-dating-app-ui-overhaul-design.md`

**Goal:** Deliver the validated end-to-end UI overhaul for the Flutter dating app across theme, shell, shared components, people-first surfaces, utility flows, and verification—without lowering the design bar when the current backend contract is too thin.

**Architecture:** Execute foundation-first. First replace the lavender-heavy theme and redundant shell chrome, then add a shared UI kit for overflow menus, developer-only callouts, photo-backed person cards, compact context strips, and detail bottom sheets. After that, redesign the core dating surfaces (`Discover`, `Matches`, `Chats`, profiles), rebuild the most broken utility surface (`Notifications`), finish the remaining forms/utilities, and close with screenshot-driven verification. Keep imperative navigation, Riverpod orchestration, centralized API/header logic, and thin-client boundaries intact.

**Tech Stack:** Flutter 3.41, Dart 3.11, Material 3, Riverpod, Dio, shared_preferences, flutter_test

---

## Validation notes

- The design brief was re-read and validated against the live codebase on 2026-04-24.
- The backend Stage A contract response was received in `docs/frontend-ui-overhaul-contract-response-2026-04-25.md` on 2026-04-25 and is now the contract checkpoint for execution.
- `matchId == conversationId` is confirmed by backend as live; the frontend may use `matchId` anywhere a conversation id is required.
- `GET /api/users/{id}/match-quality/{matchId}` is confirmed live by backend, but is **not currently wired through the live frontend API layer**.
- `LocationCountry.flagEmoji` already exists in the current models and should be used in the UI.
- `BrowseCandidate`, `MatchSummary`, `PendingLiker`, `DailyPick`, and the current stats payload are all thinner than the desired UI.
- Missing endpoint or DTO support is **not** a reason to weaken the redesign. When the current contract is insufficient, this plan calls it out explicitly as backend work.

## Stage A contract checkpoint

Backend Stage A is accepted. Use these gates during frontend execution:

| Area | Backend status | Frontend action now |
|------|----------------|---------------------|
| Match-to-conversation identity | Exists now | Treat `matchId` as the conversation id and verify chat-opening paths. |
| Match quality | Exists now | Wire `GET /api/users/{id}/match-quality/{matchId}` and build `Why we match` against the real response shape. |
| Person summary media/context | Will add, target 2026-05-01 | Build layout/fallbacks now; do not depend on `primaryPhotoUrl`, `photoUrls`, `approximateLocation`, or `summaryLine` until Stage B lands. |
| Profile edit snapshot | Will add, target 2026-05-01 | Rework form layout now; do not wire full edit-prefill to `GET /profile-edit-snapshot` until Stage B lands. |
| Notification schema stabilization | Will add, target 2026-05-01 | Rebuild notification row shell now; do not add deep links or quick actions until the stabilized data keys land. |
| Presentation context | Will add, target 2026-05-08 | Prepare bottom-sheet UI boundaries now; do not show `Why this profile is shown` content until Stage B lands. |
| Stats and achievements richer semantics | P1 follow-up | Improve current layouts conservatively; do not invent grouped stat meaning or achievement detail semantics. |

### Current execution order

Start with backend-independent foundation work:

1. Task 2 — visual foundation and shared UI kit
2. Task 3 — shell cleanup, overflow menus, and developer-only framing
3. Task 1 subset — wire only the live backend contracts: match-quality and match/conversation identity tests
4. Tasks 4 through 9 — land layout shells and current-contract polish, leaving Stage B-dependent portions explicitly blocked
5. Stage B integration pass — after backend confirms the 2026-05-01 and 2026-05-08 contracts, wire enriched DTOs/screens
6. Task 10 — full visual/test verification and review report

## Scope matrix

| Surface             | Work type                       | Backend/API dependency                                  | Primary verification                                                         |
|---------------------|---------------------------------|---------------------------------------------------------|------------------------------------------------------------------------------|
| Dev-user picker     | polish + developer-only framing | none                                                    | `test/features/auth/dev_user_picker_screen_test.dart`, visual review         |
| Signed-in shell     | shell cleanup                   | none                                                    | create `test/features/home/signed_in_shell_test.dart`, visual review         |
| Discover            | major redesign                  | layout can start now; richer browse/daily-pick summaries target 2026-05-01, presentation context targets 2026-05-08 | `test/features/browse/browse_screen_test.dart`, visual review                |
| Matches             | major redesign                  | match-quality exists now; richer match preview data targets 2026-05-01 | `test/features/matches/matches_screen_test.dart`, visual review              |
| Chats               | medium redesign                 | none                                                    | `test/features/chat/conversations_screen_test.dart`, visual review           |
| Self profile        | medium redesign                 | none                                                    | `test/features/profile/profile_screen_test.dart`, visual review              |
| Other-user profile  | medium redesign                 | presentation-context targets 2026-05-08; hide is deferred | `test/features/profile/profile_screen_test.dart`, visual review              |
| Profile edit        | medium redesign                 | layout can start now; full edit snapshot targets 2026-05-01 | `test/features/profile/profile_edit_screen_test.dart`, visual review         |
| Settings            | medium cleanup                  | none                                                    | `test/features/settings/settings_screen_test.dart`, visual review            |
| Standouts           | medium redesign                 | richer standout preview data                            | `test/features/browse/standouts_screen_test.dart`, visual review             |
| Pending likers      | medium redesign                 | richer liker preview data                               | `test/features/browse/pending_likers_screen_test.dart`, visual review        |
| Notifications       | rebuild                         | row shell can start now; stabilized routing keys target 2026-05-01 | `test/features/notifications/notifications_screen_test.dart`, visual review  |
| Stats               | medium redesign                 | current endpoint usable; grouped/typed semantics are P1 follow-up | `test/features/stats/stats_screen_test.dart`, visual review                  |
| Achievements        | medium redesign                 | current endpoint usable; richer canonical semantics are P1 follow-up | `test/features/stats/achievements_screen_test.dart`, visual review           |
| Verification        | medium redesign                 | current start/confirm contract only; resend/cooldown is deferred | `test/features/verification/verification_screen_test.dart`, visual review    |
| Location completion | polish                          | existing country/city/resolve endpoints are sufficient  | `test/features/location/location_completion_screen_test.dart`, visual review |
| Conversation thread | low-risk polish                 | none                                                    | `test/features/chat/conversation_thread_screen_test.dart`, visual review     |
| Blocked users       | low-risk polish                 | optional unblock confirmation metadata not required     | `test/features/safety/blocked_users_screen_test.dart`, visual review         |

## Backend/API contract work required to preserve quality

These items should be treated as **quality-preserving backend work**, not optional nice-to-haves. The Stage A response has clarified what is live and what must wait for backend Stage B.

| Priority | Needed for | Stage A status | Frontend execution rule |
|----------|------------|----------------|-------------------------|
| P0 | Correct `Message now` and chat-thread routing | Exists now: `matchId == conversationId` | Verify current flows and do not wait for a new conversation id field. |
| P0 | `Why we match` bottom sheet on `Matches` | Exists now: `GET /api/users/{id}/match-quality/{matchId}` | Wire API/model/tests now against the Stage A response shape. |
| P0 | Photo-backed person cards in `Discover`, `Matches`, `Pending likers`, `Standouts`, and compact `Daily pick` | Will add by 2026-05-01 | Build card layout and no-photo fallbacks now; wire additive fields only after Stage B confirmation. |
| P0 | `Why this profile is shown` on `Discover` and other-user profile | Will add by 2026-05-08 | Build the sheet boundary now; keep content blocked until endpoint lands. |
| P0 | Complete profile-edit prefilling | Will add by 2026-05-01 | Redesign form layout now; wire snapshot endpoint only after Stage B confirmation. |
| P0 | Notification deep links and quick actions | Will add by 2026-05-01 | Rebuild inbox shell now; keep routing/quick actions blocked until stabilized keys land. |
| P1 | Stats grouping + stat detail sheets | Follow-up contract needed | Improve current presentation conservatively; do not infer stat meaning. |
| P1 | Achievement drill-downs that feel meaningful | Follow-up contract needed | Improve current presentation conservatively; do not infer achievement semantics. |
| P1 | Persistent `Hide` action on other-user profiles | Deferred | Do not ship persistent hide. If UI includes `Hide`, label it as deferred or omit it. |
| P2 | Verification resend/cooldown UX | Deferred | Do not add resend/cooldown UX yet. |

### Backend Stage B order

1. By 2026-05-01: richer person-summary/photo payloads for browse, matches, pending likers, standouts, and daily pick.
2. By 2026-05-01: `GET /api/users/{id}/profile-edit-snapshot`.
3. By 2026-05-01: stabilized notification type/data schema.
4. By 2026-05-08: `GET /api/users/{viewerId}/presentation-context/{targetId}`.
5. Later P1/P2: grouped/typed stats, richer achievements, conversation enrichment, persistent hide, verification resend/cooldown, dev-only cleanup.

## Files expected to change

### Foundation and shared UI system
- Modify: `lib/theme/app_theme.dart`
- Modify: `lib/shared/widgets/shell_hero.dart`
- Modify: `lib/shared/widgets/section_intro_card.dart`
- Modify: `lib/shared/widgets/app_async_state.dart`
- Modify: `lib/shared/widgets/user_avatar.dart`
- Create: `lib/shared/widgets/app_overflow_menu_button.dart`
- Create: `lib/shared/widgets/compact_context_strip.dart`
- Create: `lib/shared/widgets/compact_summary_header.dart`
- Create: `lib/shared/widgets/developer_only_callout_card.dart`
- Create: `lib/shared/widgets/person_photo_card.dart`
- Create: `lib/shared/widgets/compatibility_meter.dart`
- Create: `lib/shared/widgets/highlight_tag_row.dart`
- Create: `lib/shared/widgets/view_mode_toggle.dart`
- Create: `test/shared/widgets/app_overflow_menu_button_test.dart`
- Create: `test/shared/widgets/compact_context_strip_test.dart`
- Create: `test/shared/widgets/developer_only_callout_card_test.dart`
- Create: `test/shared/widgets/person_photo_card_test.dart`
- Create: `test/shared/widgets/compatibility_meter_test.dart`
- Create: `test/shared/widgets/view_mode_toggle_test.dart`

### Shell, menus, and developer-only framing
- Modify: `lib/features/home/signed_in_shell.dart`
- Modify: `lib/features/safety/safety_action_sheet.dart`
- Modify: `lib/features/settings/settings_screen.dart`
- Modify: `lib/features/auth/dev_user_picker_screen.dart`
- Modify: `lib/features/browse/browse_screen.dart`
- Modify: `lib/features/verification/verification_screen.dart`
- Create: `test/features/home/signed_in_shell_test.dart`
- Modify: `test/features/settings/settings_screen_test.dart`
- Modify: `test/features/auth/dev_user_picker_screen_test.dart`
- Modify: `test/features/browse/browse_screen_test.dart`
- Modify: `test/features/chat/conversation_thread_screen_test.dart`
- Modify: `test/features/profile/profile_screen_test.dart`
- Modify: `test/features/matches/matches_screen_test.dart`

### API layer and models (conditional on backend additions)
- Modify: `lib/api/api_endpoints.dart`
- Modify: `lib/api/api_client.dart`
- Modify: `test/api/api_client_test.dart`
- Modify: `lib/models/browse_candidate.dart`
- Modify: `lib/models/daily_pick.dart`
- Modify: `lib/models/match_summary.dart`
- Modify: `lib/models/pending_liker.dart`
- Modify: `lib/models/standout.dart`
- Modify: `lib/models/user_stats.dart`
- Modify: `lib/models/achievement_summary.dart`
- Modify: `lib/models/notification_item.dart`
- Create: `lib/models/match_quality.dart`
- Create: `lib/models/profile_presentation_context.dart`
- Create: `lib/models/profile_edit_snapshot.dart`
- Create: `test/models/match_quality_test.dart`
- Create: `test/models/profile_presentation_context_test.dart`
- Create: `test/models/profile_edit_snapshot_test.dart`
- Modify: `test/models/browse_response_test.dart`
- Modify: `test/models/standout_test.dart`
- Modify: `test/models/notification_item_test.dart`

### Core dating surfaces
- Modify: `lib/features/browse/browse_screen.dart`
- Modify: `lib/features/matches/matches_screen.dart`
- Modify: `lib/features/chat/conversations_screen.dart`
- Modify: `lib/features/profile/profile_screen.dart`
- Modify: `lib/features/profile/profile_edit_screen.dart`
- Create: `lib/features/matches/match_factors_sheet.dart`
- Create: `lib/features/profile/profile_presentation_sheet.dart`
- Create: `lib/features/browse/daily_pick_summary_tile.dart`
- Modify: `test/features/browse/browse_screen_test.dart`
- Modify: `test/features/matches/matches_screen_test.dart`
- Modify: `test/features/chat/conversations_screen_test.dart`
- Modify: `test/features/profile/profile_screen_test.dart`
- Modify: `test/features/profile/profile_edit_screen_test.dart`

### Secondary product surfaces
- Modify: `lib/features/browse/standouts_screen.dart`
- Modify: `lib/features/browse/pending_likers_screen.dart`
- Modify: `lib/features/notifications/notifications_screen.dart`
- Modify: `lib/features/stats/stats_screen.dart`
- Modify: `lib/features/stats/achievements_screen.dart`
- Modify: `lib/features/location/location_completion_screen.dart`
- Modify: `lib/features/chat/conversation_thread_screen.dart`
- Modify: `lib/features/safety/blocked_users_screen.dart`
- Create: `lib/features/stats/stat_detail_sheet.dart`
- Create: `lib/features/stats/achievement_detail_sheet.dart`
- Modify: `test/features/browse/standouts_screen_test.dart`
- Modify: `test/features/browse/pending_likers_screen_test.dart`
- Modify: `test/features/notifications/notifications_screen_test.dart`
- Modify: `test/features/stats/stats_screen_test.dart`
- Modify: `test/features/stats/achievements_screen_test.dart`
- Modify: `test/features/location/location_completion_screen_test.dart`
- Modify: `test/features/chat/conversation_thread_screen_test.dart`
- Modify: `test/features/safety/blocked_users_screen_test.dart`

### Visual review and documentation
- Modify: `test/visual_inspection/screenshot_test.dart`
- Modify: `test/visual_inspection/fixtures/visual_fixture_catalog.dart`
- Modify: `test/visual_inspection/fixtures/visual_fixture_builders.dart`
- Modify: `test/visual_inspection/fixtures/visual_scenarios.dart`
- Create: `docs/2026-04-24-ui-overhaul-review.md`
- Modify: `docs/superpowers/plans/2026-04-24-dating-app-ui-overhaul-implementation.md`

---

### Task 1: Apply Stage A backend decisions and wire only live contracts

**Files:**
- Modify: `lib/api/api_endpoints.dart`
- Modify: `lib/api/api_client.dart`
- Modify: `test/api/api_client_test.dart`
- Create: `lib/models/match_quality.dart`
- Create: `test/models/match_quality_test.dart`

- [ ] Record the Stage A decision in code/tests where behavior depends on it: `matchId` is the valid conversation id.
- [ ] Add the `ApiEndpoints` builder and `ApiClient` method for the live `GET /api/users/{id}/match-quality/{matchId}` endpoint.
- [ ] Add `MatchQuality` parsing for the actual Stage A response fields: `matchId`, `perspectiveUserId`, `otherUserId`, `compatibilityScore`, `compatibilityLabel`, `starDisplay`, `paceSyncLevel`, `distanceKm`, `ageDifference`, and `highlights`.
- [ ] Add model/API tests for match-quality and any match-to-chat identity behavior that is not already covered.
- [ ] Do **not** wire `presentation-context`, `profile-edit-snapshot`, person-summary enrichment, or notification deep links in this task. Those wait for backend Stage B confirmation.
- [ ] Run: `flutter test test/api/api_client_test.dart test/models/match_quality_test.dart`

### Task 1B: Stage B contract integration pass, only after backend confirms implementation

**Files:**
- Modify: `lib/api/api_endpoints.dart`
- Modify: `lib/api/api_client.dart`
- Modify: `test/api/api_client_test.dart`
- Modify: `lib/models/browse_candidate.dart`
- Modify: `lib/models/daily_pick.dart`
- Modify: `lib/models/match_summary.dart`
- Modify: `lib/models/pending_liker.dart`
- Modify: `lib/models/standout.dart`
- Modify: `lib/models/notification_item.dart`
- Create: `lib/models/profile_presentation_context.dart`
- Create: `lib/models/profile_edit_snapshot.dart`
- Create: `test/models/profile_presentation_context_test.dart`
- Create: `test/models/profile_edit_snapshot_test.dart`
- Modify: `test/models/browse_response_test.dart`
- Modify: `test/models/standout_test.dart`
- Modify: `test/models/notification_item_test.dart`

- [ ] After backend confirms the 2026-05-01 contracts, extend summary DTOs with `primaryPhotoUrl`, `photoUrls`, `approximateLocation`, and `summaryLine`.
- [ ] After backend confirms the 2026-05-01 contract, add `profile-edit-snapshot` endpoint/model wiring.
- [ ] After backend confirms the 2026-05-01 contract, update `NotificationItem` tests for the stabilized type/data registry; do not deep-link unknown types.
- [ ] After backend confirms the 2026-05-08 contract, add `presentation-context` endpoint/model wiring.
- [ ] Keep any P1 stats/achievements/conversation/hide/verification additions out of this pass unless the manager explicitly promotes them.
- [ ] Run the expanded API/model tests after each confirmed backend contract is wired.

### Task 2: Rebuild the visual foundation and shared UI kit

**Files:**
- Modify: `lib/theme/app_theme.dart`
- Modify: `lib/shared/widgets/shell_hero.dart`
- Modify: `lib/shared/widgets/section_intro_card.dart`
- Modify: `lib/shared/widgets/app_async_state.dart`
- Modify: `lib/shared/widgets/user_avatar.dart`
- Create: `lib/shared/widgets/app_overflow_menu_button.dart`
- Create: `lib/shared/widgets/compact_context_strip.dart`
- Create: `lib/shared/widgets/compact_summary_header.dart`
- Create: `lib/shared/widgets/developer_only_callout_card.dart`
- Create: `lib/shared/widgets/person_photo_card.dart`
- Create: `lib/shared/widgets/compatibility_meter.dart`
- Create: `lib/shared/widgets/highlight_tag_row.dart`
- Create: `lib/shared/widgets/view_mode_toggle.dart`
- Create: `test/shared/widgets/app_overflow_menu_button_test.dart`
- Create: `test/shared/widgets/compact_context_strip_test.dart`
- Create: `test/shared/widgets/developer_only_callout_card_test.dart`
- Create: `test/shared/widgets/person_photo_card_test.dart`
- Create: `test/shared/widgets/compatibility_meter_test.dart`
- Create: `test/shared/widgets/view_mode_toggle_test.dart`

- [ ] Replace the lavender-heavy theme with the graphite + delicate silver + ink-blue system in both `AppTheme.light()` and `AppTheme.dark()`.
- [ ] Reduce excessive gradients, heavy shadows, and bulky radii so cards feel premium and adult rather than soft-toy-like.
- [ ] Refine `ShellHero`, `SectionIntroCard`, and `AppAsyncState` so they remain part of the design system but are less vertically expensive and less mandatory-looking.
- [ ] Add the shared UI building blocks needed across the redesign: overflow menu, developer-only callout, compact context strip, compact summary header, photo-backed person card, compatibility meter, highlight tag row, and list/grid view toggle.
- [ ] Improve no-photo fallbacks so they are more intentional than a repeated monogram blob.
- [ ] Add shared-widget tests before the feature screens start depending on the new primitives.
- [ ] Run: `flutter test test/shared/widgets test/shared/media/media_url_test.dart`

### Task 3: Remove redundant shell chrome and standardize developer-only framing

**Files:**
- Modify: `lib/features/home/signed_in_shell.dart`
- Modify: `lib/features/safety/safety_action_sheet.dart`
- Modify: `lib/features/settings/settings_screen.dart`
- Modify: `lib/features/auth/dev_user_picker_screen.dart`
- Modify: `lib/features/browse/browse_screen.dart`
- Modify: `lib/features/verification/verification_screen.dart`
- Create: `test/features/home/signed_in_shell_test.dart`
- Modify: `test/features/settings/settings_screen_test.dart`
- Modify: `test/features/auth/dev_user_picker_screen_test.dart`
- Modify: `test/features/browse/browse_screen_test.dart`
- Modify: `test/features/chat/conversation_thread_screen_test.dart`
- Modify: `test/features/profile/profile_screen_test.dart`
- Modify: `test/features/matches/matches_screen_test.dart`

- [ ] Remove the redundant summary strip above the bottom `NavigationBar` in `SignedInShell` so the nav bar is the only persistent bottom chrome.
- [ ] Replace the ambiguous shield entry affordance with one reusable kebab overflow-menu pattern in `safety_action_sheet.dart` and migrate all affected screens to it.
- [ ] Standardize one `Developer only` surface treatment and apply it consistently to the dev-user picker, settings session controls, browse developer/system panel, and verification debug-code area.
- [ ] Ensure the new developer framing reads as temporary/internal tooling, not as a normal consumer feature.
- [ ] Add a dedicated shell test that proves the duplicate strip is gone and the `NavigationBar` remains usable.
- [ ] Run: `flutter test test/features/home/signed_in_shell_test.dart test/features/settings/settings_screen_test.dart test/features/auth/dev_user_picker_screen_test.dart`

### Task 4: Redesign `Discover` around one dominant candidate surface

**Files:**
- Modify: `lib/features/browse/browse_screen.dart`
- Create: `lib/features/browse/daily_pick_summary_tile.dart`
- Modify: `test/features/browse/browse_screen_test.dart`
- Modify: `test/visual_inspection/fixtures/visual_fixture_catalog.dart`
- Modify: `test/visual_inspection/fixtures/visual_scenarios.dart`

- [ ] Remove the bulky top hero/instruction banner and replace it with a compact context strip.
- [ ] Collapse daily pick into a compact summary tile near the top, with a clear tap path into fuller detail.
- [ ] Make the current candidate the dominant viewport surface and keep pass/like thumb-friendly in a persistent bottom action bar.
- [ ] Use photo-backed candidate cards whenever the payload supports it, and fall back gracefully when it does not.
- [ ] Add concise, server-driven reasons/chips plus a compact compatibility meter only when those signals are truly provided by the backend.
- [ ] Keep swipe as a first-class interaction and demote the full-profile affordance so it no longer competes with the core decision loop.
- [ ] Before backend Stage B, land the layout shell without fake reasons and use intentional no-photo/current-contract fallbacks.
- [ ] After backend Stage B, wire 2026-05-01 person-summary fields and 2026-05-08 presentation-context data.
- [ ] Run: `flutter test test/features/browse/browse_screen_test.dart`

### Task 5: Redesign `Matches` and `Chats` as compact, people-first lists

**Files:**
- Modify: `lib/features/matches/matches_screen.dart`
- Modify: `lib/features/chat/conversations_screen.dart`
- Modify: `lib/features/safety/safety_action_sheet.dart`
- Create: `lib/features/matches/match_factors_sheet.dart`
- Modify: `test/features/matches/matches_screen_test.dart`
- Modify: `test/features/chat/conversations_screen_test.dart`
- Modify: `test/features/chat/conversation_thread_screen_test.dart`

- [ ] Redesign match cards as compact, image-forward cards that prioritize the person, the next action, and the reasons the match matters.
- [ ] Keep `Message now` primary and add a clearly labeled `Why we match` trigger that opens a bottom sheet.
- [ ] Wire the match factors sheet to the live backend match-quality endpoint from Task 1; do not infer compatibility from unrelated fields.
- [ ] Use `matchId` as the conversation id when opening chat, per the accepted Stage A backend contract.
- [ ] Make conversation rows denser, whole-row tappable, and more socially legible than the current productivity-inbox feel.
- [ ] Add overflow menus to both match cards and conversation rows, and remove any remaining shield-style ambiguity.
- [ ] Normalize how recency, unread/new state, and secondary actions are displayed across these two list surfaces.
- [ ] Run: `flutter test test/features/matches/matches_screen_test.dart test/features/chat/conversations_screen_test.dart test/features/chat/conversation_thread_screen_test.dart`

### Task 6: Redesign self profile, other-user profile, and profile edit as one coherent profile system

**Files:**
- Modify: `lib/features/profile/profile_screen.dart`
- Modify: `lib/features/profile/profile_edit_screen.dart`
- Create: `lib/features/profile/profile_presentation_sheet.dart`
- Modify: `test/features/profile/profile_screen_test.dart`
- Modify: `test/features/profile/profile_edit_screen_test.dart`
- Modify: `test/features/location/location_completion_screen_test.dart`

- [ ] Tighten the self-profile hero so identity, compact state/location metadata, and a small readiness indicator are visible above the fold without explanatory clutter.
- [ ] Remove the over-promotion of tiny facts into separate full-width cards.
- [ ] Redesign the other-user profile hero to surface `Profile snapshot`, compact metadata, photos earlier, and a top-right overflow menu.
- [ ] Prepare the `Why this profile is shown` sheet boundary, but only show server-driven content after the 2026-05-08 presentation-context endpoint lands.
- [ ] Do not add persistent `Hide`; backend Stage A deferred hide/unhide support.
- [ ] Reorder profile edit so basics, preferences, and distance come first; move `About` below those controls; replace distance text input with a slider plus live numeric value.
- [ ] Demote advanced optional filters so the form feels intuitive instead of equally weighted from top to bottom.
- [ ] After backend Stage B, wire full profile-edit prefilling to `GET /api/users/{id}/profile-edit-snapshot`.
- [ ] Run: `flutter test test/features/profile/profile_screen_test.dart test/features/profile/profile_edit_screen_test.dart test/features/location/location_completion_screen_test.dart`

### Task 7: Redesign `Standouts` and `Pending likers` with stronger prioritization and richer scanning

**Files:**
- Modify: `lib/features/browse/standouts_screen.dart`
- Modify: `lib/features/browse/pending_likers_screen.dart`
- Modify: `test/features/browse/standouts_screen_test.dart`
- Modify: `test/features/browse/pending_likers_screen_test.dart`
- Modify: `test/visual_inspection/fixtures/visual_fixture_catalog.dart`
- Modify: `test/visual_inspection/fixtures/visual_scenarios.dart`

- [ ] Add a list/grid toggle to `Standouts`, with grid as the default view.
- [ ] Replace the oversized intro card with a compact summary row or chip cluster.
- [ ] Make standout and liker cards image-forward, compact, and whole-card tappable, with overflow menus in the top-right.
- [ ] Surface prioritization, freshness, and the most important reason(s) without falling back to repetitive filler sentences.
- [ ] Use real backend reason/score data where present and avoid inventing explanatory richness when payloads are thin.
- [ ] Run: `flutter test test/features/browse/standouts_screen_test.dart test/features/browse/pending_likers_screen_test.dart`

### Task 8: Rebuild `Notifications` and redesign `Stats` + `Achievements` around meaningful detail

**Files:**
- Modify: `lib/features/notifications/notifications_screen.dart`
- Modify: `lib/features/stats/stats_screen.dart`
- Modify: `lib/features/stats/achievements_screen.dart`
- Create: `lib/features/stats/stat_detail_sheet.dart`
- Create: `lib/features/stats/achievement_detail_sheet.dart`
- Modify: `test/features/notifications/notifications_screen_test.dart`
- Modify: `test/features/stats/stats_screen_test.dart`
- Modify: `test/features/stats/achievements_screen_test.dart`
- Modify: `test/models/notification_item_test.dart`

- [ ] Rebuild notifications from a grouped inbox model (`Today`, `Yesterday`, `Earlier`) instead of the current stacked-card structure.
- [ ] Use one strong unread signal per item, make row layout scale safely, and keep filters/bulk actions compact but obvious.
- [ ] Before backend Stage B, keep notification rows display-only except for conservative existing read actions; do not add quick actions or deep links.
- [ ] After backend Stage B, add type-aware notification routing only for the stabilized registry in `docs/frontend-ui-overhaul-contract-response-2026-04-25.md`.
- [ ] Redesign stats and achievements conservatively against the current endpoints; make the UI cleaner without inventing grouped meanings or achievement semantics.
- [ ] Keep stat detail sheets and achievement detail sheets shallow/current-data-backed until a P1 backend contract exists.
- [ ] Run: `flutter test test/features/notifications/notifications_screen_test.dart test/features/stats/stats_screen_test.dart test/features/stats/achievements_screen_test.dart`

### Task 9: Polish `Verification`, `Location completion`, `Conversation thread`, and `Blocked users`

**Files:**
- Modify: `lib/features/verification/verification_screen.dart`
- Modify: `lib/features/location/location_completion_screen.dart`
- Modify: `lib/features/chat/conversation_thread_screen.dart`
- Modify: `lib/features/safety/blocked_users_screen.dart`
- Modify: `test/features/verification/verification_screen_test.dart`
- Modify: `test/features/location/location_completion_screen_test.dart`
- Modify: `test/features/chat/conversation_thread_screen_test.dart`
- Modify: `test/features/safety/blocked_users_screen_test.dart`

- [ ] Tighten verification into a guided two-step flow with clearer progression, stronger validation, and a clearly quarantined dev/debug area.
- [ ] Do not add resend/cooldown UX; backend Stage A deferred resend/cooldown support.
- [ ] Reduce whitespace and technical-looking badges in location completion, use flag + country label, and make the city suggestion/selection state feel deliberate.
- [ ] Add a top-right overflow menu to the conversation thread, consolidate excess header actions, and improve the first-visible message alignment.
- [ ] Compact the blocked-users intro, add overflow menus per row, and make unblock confirmation safer than a casual single tap.
- [ ] Run: `flutter test test/features/verification/verification_screen_test.dart test/features/location/location_completion_screen_test.dart test/features/chat/conversation_thread_screen_test.dart test/features/safety/blocked_users_screen_test.dart`

### Task 10: Refresh the screenshot suite, run full verification, and document the result

**Files:**
- Modify: `test/visual_inspection/screenshot_test.dart`
- Modify: `test/visual_inspection/fixtures/visual_fixture_catalog.dart`
- Modify: `test/visual_inspection/fixtures/visual_fixture_builders.dart`
- Modify: `test/visual_inspection/fixtures/visual_scenarios.dart`
- Create: `docs/2026-04-24-ui-overhaul-review.md`
- Modify: `docs/superpowers/plans/2026-04-24-dating-app-ui-overhaul-implementation.md`

- [ ] Update screenshot fixtures and scenarios so the new shells, cards, menus, list/grid mode, grouped notifications, and profile states are all captured deterministically.
- [ ] Run `flutter analyze` and fix any analyzer issues introduced by the overhaul.
- [ ] Run the full `flutter test` suite and fix regressions before claiming the pass is complete.
- [ ] Run `flutter test test/visual_inspection/screenshot_test.dart` to generate a fresh visual review run.
- [ ] Inspect `visual_review/latest/index.html` and all changed PNGs, then do a final consistency pass on spacing, chip semantics, overflow labels, nav overlap, empty states, and no-photo fallbacks.
- [ ] Verify both light and dark themes before closing the work.
- [ ] Write the post-implementation review report and update this plan so every completed task is marked clearly.

---

## Execution notes

- Keep the backend contract untouched **unless** a missing endpoint or field is blocking the approved design; in those cases, treat the backend work as the right solution, not as scope creep.
- Do not add a router package, real auth, subscriptions, payments, or other unrelated architecture work during this overhaul.
- Keep all request/header logic centralized in `lib/api/**` and all state orchestration in providers/controllers.
- Prefer shared widgets over one-off per-screen custom chrome whenever a pattern appears in more than one surface.
- Preserve comfortable tap targets and strong contrast while increasing information density.
- When a backend dependency is unresolved, it is acceptable to land the surrounding layout shell and explicitly leave the data-rich drill-down blocked—but it is **not** acceptable to fake the missing logic in Dart.
- After every major phase, run the relevant widget tests and then the visual review workflow before moving on.
