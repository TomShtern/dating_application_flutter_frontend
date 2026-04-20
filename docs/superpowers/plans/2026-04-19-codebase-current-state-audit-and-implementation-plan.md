# Flutter Frontend Current-State Audit & Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Capture the real current state of the Flutter frontend, identify what is missing or weak, and define a practical implementation roadmap that improves the existing core product before jumping to production-only work.

**Architecture:** Keep the Flutter app as a thin client over the Java backend. Prioritize stabilization and usability first, then fill backend-supported mobile surfaces, then improve architecture and production readiness. Do not invent client-side business rules that the backend does not own.

**Tech Stack:** Flutter, Dart, Material 3, Riverpod, Dio, SharedPreferences, flutter_test

---

## Audit method

This audit was built from four sources of truth:

1. **Repository docs**
   - `README.md`
   - `FLUTTER_FRONTEND_AGENT_GUIDE.md`
   - `FLUTTER_PROJECT_HANDOFF.md`
   - existing plans under `docs/superpowers/plans/`
2. **Code inventory**
   - `47` Dart files under `lib/`
   - `27` Dart test files under `test/`
3. **Parallel codebase reviews**
   - app shell / architecture
   - feature coverage
   - API and model coverage
   - tests and docs coverage
4. **Live verification run**
   - `flutter analyze`
   - `flutter test`

Additional note:
- A root `.env` file is present in the repository.

---

## Current state in short

The app is **well past bootstrap**. It already implements a usable development version of the core mobile loop:

- dev user picker
- discover / browse
- like / pass
- matches
- conversations
- chat thread with send message
- profile view
- profile edit
- settings
- safety actions

The repository now also has a **restored green verification baseline**:

- `flutter analyze` passes
- `flutter test` passes
- the earlier docs that reported a red baseline are now stale and should be read as historical context

So the honest snapshot is:

- **functional breadth:** solid for an internal/dev prototype
- **visual completeness:** still lean and text-heavy in several core surfaces
- **screen completeness:** important mobile product areas are still missing
- **technical health:** good architectural foundation with a restored green validation baseline

---

## What is already implemented

### App shell and navigation

Current shell:

- `lib/features/home/app_home_screen.dart`
- `lib/features/home/signed_in_shell.dart`

Current behavior:

- app boots into `AppHomeScreen`
- if there is no persisted selected dev user, the app shows `DevUserPickerScreen`
- if a selected dev user exists, the app shows `SignedInShell`
- `SignedInShell` uses a local `_selectedIndex` with `IndexedStack`
- bottom navigation has five destinations:
  - `Discover`
  - `Matches`
  - `Chats`
  - `Profile`
  - `Settings`
- deeper navigation uses `Navigator.push(...)` with `MaterialPageRoute`
- there is **no router package**, **no deep linking**, and **no named route system**

### Core screens and flows

Implemented screen inventory:

| Surface                          | Current state           | Notes                                                        |
|----------------------------------|-------------------------|--------------------------------------------------------------|
| Dev user picker                  | Implemented             | Uses `GET /api/users`, persists selected user locally        |
| Discover / browse                | Implemented             | Supports refresh, like, pass, view profile, safety menu      |
| Daily pick                       | Implemented             | Visible, but text-first and visually light                   |
| Browse conflict / inactive state | Implemented             | Handles `409` via a dedicated conflict card                  |
| Matches list                     | Implemented             | Opens profile or conversation, includes safety actions       |
| Conversations list               | Implemented             | Opens conversation thread                                    |
| Conversation thread              | Implemented             | Loads messages, sends message, polls every 20s while visible |
| Profile view                     | Implemented             | Current user and other-user variants                         |
| Profile edit                     | Partial                 | Edits only the currently surfaced fields                     |
| Settings                         | Implemented but minimal | Theme mode + switch user                                     |
| Safety actions                   | Implemented             | Block, unblock, report, unmatch                              |
| Backend health banner            | Implemented             | Used for development diagnostics                             |

### Current feature folders

Current `lib/features/` folders:

- `auth/`
- `browse/`
- `chat/`
- `home/`
- `matches/`
- `profile/`
- `safety/`
- `settings/`

Important absence:

There are **no current feature folders** for:

