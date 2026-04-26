# Dating App UI Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Status:** Revised after frontend foundation completion, backend Stage B implementation report, and Task 1B frontend Stage B integration completion on 2026-04-26. Continue with the remaining layout-shell tasks.

**Design input:** `docs/superpowers/specs/2026-04-23-dating-app-ui-overhaul-design.md`

**Goal:** Deliver the validated end-to-end UI overhaul for the Flutter dating app across theme, shell, shared components, people-first surfaces, utility flows, and verification—without lowering the design bar when the current backend contract is too thin.

**Architecture:** Execute foundation-first. First replace the lavender-heavy theme and redundant shell chrome, then add a shared UI kit for overflow menus, developer-only callouts, photo-backed person cards, compact context strips, and detail bottom sheets. After that, redesign the core dating surfaces (`Discover`, `Matches`, `Chats`, profiles), rebuild the most broken utility surface (`Notifications`), finish the remaining forms/utilities, and close with screenshot-driven verification. Keep imperative navigation, Riverpod orchestration, centralized API/header logic, and thin-client boundaries intact.

**Tech Stack:** Flutter 3.41, Dart 3.11, Material 3, Riverpod, Dio, shared_preferences, flutter_test

---

## Validation notes

- The design brief was re-read and validated against the live codebase on 2026-04-24.
- The backend Stage A contract response was received in `docs/frontend-ui-overhaul-contract-response-2026-04-25.md` on 2026-04-25 and is now the contract checkpoint for execution.
- Backend Stage B was reported implemented on 2026-04-26, with the response document updated to say the Stage B additions landed additively against the same JSON shapes.
- Frontend reports Task 2, Task 3, the Task 1 live-contract subset, and Task 1B Stage B contract integration are implemented and verified in the current branch/worktree.
- `matchId == conversationId` is confirmed by backend as live; the frontend may use `matchId` anywhere a conversation id is required.
- `GET /api/users/{id}/match-quality/{matchId}` is confirmed live by backend and wired through the frontend API layer.
- `GET /api/users/{id}/profile-edit-snapshot` is wired through the frontend API layer and profile edit prefill.
- `GET /api/users/{viewerId}/presentation-context/{targetId}` is wired through the frontend API layer and server-driven explanation surfaces.
- `LocationCountry.flagEmoji` already exists in the current models and should be used in the UI.
- `BrowseCandidate`, `MatchSummary`, `PendingLiker`, `DailyPick`, and the current stats payload are all thinner than the desired UI.
- Missing endpoint or DTO support is **not** a reason to weaken the redesign. When the current contract is insufficient, this plan calls it out explicitly as backend work.

## Contract checkpoint

Backend Stage B is reported implemented. Use these gates during frontend execution:

| Area | Backend status | Frontend action now |
|------|----------------|---------------------|
| Match-to-conversation identity | Exists now; frontend reports implemented | Keep using `matchId` as the conversation id and keep chat-opening tests green. |
| Match quality | Exists now; frontend reports implemented in Matches | Continue building `Why we match` against the real response shape. |
| Person summary media/context | ✅ Stage B reported implemented and frontend wired | `primaryPhotoUrl`, `photoUrls`, `approximateLocation`, and `summaryLine` are wired in DTOs and affected people surfaces. |
| Profile edit snapshot | ✅ Stage B reported implemented and frontend wired | Full edit-prefill is wired to `GET /api/users/{id}/profile-edit-snapshot`. |
| Notification schema stabilization | ✅ Stage B reported implemented and frontend wired | Type-aware notification routing/actions are limited to the stabilized registry; unknown future types remain display-only. |
| Presentation context | ✅ Stage B reported implemented and frontend wired | `GET /api/users/{viewerId}/presentation-context/{targetId}` is wired and server-driven `Why this profile is shown` is displayed. |
| Stats and achievements richer semantics | P1 follow-up | Improve current layouts conservatively; do not invent grouped stat meaning or achievement detail semantics. |

### Current execution order

Foundation work is reported complete. Continue in this order:

