# Flutter Frontend Audit Handoff

> Date: 2026-04-19
> Scope: `flutter_dating_application_1` plus the sibling backend repo `Date_Program` where integration details affect the mobile app
> Purpose: give a future implementation agent one clean, comprehensive inventory of what is wrong, what is missing, what is fragile, and what should be improved next

## Why this file exists

This frontend is no longer an empty shell. The core mobile loop mostly works, the app runs on the Android emulator, and the backend can be brought up locally. However, the product still behaves and looks more like a **polished internal/dev build** than a complete consumer-facing dating app.

This document is meant to prevent future agents from:

- re-discovering the same issues from scratch
- trusting stale docs
- fixing only UI polish while leaving fragile architecture underneath
- adding more features on top of brittle runtime assumptions

## Evidence used for this audit

### Runtime verification from this session

- `flutter analyze` → clean
- `flutter test` → `93 passed, 0 failed`
- Android emulator app launched successfully
- Local PostgreSQL was started and verified on `localhost:55432`
- Local REST API was started and verified healthy on `http://127.0.0.1:7070/api/health`

### Screenshot evidence reviewed

- dev-user picker
- discover in light theme
- discover in dark theme
- profile in light theme
- settings in light theme
- settings in dark theme
- matches empty state in dark theme
- achievements loading/fix state during runtime investigation

### Code and docs reviewed

Representative files across:

- `lib/api/**`
- `lib/features/**`
- `lib/shared/**`
- `lib/theme/**`
- `test/**`
- `README.md`
- `FLUTTER_PROJECT_HANDOFF.md`
- `docs/2026-04-19-project-state-review.md`

And in the sibling backend repo:

- `..\Date_Program\README.md`
- `..\Date_Program\REST_LAN_STARTUP.md`
- `..\Date_Program\config\app-config.json`
- `..\Date_Program\src\main\java\datingapp\app\api\RestApiServer.java`
- `..\Date_Program\src\main\java\datingapp\app\api\RestApiRequestGuards.java`
- `..\Date_Program\src\main\java\datingapp\app\api\RestApiDtos.java`
- `..\Date_Program\src\main\java\datingapp\storage\DatabaseManager.java`

## Current state in one paragraph

The app already has a usable foundation: dev-user picker, Discover, like/pass/undo, matches, conversations, message sending, profile view/edit, safety actions, settings, theme switching, stats, and achievements. The biggest problems are not “nothing exists”; they are **product incompleteness, dev-facing UI leaking into the experience, fragile user-scoped state/caching, manually bootstrapped runtime dependencies, underpowered loading/error/offline UX, and several backend/frontend contract seams that can break easily during future refactors.**

## What already works and should not be rebuilt from scratch

These areas are present and functionally real:

- dev user picker and persisted selected user
- Discover flow
- like / pass / undo actions
- matches list
- conversations list
- chat thread with send-message flow
- profile view
- partial profile editing
- safety actions: block, report, unmatch
- settings screen
- theme switching
- stats screen
- achievements screen
- backend health banner
- signed-in shell with bottom navigation

Future work should improve and stabilize these, not replace them blindly.

## Priority summary

### P0 — Fix first before major feature work

1. **User-scoped provider reactivity is fragile**
2. **Local stack bring-up is still too manual and easy to get wrong**
3. **Backend/frontend contract seams are under-documented and brittle**
4. **Discover is visually and structurally dominated by dev/infrastructure UI**
5. **Stale docs can send future agents in the wrong direction**

### P1 — High-value product work

1. remove developer-facing UI copy from user-facing flows
2. strengthen Discover as the primary task surface
3. improve loading, empty, and offline states
4. expand missing core-adjacent features like notifications and pending likers
5. move stats/achievements out of Settings or redesign their placement

### P2 — Important but can follow stabilization

1. richer profile editing
2. blocked-users management and unblock UI
3. better pagination, image handling, and chat resiliency
4. broader accessibility work
5. transport/client modularization

## Issues by area

## Runtime and integration issues

### 1. Local startup still depends on manual multi-step bootstrapping

**Type:** Confirmed runtime issue
**Severity:** P0