- `notifications/`
- `stats/`
- `verification/`
- `standouts/`
- `pending_likers/`
- `location/`
- `discovery_preferences/`
- `blocked_users/`

That alone is a strong signal about what is still missing.

---

## API surface currently wired in Flutter

The current mobile app only wires the following endpoint groups into `lib/api/api_client.dart` and `lib/api/api_endpoints.dart`:

- `GET /api/health`
- `GET /api/users`
- `GET /api/users/{id}`
- `PUT /api/users/{id}/profile`
- `GET /api/users/{id}/browse`
- `POST /api/users/{id}/like/{targetId}`
- `POST /api/users/{id}/pass/{targetId}`
- `GET /api/users/{id}/matches`
- `GET /api/users/{id}/conversations`
- `GET /api/conversations/{conversationId}/messages`
- `POST /api/conversations/{conversationId}/messages`
- `POST /api/users/{id}/block/{targetId}`
- `DELETE /api/users/{id}/block/{targetId}`
- `POST /api/users/{id}/report/{targetId}`
- `POST /api/users/{id}/relationships/{targetId}/unmatch`

This means the current Flutter implementation is focused on the **core loop + safety basics**, and little beyond that.

---

## What is partially implemented or visually weak

### Discover / browse is functional but not yet visually strong

The current `BrowseScreen` is usable, but it still feels closer to a structured prototype than a polished dating-app discovery surface.

Current strengths:

- clear action bar for `Like` / `Pass`
- current user summary
- daily pick card
- location warning card
- explicit browse conflict handling
- profile handoff for richer detail

Current weaknesses:

- the primary browse card is still **text-led**, not image-led
- no swipe deck or gesture-based interaction
- no card stack animation
- no skeleton loading
- no image-forward presentation of candidates
- no browse filters/preferences UI
- no undo action in the mobile UI
- no pending likers / “who liked me” UI

Important nuance:

- `BrowseScreen` explicitly tells the user that the browse DTO is intentionally lean
- current browse items only surface `id`, `name`, `age`, `state`
- richer discovery cards likely need backend DTO enrichment or a deliberate secondary fetch strategy

### Profile exists, but profile management is still narrow

Current strengths:

- profile detail loads for current user and other users
- profile edit exists
- profile detail can render `photoUrls` via `Image.network`
- safety actions are available on other-user profiles

Current limitations:

- profile edit only updates:
  - `bio`
  - `gender`
  - `interestedIn`
  - `maxDistanceKm`
- no photo upload / delete / reorder / set-primary-photo flow
- no location edit / resolution flow from the profile UI
- no richer edit experience for additional dating profile fields
- no profile completion progress or onboarding guidance

### Matches and conversations exist, but are still lightweight

Current strengths:

- matches list works
- conversations list works
- thread screen works
- message sending works
- thread auto-refreshes while the route is visible

Current limitations:

- no unread indicators
- no avatar/photo presentation in matches or chats
- no last-message preview in the UI beyond simple count and timestamp formatting
- no archive/mute/manage-conversation flows
- no pull-to-refresh gesture
- no pagination / infinite scroll even though the backend endpoints are paginated
- chat is polling-based, not real-time
- no typing indicators, receipts, or presence state

### Settings exists, but it is still just a utility screen

Current settings scope is intentionally minimal:

- switch dev user
- choose theme mode

Missing from settings:

- notification preferences
- privacy settings
- discovery preferences
- account controls
- verification status
- safety/history controls

---

## Missing screens and product surfaces

### High-value mobile screens missing right now

These are the clearest missing UI surfaces based on the current codebase plus the handoff docs.

| Missing surface                        | Current evidence                                            | Priority    |
|----------------------------------------|-------------------------------------------------------------|-------------|
| Blocked users management screen        | no `features/blocked_users/`; no current mobile surface     | High        |
| Verification screen / flow             | no `features/verification/`; no verification UI wired       | High        |
| Notifications center                   | no `features/notifications/`; no notifications API wiring   | High        |
| Stats / achievements screen            | no `features/stats/`; no API wiring                         | Medium-High |
| Standouts screen                       | no standouts feature folder or API wiring                   | Medium-High |
| Pending likers / likes-you screen      | not represented in Flutter features or API client           | Medium-High |
| Undo last swipe UI                     | backend support is documented, but mobile UI is absent      | Medium      |
| Location completion / fix flow         | `locationMissing` is shown, but there is no guided fix path | High        |
| Discovery preferences / filters screen | absent from features and settings                           | High        |
| Photo management screen                | profile reads photos, but no upload/manage flow exists      | High        |
| Search / people lookup surface         | absent                                                      | Low-Medium  |
| Onboarding / real auth / signup        | intentionally out of scope today, still absent              | Future      |