1. Review the current frontend worktree and keep Task 2, Task 3, and Task 1 live-contract changes intact.
2. ✅ Task 1B — Stage B frontend contract integration pass.
3. Tasks 4 through 9 — continue the remaining layout/surface work with the Stage B DTOs available.
4. Task 10 — final post-overhaul visual/test verification and review report.

## Scope matrix

| Surface             | Work type                       | Backend/API dependency                                  | Primary verification                                                         |
|---------------------|---------------------------------|---------------------------------------------------------|------------------------------------------------------------------------------|
| Dev-user picker     | polish + developer-only framing | none                                                    | `test/features/auth/dev_user_picker_screen_test.dart`, visual review         |
| Signed-in shell     | shell cleanup                   | none                                                    | create `test/features/home/signed_in_shell_test.dart`, visual review         |
| Discover            | major redesign                  | Stage B person summaries and presentation context are reported implemented | `test/features/browse/browse_screen_test.dart`, visual review                |
| Matches             | major redesign                  | match-quality is implemented in frontend; Stage B richer match preview fields are reported implemented | `test/features/matches/matches_screen_test.dart`, visual review              |
| Chats               | medium redesign                 | none                                                    | `test/features/chat/conversations_screen_test.dart`, visual review           |
| Self profile        | medium redesign                 | none                                                    | `test/features/profile/profile_screen_test.dart`, visual review              |
| Other-user profile  | medium redesign                 | presentation-context is reported implemented; hide is deferred | `test/features/profile/profile_screen_test.dart`, visual review              |
| Profile edit        | medium redesign                 | full edit snapshot is reported implemented | `test/features/profile/profile_edit_screen_test.dart`, visual review         |
| Settings            | medium cleanup                  | none                                                    | `test/features/settings/settings_screen_test.dart`, visual review            |
| Standouts           | medium redesign                 | richer standout preview data                            | `test/features/browse/standouts_screen_test.dart`, visual review             |
| Pending likers      | medium redesign                 | richer liker preview data                               | `test/features/browse/pending_likers_screen_test.dart`, visual review        |
| Notifications       | rebuild                         | stabilized routing keys are reported implemented | `test/features/notifications/notifications_screen_test.dart`, visual review  |
| Stats               | medium redesign                 | current endpoint usable; grouped/typed semantics are P1 follow-up | `test/features/stats/stats_screen_test.dart`, visual review                  |
| Achievements        | medium redesign                 | current endpoint usable; richer canonical semantics are P1 follow-up | `test/features/stats/achievements_screen_test.dart`, visual review           |
| Verification        | medium redesign                 | current start/confirm contract only; resend/cooldown is deferred | `test/features/verification/verification_screen_test.dart`, visual review    |
| Location completion | polish                          | existing country/city/resolve endpoints are sufficient  | `test/features/location/location_completion_screen_test.dart`, visual review |
| Conversation thread | low-risk polish                 | none                                                    | `test/features/chat/conversation_thread_screen_test.dart`, visual review     |
| Blocked users       | low-risk polish                 | optional unblock confirmation metadata not required     | `test/features/safety/blocked_users_screen_test.dart`, visual review         |

## Backend/API contract work required to preserve quality

These items should be treated as **quality-preserving backend work**, not optional nice-to-haves. Backend Stage B is reported implemented for the P0 contract items; frontend now needs to wire and verify them.