To run the full mobile loop locally, someone still has to:

1. start local PostgreSQL on `55432`
2. ensure the DB password is available through env or `.env`
3. compile the backend
4. start the REST server separately on `7070`
5. launch Flutter with the correct `.env`
6. use the correct host for the chosen device (`10.0.2.2` for emulator, LAN IP for physical device)

**Why this is a problem**

This is easy to do incorrectly, and several failure modes look like generic frontend bugs:

- backend not running
- wrong host for device
- wrong entrypoint (`mvn exec:exec` instead of `RestApiServer`)
- DB password missing
- REST server not started after verification run

**Relevant files**

- `..\Date_Program\README.md`
- `..\Date_Program\REST_LAN_STARTUP.md`
- `..\Date_Program\check_postgresql_runtime_env.ps1`
- `..\Date_Program\start_local_postgres.ps1`
- `..\Date_Program\run_verify.ps1`
- `lib/app/env.dart`
- `README.md`
- `AGENTS.md`

**Implementation direction**

- create a frontend-facing startup checklist or script that leaves the stack running
- add a tracked frontend `.env.example`
- make the “correct launch path” unmissable in docs

### 2. Backend password handling is implicit and easy to miss

**Type:** Code/config risk
**Severity:** P0

The backend database password is not simply “in config”; it is resolved from env/system properties.

**Why this matters**

A future agent can have Postgres running, correct DB URL, correct username, and still fail startup if `DATING_APP_DB_PASSWORD` is missing.

**Relevant files**

- `..\Date_Program\src\main\java\datingapp\storage\DatabaseManager.java`
- `..\Date_Program\check_postgresql_runtime_env.ps1`
- `..\Date_Program\config\app-config.json`

**Implementation direction**

- document config precedence explicitly
- make the startup script validate password presence earlier and more loudly

### 3. The REST server entrypoint is easy to start incorrectly

**Type:** Operational/documentation issue
**Severity:** P0

The CLI/Maven exec path and the mobile REST path are different. The backend repo still makes it easy to run the wrong thing.

**Relevant files**

- `..\Date_Program\pom.xml`
- `..\Date_Program\REST_LAN_STARTUP.md`
- `FLUTTER_PROJECT_HANDOFF.md`

**Implementation direction**

- consider adding a dedicated backend `start_rest_lan.ps1` script
- make frontend docs explicitly warn: do not use `mvn exec:exec` for Flutter/mobile API bring-up

### 4. The backend compile fix needs to exist on disk, not just in session memory

**Type:** Cross-repo fragility
**Severity:** P0

During this session, a real backend compile blocker was found in:

- `..\Date_Program\src\main\java\datingapp\app\api\RestApiRequestGuards.java`

The wrong `Context` import caused REST compile failures.

**Why this matters**

If that fix is not actually persisted in the backend repo state, future agents will hit the same startup failure again.

**Implementation direction**

- make sure the corrected import is committed/saved in the backend repo
- add a targeted backend test or compile check for the REST guard wiring

## Contract and data-shape fragility

### 5. `matchId` is effectively being treated as `conversationId`

**Type:** Contract coupling
**Severity:** P0

The frontend currently opens chat from matches by constructing a `ConversationSummary` using `matchId` as the conversation identifier.

**Why this matters**

This works only because the backend currently uses a deterministic paired-user ID scheme that aligns match and conversation identity closely enough. If the backend ever separates those concepts, the “message now” path breaks.

**Relevant files**

- `lib/features/browse/browse_screen.dart`
- `lib/features/matches/matches_screen.dart`
- `..\Date_Program\src\main\java\datingapp\app\api\RestApiIdentityPolicy.java`
- `..\Date_Program\src\main\java\datingapp\app\api\RestApiDtos.java`

**Implementation direction**

- either document this coupling explicitly as a stable contract
- or introduce a dedicated conversation ID handoff from the backend

### 6. Chat GET routes still depend on `X-User-Id`

**Type:** Hidden contract rule
**Severity:** P0

The backend requires user identity headers for message loading, even though it is a GET route.

**Why this matters**