### Missing visual features and interaction quality

The app has the right skeleton, but still needs several visual and interaction upgrades to feel like a stronger dating app:

- image-forward discovery cards
- richer candidate presentation hierarchy
- swipe gestures / card throw interaction
- better empty-state visuals
- skeleton loaders or shimmer placeholders
- stronger date/time formatting across lists and threads
- more branded visual identity across discovery and profile surfaces
- better avatar handling throughout matches and chats
- visually richer daily pick presentation
- persistent unread / fresh activity affordances
- more polished success/failure feedback for relationship actions

---

## Technical and quality observations

### The biggest immediate issue: the repository is currently red

Live verification found that the repo is **not currently healthy**.

#### `flutter analyze`

Live result:

- **failed**
- reported `13` issues total
- included `8` errors, `2` warnings, and `3` infos

Most important findings:

- `test/features/home/signed_in_shell_test.dart` has provider override type mismatch problems
- `test/features/safety/safety_action_sheet_test.dart` has compile-time const/property access issues
- `test/widget_test.dart` references `sharedPreferencesProvider` without importing the provider definition
- `lib/features/auth/selected_user_store.dart` contains a broken nested implementation and an unused declaration warning

#### `flutter test`

Live result:

- **failed**
- final summary reported `+59 -4`

Important failures:

- `test/features/auth/selected_user_store_test.dart`
  - expected a restored `UserSummary`
  - actual value was `null`
- `test/features/home/signed_in_shell_test.dart`
  - failed to load because of provider override/type mismatch
- `test/features/safety/safety_action_sheet_test.dart`
  - failed to load because of test compile errors
- `test/widget_test.dart`
  - failed to load because of the missing `sharedPreferencesProvider` reference/import mismatch

### Real regression found in source code

`lib/features/auth/selected_user_store.dart` currently contains an accidental nested `readSelectedUser()` function inside `readSelectedUser()`.

Practical effect:

- persisted selected user restoration is broken
- auth/user-restoration tests fail
- `AppHomeScreen` restoration behavior is less trustworthy than the docs imply

### Manual provider invalidation is doing a lot of work

The Riverpod foundation is good, but several flows rely on manual invalidation fan-out:

- browse mutations invalidate browse data and sometimes matches + conversations
- safety actions invalidate browse + matches + conversations + other-user profile
- profile update invalidates current profile + other-user profile for the current user
- message send invalidates thread + conversations

This is fine for the current size, but it becomes easy to miss dependent state as the app grows.

### API client is centralized, but still monolithic

`lib/api/api_client.dart` is a clean single entry point today, but it is also becoming the one file that knows every endpoint.

Current implications:

- good for bootstrapping
- less good for long-term scaling
- missing domain separation for chat, discovery, safety, notifications, etc.

### Navigation is simple and easy to follow, but limited

Current navigation approach:

- `IndexedStack` shell
- local selected tab index
- `Navigator.push(...)` for deeper screens

What this means:

- good for the current app size
- not good enough if the app needs:
  - deep linking
  - better route restoration
  - nested flows
  - future auth routing complexity

### Test coverage is decent in breadth, but not strong enough in the right places

The codebase has a respectable number of tests, but there are still important gaps:

- no direct tests for the full API client surface
- missing or stale coverage for some shell/home/conversations flows
- no golden tests
- no accessibility test layer
- no integration-level validation against a real backend contract from this repo

The current problem is not that the repo has no tests.
The real problem is that the repo has enough tests to give confidence, but not enough maintenance discipline to keep the suite green.

---

## Docs versus code reality

The docs are broadly directionally correct about the architecture and scope, but they are now **too optimistic** about verification status.