| Priority | Needed for | Current status | Frontend execution rule |
|----------|------------|----------------|-------------------------|
| P0 | Correct `Message now` and chat-thread routing | Exists now: `matchId == conversationId` | Verify current flows and do not wait for a new conversation id field. |
| P0 | `Why we match` bottom sheet on `Matches` | Exists now: `GET /api/users/{id}/match-quality/{matchId}` | Wire API/model/tests now against the Stage A response shape. |
| P0 | Photo-backed person cards in `Discover`, `Matches`, `Pending likers`, `Standouts`, and compact `Daily pick` | ✅ Stage B frontend wiring complete | Additive fields are wired and graceful null/no-photo behavior is preserved. |
| P0 | `Why this profile is shown` on `Discover` and other-user profile | ✅ Stage B frontend wiring complete | Endpoint/model are wired and only server-driven reasons are shown. |
| P0 | Complete profile-edit prefilling | ✅ Stage B frontend wiring complete | Snapshot endpoint/model are wired and edit-prefill tests are updated. |
| P0 | Notification deep links and quick actions | ✅ Stage B frontend wiring complete | Only stabilized known types route; unknown and incomplete types remain display-only. |
| P1 | Stats grouping + stat detail sheets | Follow-up contract needed | Improve current presentation conservatively; do not infer stat meaning. |
| P1 | Achievement drill-downs that feel meaningful | Follow-up contract needed | Improve current presentation conservatively; do not infer achievement semantics. |
| P1 | Persistent `Hide` action on other-user profiles | Deferred | Do not ship persistent hide. If UI includes `Hide`, label it as deferred or omit it. |
| P2 | Verification resend/cooldown UX | Deferred | Do not add resend/cooldown UX yet. |

### Backend Stage B status

Backend reports the P0 Stage B work is implemented in an uncommitted backend working tree at `main` / `HEAD 129273a`, with backend tests passing except for unrelated existing/environment failures. Frontend should proceed with integration against the documented Stage B contract, while the manager keeps backend commit/review hygiene separate.

Still later P1/P2: grouped/typed stats, richer achievements, conversation enrichment, persistent hide, verification resend/cooldown, dev-only cleanup.

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

### Task 1B: Stage B contract integration pass

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
- Create: `lib/models/person_summary_fields.dart`
- Create: `test/models/profile_presentation_context_test.dart`
- Create: `test/models/profile_edit_snapshot_test.dart`
- Create: `test/models/person_summary_contract_test.dart`
- Modify: `test/models/browse_response_test.dart`
- Modify: `test/models/standout_test.dart`
- Modify: `test/models/notification_item_test.dart`

- [x] ✅ Extend summary DTOs with `primaryPhotoUrl`, `photoUrls`, `approximateLocation`, and `summaryLine`.
- [x] ✅ Add `profile-edit-snapshot` endpoint/model wiring.
- [x] ✅ Update `NotificationItem` tests for the stabilized type/data registry; do not deep-link unknown types.
- [x] ✅ Add `presentation-context` endpoint/model wiring.
- [x] ✅ Keep any P1 stats/achievements/conversation/hide/verification additions out of this pass unless the manager explicitly promotes them.
- [x] ✅ Run the expanded API/model tests after each confirmed backend contract is wired.

**Completed verification on 2026-04-26:**
- ✅ `flutter analyze`
- ✅ `flutter test test/models/browse_response_test.dart test/models/standout_test.dart test/models/person_summary_contract_test.dart test/models/profile_presentation_context_test.dart test/models/profile_edit_snapshot_test.dart test/models/notification_item_test.dart test/api/api_client_test.dart`
- ✅ Affected feature tests for browse, pending likers, standouts, matches, profile, profile edit, and notifications
- ✅ Full `flutter test`
- ✅ `flutter test test/visual_inspection/screenshot_test.dart` through the full suite, producing visual review run `0012`

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
- [x] ✅ Wire Stage B person-summary fields and presentation-context data, while preserving intentional no-photo/current-contract fallbacks.
- [x] ✅ Run: `flutter test test/features/browse/browse_screen_test.dart`

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
- [x] ✅ Wire Stage B richer match preview fields where applicable.
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