A future “cleanup” that narrows header injection to mutating requests would silently break chat reads.

**Relevant files**

- `lib/api/api_headers.dart`
- `lib/api/api_client.dart`
- `..\Date_Program\src\main\java\datingapp\app\api\RestApiServer.java`

**Implementation direction**

- document this in code comments/tests
- add direct API tests for chat read header requirements

### 7. Achievements payload shape is non-obvious and easy to regress

**Type:** Confirmed runtime bug seam
**Severity:** P0

The backend returns achievements as a snapshot object containing `unlocked` and `newlyUnlocked`, not as a simple flat list.

This caused a real runtime issue in this session and required a parser fix in the frontend.

**Relevant files**

- `lib/api/api_client.dart`
- `lib/models/achievement_summary.dart`
- `test/api/api_client_test.dart`
- `..\Date_Program\src\main\java\datingapp\app\api\RestApiDtos.java`

**Implementation direction**

- keep dedicated regression coverage for this shape
- document the exact payload in a frontend-facing doc
- do not simplify the parser unless the backend contract changes formally

### 8. Browse and conversation DTOs are intentionally too thin for the intended product feel

**Type:** Product/contract limitation
**Severity:** P1

The current backend payloads for browse and conversation summaries are minimal.

**Practical impact**

- candidate cards feel sparse
- chats list lacks rich previews
- much of the UI looks like placeholders over thin transport DTOs

**Relevant files**

- `lib/features/browse/browse_screen.dart`
- `lib/features/chat/conversations_screen.dart`
- `lib/models/browse_candidate.dart`
- `lib/models/conversation_summary.dart`
- `FLUTTER_PROJECT_HANDOFF.md`

**Implementation direction**

- either enrich DTOs on the backend
- or explicitly design an MVP UI that feels intentional despite thin data

## Functional product gaps

### 9. Notifications are not implemented

**Type:** Missing feature
**Severity:** P1

The backend has notification endpoints, but there is no notifications screen, provider, or client wiring in the Flutter app.

**Why this matters**

Users currently have no dedicated place to see new events such as activity, which makes the experience feel incomplete.

### 10. Pending likers are not implemented

**Type:** Missing feature
**Severity:** P1

The backend supports pending likers, but the frontend has no screen or flow for it.

**Why this matters**

This is one of the most obvious discovery-adjacent features missing from a dating product.

### 11. Standouts are not implemented

**Type:** Missing feature
**Severity:** P2

There is no standouts screen or provider, even though the backend supports it.

### 12. Match quality is not implemented

**Type:** Missing feature
**Severity:** P2

The backend exposes match quality, but the frontend has no way to surface compatibility or quality insights.

### 13. Friend requests are not implemented

**Type:** Missing feature
**Severity:** P2

The backend supports friend request flows, but there is no UI or provider implementation for them.

### 14. Blocked-users management is incomplete

**Type:** Partial feature
**Severity:** P2

Block actions exist, but the blocked-users list and unblock flow are still incomplete in the normal UI.
**Why this matters**

Users can block, but cannot review or reverse that choice from normal UI.

### 15. Graceful exit and archive actions are missing

**Type:** Missing feature
**Severity:** P2

Relationship cleanup and organizational features are not surfaced in the mobile UI.

### 16. Verification flow is missing

**Type:** Missing feature
**Severity:** P2

The backend supports verification start/confirm, but the app has no verification flow.

### 17. Profile notes are missing

**Type:** Missing feature
**Severity:** P3

Private notes about users are not implemented in Flutter.

### 18. Location selection and resolution are missing

**Type:** Missing feature
**Severity:** P1

The backend supports countries, cities, and location resolution, but the mobile app cannot edit location using those APIs.

**Why this matters**

Location is core discovery data, yet the user cannot manage it properly from the mobile app.

### 19. Profile editing is still only partial

**Type:** Partial feature
**Severity:** P1

The current edit screen only covers a small subset of the backend write contract:

- bio
- gender
- interested in
- max distance

**Missing from UI**

- birth date
- min/max age preferences
- height
- smoking/drinking
- wants kids
- looking for
- education
- interests
- dealbreakers
- nested location selection

