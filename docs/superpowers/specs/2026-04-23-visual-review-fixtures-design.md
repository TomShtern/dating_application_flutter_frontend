# Visual review fixtures design

Date: 2026-04-23

## Purpose

Improve the visual review workflow by replacing the current minimal inline screenshot data with a reusable, richer fixture system that supports:

- more realistic screenshot scenarios
- better density for list and detail screens
- reuse across widget and provider tests where it is clearly beneficial
- thinner, easier-to-maintain screenshot test files

## Problem

The current screenshot suite in `test/visual_inspection/screenshot_test.dart` already uses deterministic fake data, but most screens are seeded with only one or two records. That creates screenshots that prove a screen renders, yet often fail to show what the UI looks like under believable use.

Examples of current limitations:

- `Discover` shows only one candidate
- `Matches` shows one match
- `Chats` shows one conversation
- `Conversation thread` shows two messages
- `Blocked users` shows one row
- `Notifications` shows two items
- `Achievements` shows only two achievements

This leads to visual review artifacts that are too sparse to evaluate rhythm, list density, hierarchy under repetition, long-scroll behavior, and realistic content variation.

## Goals

1. Create a reusable fixture layer for visual review data.
2. Refactor screenshot tests so they consume named scenarios rather than large inline data blocks.
3. Enrich screenshot scenarios so the captured screens reflect realistic app use.
4. Make the same fixtures reusable in selected feature tests where richer data improves coverage or readability.
5. Keep all data deterministic, local to tests, and independent of backend seeding.

## Non-goals

- Do not seed the real backend or local development database.
- Do not add random or time-dependent fixture generation.
- Do not modify production DTOs solely to make test fixture creation easier.
- Do not convert the fixture layer into a generic testing framework.
- Do not expand screenshot coverage to unrelated new screens during this change unless needed for consistency.

## Constraints

- The app is a thin client; business logic remains owned by the backend.
- Visual review artifacts must remain deterministic and repeatable.
- The screenshot workflow must continue to use the fixed `412 x 915` viewport.
- Existing visual review output structure and capture infrastructure must remain intact.
- Test fixtures must live in `test/`, not `lib/`.

## Proposed design

### 1. Introduce a dedicated visual fixture layer

Create a focused fixture area under `test/visual_inspection/fixtures/`.

Planned files:

- `test/visual_inspection/fixtures/visual_fixture_catalog.dart`
  - canonical rich test entities and reusable records
- `test/visual_inspection/fixtures/visual_fixture_builders.dart`
  - lightweight test-only builders/helpers for DTO construction
- `test/visual_inspection/fixtures/visual_scenarios.dart`
  - named scenario bundles used by screenshot tests

This splits the current monolithic inline setup into three clear responsibilities:

- base entities
- composition helpers
- screen-ready scenario groupings

### 2. Keep builders test-only and lightweight

Most DTOs do not provide `copyWith()`. Rather than changing production models for test ergonomics, introduce small builder helpers in `test/`.

These builders should:

- create readable variants without reconstructing every field manually
- support stable overrides for names, timestamps, counts, statuses, and message content
- stay intentionally small and DTO-specific

Examples of builder targets:

- `UserSummary`
- `UserDetail`
- `BrowseCandidate`
- `MatchSummary`
- `ConversationSummary`
- `MessageDto`
- `PendingLiker`
- `NotificationItem`
- `AchievementSummary`
- `BlockedUserSummary`

The builders must not become abstract factories or a deeply nested DSL. They should remain readable enough that someone can understand a scenario without studying helper internals.

### 3. Move screenshot tests to scenario-driven setup

Refactor `test/visual_inspection/screenshot_test.dart` so each screen consumes a named scenario instead of defining raw inline data.

Examples:

- `denseDiscoverScenario`
- `busyMatchesScenario`
- `busyChatsScenario`
- `richConversationScenario`
- `crowdedNotificationsScenario`
- `fullAchievementsScenario`

Each scenario should expose only what the screen needs:

- provider override values
- the selected current user
- any route/widget parameters
- screen-specific seeded collections

This will make the screenshot harness easier to read and will centralize fixture evolution.

### 4. Increase density to realistic review states

The default visual review scenarios should favor “busy but believable” states.

Target density by screen:

- `Discover`
  - multiple browse candidates available through the response model
  - one strong daily pick
  - visible variation in candidate metadata
- `Matches`
  - 4 to 6 matches