What still matches reality:

- thin-client boundary
- Flutter + Riverpod + Dio stack
- core loop focus
- dev user picker instead of real auth
- backend-owned business rules

What no longer matches the live repository state:

- documentation implying that analysis/test verification is currently green

Practical recommendation:

- treat the docs as good architectural guidance
- treat the live code and verification run as the actual truth for current health

---

## Recommended implementation order

The right next move is **not** to jump straight into real auth, push notifications, or other production-only work.

The correct order for this codebase is:

1. **restore the repo to a green baseline**
2. **improve the current core loop UX and visuals**
3. **add the highest-value missing screens that the backend already supports**
4. **strengthen architecture where it will soon start to creak**
5. **only then move into production-only concerns like real auth and advanced delivery features**

---

## Implementation plan

### Phase 0: Restore a trustworthy green baseline

**Why this comes first:**
The repo is currently red. Any further feature work on top of a broken baseline will blur real regressions with pre-existing ones.

**Likely files:**
- `lib/features/auth/selected_user_store.dart`
- `test/features/auth/selected_user_store_test.dart`
- `test/features/home/signed_in_shell_test.dart`
- `test/features/safety/safety_action_sheet_test.dart`
- `test/widget_test.dart`
- `lib/features/profile/profile_screen.dart`
- `test/features/chat/conversations_screen_test.dart` (new)
- `test/features/home/app_home_screen_test.dart` (new)
- `test/features/chat/conversations_provider_test.dart` (new)
- `test/features/home/backend_health_provider_test.dart` (new)
- `test/features/settings/app_preferences_provider_test.dart` (new)
- `test/api/api_client_test.dart` (new)

**Known current breakpoints to fix first:**
- `lib/features/auth/selected_user_store.dart`
  - remove the accidental nested `readSelectedUser()` implementation so the outer method actually returns the parsed persisted user
- `test/features/home/signed_in_shell_test.dart`
  - replace the invalid async `appPreferencesProvider.overrideWith(...)` usage with a correct synchronous `Notifier`-compatible override strategy
- `test/features/safety/safety_action_sheet_test.dart`
  - remove the invalid `const` widget usage around runtime `UserSummary` property access
- `test/widget_test.dart`
  - import `sharedPreferencesProvider` from `lib/shared/persistence/shared_preferences_provider.dart`
- `lib/features/profile/profile_screen.dart`
  - replace deprecated `surfaceVariant` usage with the current Material 3 color token

- [x] Fix the nested `readSelectedUser()` regression in `lib/features/auth/selected_user_store.dart`.
- [x] Repair the stale test scaffolding issues in:
  - `test/features/home/signed_in_shell_test.dart`
  - `test/features/safety/safety_action_sheet_test.dart`
  - `test/widget_test.dart`
- [x] Fix the currently flagged deprecated Material 3 API usage in `lib/features/profile/profile_screen.dart`.
- [x] Add missing direct tests for the currently uncovered but important app shell/provider pieces.
- [x] Add at least one focused test file for `ApiClient` request/response behavior.
- [x] Re-run `flutter analyze`.
- [x] Re-run `flutter test`.
- [x] Do not start new product work until the baseline is green again.

**Exit criteria:**
- `flutter analyze` passes
- `flutter test` passes
- selected user restoration is confirmed working again

### Phase 1: Make the existing core loop feel more like a dating app

**Why this comes next:**
The current app is functional, but it still reads as a strong internal prototype more than a visually convincing consumer dating app.

**Primary goal:**
Upgrade discovery, matches, chats, and profile visuals without violating the thin-client boundary.

**Likely files:**
- `lib/features/browse/browse_screen.dart`
- `lib/features/matches/matches_screen.dart`
- `lib/features/chat/conversations_screen.dart`
- `lib/features/chat/conversation_thread_screen.dart`
- `lib/features/profile/profile_screen.dart`
- `lib/theme/app_theme.dart`
- `lib/shared/formatting/date_formatting.dart` (new)
- `lib/shared/providers/selected_user_guard.dart` (new, only if a small helper meaningfully removes duplication)
- `lib/shared/widgets/` (new reusable visual widgets)
- `pubspec.yaml` (only if a package such as `intl` or `cached_network_image` is truly justified)