**Relevant files**

- `lib/features/profile/profile_edit_screen.dart`
- `lib/models/profile_update_request.dart`
- `FLUTTER_PROJECT_HANDOFF.md`

## UX and design issues

### 20. The app still feels like a dev build, not a dating product

**Type:** Confirmed screenshot/design issue
**Severity:** P1

The UI is coherent, but it does not yet feel productized. It still reads as “clean internal app with seeded Material 3” more than “distinctive dating experience.”

**What causes this feeling**

- mostly default Material patterns
- repetitive card-heavy layouts
- developer-facing copy in user-facing screens
- thin content hierarchy
- limited use of imagery and emotional cues

**Relevant files**

- `lib/theme/app_theme.dart`
- `lib/features/browse/browse_screen.dart`
- `lib/features/settings/settings_screen.dart`
- `lib/features/auth/dev_user_picker_screen.dart`

### 21. Discover is overloaded with meta UI above the main candidate

**Type:** Confirmed screenshot/flow issue
**Severity:** P1

The Discover screen currently leads with:

- backend health banner
- current user summary
- daily pick
- then the actual candidate card

**Why this is a problem**

The main user task is browsing a person, but that content is pushed down by infrastructure/dev/context chrome.

**Relevant file**

- `lib/features/browse/browse_screen.dart`

### 22. The main candidate card is too sparse and too developer-facing

**Type:** Confirmed screenshot/content issue
**Severity:** P1

The candidate card contains internal explanatory text:

> “The current browse payload is intentionally lean. More profile richness can come after the backend DTO grows.”

That is useful engineering context but bad product copy.

**Why this is a problem**

It breaks immersion instantly and tells the user they are inside a work-in-progress system.

**Relevant file**

- `lib/features/browse/browse_screen.dart`

### 23. Dev-user UI is too prominent in the live experience

**Type:** Product polish issue
**Severity:** P1

The app repeatedly foregrounds developer-specific identity state:

- “Choose a dev user”
- “Current dev user”
- “Browsing as ...”
- switch-user controls living prominently in Settings

**Why this is a problem**

For development this is practical, but it should be visually quarantined better so the app does not feel like a test harness.

**Relevant files**

- `lib/features/auth/dev_user_picker_screen.dart`
- `lib/features/browse/browse_screen.dart`
- `lib/features/settings/settings_screen.dart`

### 24. The theme is consistent but too generic

**Type:** Design-system issue
**Severity:** P2

`AppTheme` is tidy, but it is still just a seed-color theme with light structural tuning.

**Missing design-system depth**

- stronger typography decisions
- more distinctive button treatments
- navigation-specific tuning
- list density and spacing rules
- richer component hierarchy

**Relevant file**

- `lib/theme/app_theme.dart`

### 25. Loading states are visually weak and feel empty

**Type:** Confirmed screenshot/design issue
**Severity:** P1

The app relies heavily on centered hourglass/spinner/label loading states.

**Why this is a problem**

Large blank areas make slow loads feel broken instead of intentional.

**Relevant file**

- `lib/shared/widgets/app_async_state.dart`

**Implementation direction**

- use screen-shaped skeletons or contextual placeholders for key screens

### 26. Dev-picker loading/health treatment is confusing

**Type:** Screenshot/interaction issue
**Severity:** P2

During picker startup, backend health currently presents as a thin progress line before the proper status card appears. This can read like a broken divider or unexplained loading bar.

**Relevant files**

- `lib/features/auth/dev_user_picker_screen.dart`
- `lib/features/home/backend_health_banner.dart`

### 27. Settings mixes product settings, session controls, and insights awkwardly

**Type:** IA/design issue
**Severity:** P1

`Settings` currently includes:

- switch user
- stats
- achievements
- appearance settings

This makes the page feel part admin panel, part preferences page, part insights hub.

**Relevant file**

- `lib/features/settings/settings_screen.dart`

### 28. Stats and achievements are discoverable, but in the wrong place

**Type:** Information architecture issue
**Severity:** P2