- `Chats`
  - 4 to 6 conversations with different preview lengths and recency
- `Conversation thread`
  - 8 to 14 messages across at least two day groupings
- `Standouts`
  - 4 to 5 standouts with varied reasons and ranks
- `People who liked you`
  - 4 to 6 pending likers
- `Blocked users`
  - 3 to 5 blocked-user rows
- `Notifications`
  - 6 to 8 items across multiple notification types and read states
- `Stats`
  - a fuller set of stat items with varied values
- `Achievements`
  - a richer mix of unlocked and in-progress achievements
- profile-oriented screens
  - richer but still plausible photos, bios, sections, and supporting content where supported by the model

The goal is not volume for its own sake. The goal is enough content to evaluate hierarchy, rhythm, repetition, and real-use composition.

### 5. Reuse fixtures selectively in other tests

After the fixture layer exists, reuse it only where it clearly improves tests.

Likely candidates:

- widget tests for list-heavy screens
- provider tests that benefit from realistic sequences or fuller collections
- visual assertions that should share the same seeded data language

Reuse should be selective, not mandatory. If a small local inline fixture is clearer in a feature test, it should remain local.

## File-level plan

### New files

- `test/visual_inspection/fixtures/visual_fixture_catalog.dart`
- `test/visual_inspection/fixtures/visual_fixture_builders.dart`
- `test/visual_inspection/fixtures/visual_scenarios.dart`

### Updated files

- `test/visual_inspection/screenshot_test.dart`
- selected files under `test/features/**` where fixture reuse is clearly beneficial
- possibly `docs/visual-review-workflow.md` if the new fixture/scenario structure should be documented for future contributors

## Scenario design rules

1. Use fixed IDs and timestamps.
2. Use realistic but compact text lengths.
3. Avoid joke/test-only placeholder copy that would distort the visual read.
4. Keep names, ages, and content varied enough to reveal repetition issues.
5. Keep the selected current user stable unless a specific scenario requires otherwise.
6. Prefer one canonical “rich default” scenario per screen over many near-duplicates.
7. Preserve deterministic ordering in all lists.

## Testing strategy

### Red-green workflow

Before refactoring screenshot setup, add or adjust targeted tests to assert the intended scenario structure where practical.

Examples:

- screenshot harness still pumps successfully using the new scenario layer
- key visual-review scenarios expose the expected number of seeded items
- any migrated feature tests still pass using shared fixtures

### Verification commands

After implementation:

- `flutter analyze`
- `flutter test`
- `flutter test test/visual_inspection/screenshot_test.dart`

Then inspect the fresh visual output in `visual_review/latest/`.

## Risks

### Risk: fixture system becomes over-engineered

Mitigation:
- keep only a few files
- use DTO-specific helpers, not a generic framework
- prefer explicit scenario naming over clever abstraction

### Risk: screenshots become unrealistic in a different way

Mitigation:
- use believable product data rather than exaggerated extreme states
- review the seeded copy and counts screen by screen

### Risk: fixture reuse hurts readability in feature tests

Mitigation:
- reuse only where it improves clarity or reduces duplication materially
- allow local fixtures to remain where they are still simpler

## Success criteria

This work is successful when:

1. `screenshot_test.dart` is materially thinner and easier to scan.
2. The visual review screenshots show fuller, more realistic screen occupancy.
3. Dense list screens and conversation screens better reflect real use.
4. Shared fixtures are reused in at least a small number of high-value feature tests.
5. Analyzer, full tests, and the screenshot suite all pass.

## Recommended execution split for sub-agents

### Sub-agent 1: fixture architecture

Responsibilities:
- create fixture catalog, builders, and scenarios files
- migrate existing inline screenshot data into the new structure
- keep scenarios deterministic and readable

### Sub-agent 2: scenario enrichment

Responsibilities:
- expand the seeded data screen by screen
- tune list density and message volume for realistic visual review
- keep copy believable and varied

### Sub-agent 3: integration and verification

Responsibilities:
- refactor screenshot test usage onto the scenario layer
- reuse shared fixtures in selected high-value feature tests
- run verification and summarize any follow-up fixes needed

## Bottom line

A test-only visual fixture system with reusable builders and named screen scenarios should be implemented. This keeps screenshot review deterministic, makes the screenshot harness easier to maintain, and improves the realism of visual review artifacts without introducing backend seeding or production-only demo data.