- [x] Improve browse card hierarchy and layout so the primary surface feels less admin-like and more discovery-oriented.
- [x] Improve daily pick presentation so it reads like a featured dating surface rather than a plain info card.
- [x] Improve avatar/photo treatment across matches, chats, and profiles.
- [x] Add stronger loading, empty, and error visuals for the current main screens.
- [x] Improve timestamp formatting and list readability in matches and conversations.
- [x] Extract duplicated date/time formatting into `lib/shared/formatting/date_formatting.dart` instead of repeating `_formatDateTime()` in multiple screens.
- [x] Reduce the repeated selected-user guard logic across controllers with a small shared helper if that meaningfully simplifies the current Riverpod pattern.
- [x] Wire the backend-supported undo action into browse as an early quick win after the baseline is green again.
- [x] Add better thread quality-of-life behavior in chat (composer polish, scroll behavior confirmation, refresh affordances).
- [x] Consider gesture-based swipe interaction only if it can be added cleanly without faking unsupported backend behavior.

**Important constraint:**
Do not invent fake discovery richness that the backend does not currently supply. If browse cards need more data than the browse DTO exposes, log that as a backend-enrichment dependency.

**Exit criteria:**
- discovery looks intentionally mobile and visually stronger
- matches and chat lists are more readable and polished
- profile photo rendering is more graceful where URLs exist
- widget/golden coverage expands for the upgraded surfaces

### Phase 2: Add the missing backend-backed mobile screens

**Why this is high value:**
The backend handoff docs describe several product areas that the mobile app still does not expose at all.

**Primary goal:**
Fill in the highest-value screens that already align with the backend contract.

**Likely new feature folders/files:**
- `lib/features/safety/blocked_users_screen.dart`
- `lib/features/verification/verification_screen.dart`
- `lib/features/notifications/notifications_screen.dart`
- `lib/features/stats/stats_screen.dart`
- `lib/features/stats/achievements_screen.dart`
- `lib/features/browse/standouts_screen.dart`
- `lib/features/browse/pending_likers_screen.dart`
- `lib/features/location/location_completion_screen.dart`
- `lib/api/api_client.dart`
- `lib/api/api_endpoints.dart`
- matching model files under `lib/models/`
- matching tests under `test/features/**` and `test/models/**`

- [x] Add blocked-users management if the documented backend endpoint is confirmed and stable.
- [x] Add verification UI if the documented verification endpoints are confirmed and stable.
- [x] Add notifications center if the documented notification endpoints are confirmed and stable.
- [x] Add stats / achievements surfaces if the documented endpoints are confirmed and stable.
- [x] Add standouts and pending-likers discovery surfaces if the documented endpoints are confirmed and stable.
- [x] Add a location completion / remediation flow instead of only showing `locationMissing` as a passive warning.

**Important constraint:**
For each surface above, confirm the actual backend contract before implementation. Do not assume the handoff docs are enough on their own.

**Exit criteria:**
- the mobile app covers more than just the bare core loop
- missing screens from the documented backend surface start to disappear
- the app becomes more complete without drifting into fake client-side product logic

### Phase 3: Expand profile completeness and user control

**Why this matters:**
The app can show and lightly edit profiles, but users still cannot manage key profile and discovery inputs well enough from mobile.

**Primary goal:**
Make the app feel more self-sufficient for profile completion and discovery control.

**Current baseline to build from:**
The current mobile profile edit flow already supports `bio`, `gender`, `interestedIn`, and `maxDistanceKm`. Expand beyond that baseline deliberately, based on the real read/write backend contract rather than assumptions.

**Likely files:**
- `lib/features/profile/profile_edit_screen.dart`
- `lib/features/profile/profile_screen.dart`
- `lib/features/settings/settings_screen.dart`
- `lib/features/discovery_preferences/` (new)
- `lib/features/location/` (new)
- `lib/api/api_client.dart`
- `lib/api/api_endpoints.dart`
- relevant new models/tests

- [ ] Add discovery preferences/filter UI if the backend supports the necessary write/read paths.
- [x] Add location editing/resolution flow if the backend supports it for mobile.
- [x] Expand editable profile fields only where the backend contract is clear and safe.
- [x] Add profile completeness cues so users know what they still need to finish.
- [ ] Add a proper photo management flow if and only if the backend exposes a real upload/manage contract.