Stats and achievements are not missing anymore, but their placement under Settings feels wrong for the product mental model.

They likely belong under Profile or a dedicated insights destination.

### 29. Profile layout is overly vertical and fragmented

**Type:** Confirmed screenshot/layout issue
**Severity:** P2

The profile view uses large stacked sections and large image blocks that can push core identity and preference information far apart.

**Why this is a problem**

It increases scroll burden and weakens profile readability.

**Relevant file**

- `lib/features/profile/profile_screen.dart`

### 30. Empty states are functional but generic

**Type:** UX issue
**Severity:** P2

Examples such as matches and other lists correctly handle emptiness, but they do not yet feel motivating or product-specific.

**Relevant files**

- `lib/features/matches/matches_screen.dart`
- `lib/features/chat/conversations_screen.dart`
- `lib/shared/widgets/app_async_state.dart`

## Accessibility issues

### 31. Theme mode selection relies too much on color state

**Type:** Accessibility issue
**Severity:** P2

The segmented theme selector uses color/background to indicate state and hides the selected icon.

**Relevant file**

- `lib/features/settings/settings_screen.dart`

**Why this matters**

This is weaker for low-vision and color-blind users.

### 32. Too many icon-only app bar actions

**Type:** Accessibility/discoverability issue
**Severity:** P2

Discover, matches, profile, chat, and achievements rely on several icon-only actions.

**Why this matters**

Even with tooltips, discoverability on touch devices is weaker than labeled or grouped controls.

### 33. Image semantics and rich accessibility treatment appear limited

**Type:** Accessibility issue
**Severity:** P3

Profile photo rendering does not obviously provide richer semantics or fallbacks.

**Relevant file**

- `lib/features/profile/profile_screen.dart`

### 34. Text contrast and hierarchy could be stronger in dark mode metadata areas

**Type:** Visual accessibility issue
**Severity:** P3

Dark mode looks attractive overall, but some supporting metadata reads as visually soft rather than confidently legible.

## Architecture and maintainability issues

### 35. Selected-user reactivity is the most important structural issue

**Type:** Code/architecture issue
**Severity:** P0

The selected-user guard resolves the current user with:

- `ref.read(selectedUserProvider.future)`

not a reactive dependency.

**Why this is a problem**

User-scoped providers can remain attached to stale data when switching from one valid user to another, because only `selectedUserProvider` is invalidated directly.

**Likely affected areas**

- browse
- matches
- conversations
- chat thread
- profile
- stats

**Relevant files**

- `lib/shared/providers/selected_user_guard.dart`
- `lib/features/auth/selected_user_provider.dart`
- `lib/features/browse/browse_provider.dart`
- `lib/features/matches/matches_provider.dart`
- `lib/features/chat/conversations_provider.dart`
- `lib/features/chat/conversation_thread_provider.dart`
- `lib/features/profile/profile_provider.dart`
- `lib/features/stats/stats_provider.dart`

**Implementation direction**

- make selected user a true reactive dependency for all user-scoped providers
- add tests that switch from user A to user B and verify data rebinding across tabs

### 36. `ApiClient` is growing into a monolith

**Type:** Maintainability issue
**Severity:** P2

`ApiClient` now owns health, auth/dev-user flows, browse, profile, safety, matches, conversations, messages, stats, achievements, and undo.

**Why this matters**

Every new feature pushes more unrelated behavior into one transport class.

**Relevant file**

- `lib/api/api_client.dart`

**Implementation direction**

- split transport by domain or capability once session/user scoping is stabilized

### 37. Header injection is stringly typed and path-rule fragile

**Type:** Maintainability/contract issue
**Severity:** P2

Header rules depend on path string matching/prefix checks.

**Why this matters**

A future route rename or endpoint addition can silently skip required headers.

**Relevant files**

- `lib/api/api_headers.dart`
- `lib/api/api_endpoints.dart`

### 38. Cache invalidation is manual and easy to miss

**Type:** Architecture issue
**Severity:** P1

Controllers manually invalidate related providers after mutations.

**Why this is a problem**

This works now, but it creates a web of hidden dependencies that will get harder to maintain as features grow.