- [x] ✅ Tighten the self-profile hero so identity, compact state/location metadata, and a small readiness indicator are visible above the fold without explanatory clutter.
- [x] ✅ Remove the over-promotion of tiny facts into separate full-width cards.
- [x] ✅ Redesign the other-user profile hero to surface `Profile snapshot`, compact metadata, photos earlier, and a top-right overflow menu.
- [x] ✅ Wire `Why this profile is shown` to server-driven presentation-context data.
- [x] ✅ Do not add persistent `Hide`; backend Stage A deferred hide/unhide support.
- [x] ✅ Reorder profile edit so basics, preferences, and distance come first; move `About` below those controls; replace distance text input with a slider plus live numeric value.
- [x] ✅ Demote advanced optional filters so the form feels intuitive instead of equally weighted from top to bottom.
- [x] ✅ Wire full profile-edit prefilling to `GET /api/users/{id}/profile-edit-snapshot`.
- [x] ✅ Run affected profile tests: `flutter test test/features/profile/profile_screen_test.dart test/features/profile/profile_edit_screen_test.dart`
- [x] ✅ Run full Task 6 command including location completion when doing the complete profile/location redesign: `flutter test test/features/profile/profile_screen_test.dart test/features/profile/profile_edit_screen_test.dart test/features/location/location_completion_screen_test.dart`

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
- [x] ✅ Wire Stage B person-summary fields into standout and liker cards.
- [ ] Make standout and liker cards image-forward, compact, and whole-card tappable, with overflow menus in the top-right.
- [x] ✅ Surface prioritization, freshness, and the most important reason(s) without falling back to repetitive filler sentences.
- [x] ✅ Use real backend reason/score data where present and avoid inventing explanatory richness when payloads are thin.
- [x] ✅ Run: `flutter test test/features/browse/standouts_screen_test.dart test/features/browse/pending_likers_screen_test.dart`

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
- [x] ✅ Add type-aware notification routing only for the stabilized registry in `docs/frontend-ui-overhaul-contract-response-2026-04-25.md`.
- [x] ✅ Keep unknown and incomplete notification types display-only.
- [x] ✅ Redesign stats and achievements conservatively against the current endpoints; make the UI cleaner without inventing grouped meanings or achievement semantics.
- [x] ✅ Keep stat detail sheets and achievement detail sheets shallow/current-data-backed until a P1 backend contract exists.
- [x] ✅ Run affected notification tests: `flutter test test/features/notifications/notifications_screen_test.dart`
- [x] ✅ Run full Task 8 command when doing the complete notifications/stats/achievements redesign: `flutter test test/features/notifications/notifications_screen_test.dart test/features/stats/stats_screen_test.dart test/features/stats/achievements_screen_test.dart`

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

- [x] ✅ Tighten verification into a guided two-step flow with clearer progression, stronger validation, and a clearly quarantined dev/debug area.
- [x] ✅ Do not add resend/cooldown UX; backend Stage A deferred resend/cooldown support.
- [x] ✅ Reduce whitespace and technical-looking badges in location completion, use flag + country label, and make the city suggestion/selection state feel deliberate.
- [x] ✅ Add a top-right overflow menu to the conversation thread, consolidate excess header actions, and improve the first-visible message alignment.
- [x] ✅ Compact the blocked-users intro, add overflow menus per row, and make unblock confirmation safer than a casual single tap.
- [x] ✅ Run: `flutter test test/features/verification/verification_screen_test.dart test/features/location/location_completion_screen_test.dart test/features/chat/conversation_thread_screen_test.dart test/features/safety/blocked_users_screen_test.dart`

### Task 10: Refresh the screenshot suite, run full verification, and document the result

**Files:**
- Modify: `test/visual_inspection/screenshot_test.dart`
- Modify: `test/visual_inspection/fixtures/visual_fixture_catalog.dart`
- Modify: `test/visual_inspection/fixtures/visual_fixture_builders.dart`
- Modify: `test/visual_inspection/fixtures/visual_scenarios.dart`
- Create: `docs/2026-04-24-ui-overhaul-review.md`
- Modify: `docs/superpowers/plans/2026-04-24-dating-app-ui-overhaul-implementation.md`

- [ ] Update screenshot fixtures and scenarios so the new shells, cards, menus, list/grid mode, grouped notifications, and profile states are all captured deterministically.
- [x] ✅ Run `flutter analyze` and fix any analyzer issues introduced by Task 1B.
- [x] ✅ Run the full `flutter test` suite and fix regressions before claiming Task 1B is complete.
- [x] ✅ Run `flutter test test/visual_inspection/screenshot_test.dart` to generate a fresh visual review run for Task 1B.
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