**Important dependency:**
This phase may require backend help because the current read-side profile DTO is thinner than a full edit experience wants.

**Exit criteria:**
- profile management is not limited to a small form
- users can resolve missing location/profile completeness problems from mobile
- discovery controls are more explicit and user-driven

### Phase 4: Strengthen architecture before scale hurts

**Why this matters:**
The current architecture is appropriate for the present size, but several seams will become fragile as more screens and flows are added.

**Primary goal:**
Make the codebase easier to grow without turning every mutation into a provider invalidation scavenger hunt.

**Likely files:**
- `lib/features/home/signed_in_shell.dart`
- `lib/app/app.dart`
- `lib/api/api_client.dart`
- new route/config/helpers as needed
- multiple provider files
- `pubspec.yaml` if router or helper packages are truly justified

- [ ] Decide whether to keep imperative navigation or adopt a router before the route tree gets much bigger.
- [ ] Break up API/client responsibilities if the endpoint count keeps growing.
- [ ] Improve state refresh strategy so invalidation dependencies are easier to reason about.
- [ ] Add pagination/infinite scroll for endpoint families that already support `limit` / `offset`.
- [ ] Consider lightweight caching / stale-while-refresh patterns for lists and threads.
- [ ] Add stronger formatting/utilities rather than repeating date and status formatting inline.

**Exit criteria:**
- route handling is clearer
- data refresh rules are less fragile
- large lists can scale beyond the first page
- feature work becomes easier, not harder

### Phase 5: Production-readiness work (only after the above)

**Why this is later:**
This work matters, but it should not outrank stabilization, usability, and missing core product surfaces in the current codebase.

**Likely areas:**
- real authentication / onboarding
- production session model
- push notifications
- real-time chat transport
- crash reporting / analytics
- CI verification pipeline
- release configuration hardening

- [ ] Add real auth only when the backend auth contract is ready.
- [ ] Add push notifications only when backend delivery and mobile token lifecycle are ready.
- [ ] Revisit polling-only chat when a real-time backend transport exists.
- [ ] Add CI automation for analyze + test before expanding the team/workflow surface further.
- [ ] Add release-grade environment handling once the runtime environments are more mature.

**Exit criteria:**
- the app is no longer just a strong dev frontend
- the product can begin moving toward real-user readiness

---

## Concrete “what should be added / changed / improved” summary

### Add

Add these missing screens/features next:

- blocked users management
- verification
- notifications center
- stats and achievements
- standouts
- pending likers / likes-you
- location completion flow
- undo last swipe
- discovery preferences
- photo management

### Change

Change these existing implementation realities:

- fix the broken selected-user restoration path
- fix the stale failing tests before adding more features
- stop relying on docs alone as proof of green verification
- improve browse so it reads like a product surface, not a placeholder card list
- improve matches/conversations readability and richness

### Improve

Improve these quality dimensions across the codebase:

- test reliability
- API client coverage
- shell/navigation scalability
- loading/empty/error polish
- avatar/photo presentation
- timestamp formatting
- pagination support
- state invalidation discipline

---

## Recommended immediate next slice

If this repo should only do **one** serious next slice, it should be:

1. **Phase 0** — restore the repo to green
2. **then a focused Phase 1 pass** on:
   - discover visual polish
   - profile/photo treatment
   - matches/conversations readability

That gives the best balance of:

- realism
- user-visible improvement
- architectural safety
- momentum on the current core flows

It is a much better next step than jumping straight to real auth or other heavyweight production work.

---

## Final assessment

This codebase is **not missing its foundation**.
It already has a meaningful working mobile frontend for the core dating-app loop.

What it is missing now is:

- additional post-baseline product surface work beyond the restored green verification state
- several obvious product screens that the app does not surface yet
- stronger discovery/profile visual design
- a more complete mobile expression of backend-supported features
- some architectural hardening before feature count increases further

In short:

- **current state:** functional, structured, partially incomplete, and back to a green verification baseline
- **next move:** continue filling the safest backend-backed mobile surfaces while preserving the thin-client boundary