**Relevant areas**

- browse like/pass/undo
- send message
- safety actions
- profile update

### 39. Navigation is fully imperative and scattered

**Type:** Architecture issue
**Severity:** P2

The app uses repeated `Navigator.push(MaterialPageRoute(...))` calls instead of a centralized route map.

**Why this matters**

This makes deep-linking, shared navigation behavior, and route auditing harder over time.

### 40. The shell likely preloads too much work

**Type:** Performance/architecture issue
**Severity:** P2

The signed-in shell uses an `IndexedStack` of top-level pages. Depending on provider usage, that can front-load multiple network-backed tabs before the user even visits them.

**Relevant file**

- `lib/features/home/signed_in_shell.dart`

### 41. Mutation state is split awkwardly between widgets and controllers

**Type:** Maintainability issue
**Severity:** P2

Local booleans like `_isSubmitting`, `_isSaving`, and `_isSending` live in widgets, while network logic and invalidation live in controllers/providers.

**Why this matters**

This makes advanced retry/optimistic UI/error-state work harder later.

### 42. There is no central media URL normalization layer

**Type:** Integration/maintainability issue
**Severity:** P2

Profile photos are rendered directly, but backend examples include relative paths.

**Why this matters**

Media handling will remain fragile until one place resolves backend photo URLs into display-ready URLs.

### 43. Image caching is missing

**Type:** Performance issue
**Severity:** P2

The app uses direct network images without a dedicated caching solution.

**Why this matters**

This is acceptable for a prototype, but not ideal for photo-heavy flows.

### 44. Chat refresh strategy is functional but not robust

**Type:** Resilience/performance issue
**Severity:** P2

The thread refresh loop is timer-based and lifecycle-aware, but it does not appear to back off after repeated failures or adapt to rate limiting.

**Relevant file**

- `lib/features/chat/conversation_thread_screen.dart`

### 45. Error handling is adequate but still shallow

**Type:** Resilience issue
**Severity:** P2

`ApiError` is useful, but the app still lacks richer behavior around:

- `429` handling
- `Retry-After`
- repeated failures
- explicit transient vs terminal classifications
- app-wide offline awareness

**Relevant files**

- `lib/api/api_error.dart`
- `lib/features/home/backend_health_banner.dart`

## Testing and documentation issues

### 46. `docs/2026-04-19-project-state-review.md` is stale and should not be trusted as-is

**Type:** Documentation issue
**Severity:** P0

This doc still reports broken tests, analyzer errors, and missing features that no longer reflect the current code.

**Why this matters**

A future agent could waste time “fixing” already fixed problems or miss the real issues entirely.

### 47. There is no true end-to-end integration test coverage

**Type:** Testing gap
**Severity:** P1

The widget/unit test suite is strong, but there is no real full-flow `integration_test` coverage for the core loop.

**Why this matters**

Cross-screen state, navigation, and backend interaction issues can still sneak through.

### 48. User-switching cache behavior is not tested deeply enough

**Type:** Testing gap
**Severity:** P0

This is the most important missing test scenario.

**Needed test behavior**

- start as user A
- load browse/matches/chats/profile/stats
- switch to user B
- verify all user-scoped data refreshes correctly

### 49. Some API contract edges remain under-tested directly

**Type:** Testing gap
**Severity:** P2

Examples:

- header behavior on chat GETs
- rate limiting / `429`
- relative image URLs
- backend shape drift on less-common endpoints

### 50. The frontend repo should have a tracked `.env.example`

**Type:** Documentation/dev-experience issue
**Severity:** P1

The app relies on `.env`, but a tracked starter template would reduce bring-up errors significantly.

## Recommended implementation order

### Workstream 1 — Stabilize runtime and source of truth

1. make sure the backend compile/import fix is persisted in `Date_Program`
2. add a frontend `.env.example`
3. update or archive stale docs, especially `docs/2026-04-19-project-state-review.md`
4. produce one concise startup checklist for full-stack mobile bring-up

### Workstream 2 — Fix user session reactivity and provider invalidation

1. make selected user a reactive dependency across user-scoped providers
2. add user-switching regression tests
3. audit invalidation behavior for all mutations

### Workstream 3 — Remove dev scaffolding from prime product surfaces

1. demote or hide backend health from top-of-Discover in normal flow
2. replace developer-facing copy with product-facing copy
3. reduce repeated dev-user identity chrome
4. isolate switch-user/admin concerns more cleanly

### Workstream 4 — Improve Discover and core UX

1. make candidate content visually primary
2. reduce above-the-fold meta cards
3. redesign loading and empty states
4. strengthen theming beyond a seed-color setup
5. improve profile readability and card hierarchy

### Workstream 5 — Fill high-value functional gaps

1. notifications
2. pending likers
3. blocked-users management + unblock UI
4. location selection flow
5. richer profile editing

### Workstream 6 — Hardening and scale-up

1. split `ApiClient` by domain
2. improve rate-limit awareness and chat retry/backoff
3. introduce pagination and image caching
4. consider centralized routing
5. improve accessibility and semantics

## Context map for future agents

### Frontend files most relevant to the main issues

| File                                                | Why it matters                                            |
|-----------------------------------------------------|-----------------------------------------------------------|
| `lib/shared/providers/selected_user_guard.dart`     | current stale-cache / user-reactivity hinge point         |
| `lib/features/auth/selected_user_provider.dart`     | selected-user storage and invalidation entrypoint         |
| `lib/features/browse/browse_screen.dart`            | Discover layout, dev-facing copy, main product experience |
| `lib/features/browse/browse_provider.dart`          | browse mutations and invalidation behavior                |
| `lib/features/home/backend_health_banner.dart`      | infrastructure UI leaking into the main flow              |
| `lib/features/home/signed_in_shell.dart`            | tab structure and eager page composition                  |
| `lib/features/settings/settings_screen.dart`        | IA issues around dev user + insights + appearance         |
| `lib/features/profile/profile_screen.dart`          | profile layout/readability issues                         |
| `lib/features/profile/profile_edit_screen.dart`     | partial edit surface                                      |
| `lib/features/chat/conversation_thread_screen.dart` | polling, send flow, auto-scroll, chat UX                  |
| `lib/api/api_client.dart`                           | transport monolith and contract parsing                   |
| `lib/api/api_headers.dart`                          | fragile header rules                                      |
| `lib/api/api_error.dart`                            | resilience and error-surface limitations                  |
| `lib/shared/widgets/app_async_state.dart`           | weak loading/empty/error presentation                     |
| `lib/theme/app_theme.dart`                          | generic but clean current design system                   |

### Backend files most relevant to integration risks

| File                                                                         | Why it matters                                            |
|------------------------------------------------------------------------------|-----------------------------------------------------------|
| `..\Date_Program\REST_LAN_STARTUP.md`                                        | correct mobile/LAN startup path                           |
| `..\Date_Program\README.md`                                                  | main repo startup/verification instructions               |
| `..\Date_Program\config\app-config.json`                                     | runtime DB defaults                                       |
| `..\Date_Program\src\main\java\datingapp\storage\DatabaseManager.java`       | DB password/env resolution                                |
| `..\Date_Program\src\main\java\datingapp\app\api\RestApiServer.java`         | transport startup and route behavior                      |
| `..\Date_Program\src\main\java\datingapp\app\api\RestApiRequestGuards.java`  | rate limiting / request guards / compile-sensitive import |
| `..\Date_Program\src\main\java\datingapp\app\api\RestApiDtos.java`           | actual response payload shapes                            |
| `..\Date_Program\src\main\java\datingapp\app\api\RestApiIdentityPolicy.java` | conversation identity rules                               |

## Final takeaways

1. The app is **not empty**. It has a real functional spine.
2. The biggest remaining problems are **quality-of-product** and **quality-of-foundation**, not mere absence of screens.
3. The most dangerous mistake a future agent could make is building many new features before fixing **selected-user reactivity**, **runtime/documentation clarity**, and **core UX polish**.
4. The most valuable short-term win is to make the app feel less like a dev harness and more like a real dating product while stabilizing the state model underneath.
