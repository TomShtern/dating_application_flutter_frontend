# Project Guidelines

## Read first
- Start with `CLAUDE.md` for the shortest command, architecture, navigation, and testing reference.
- Read `docs/design-language.md` before changing UI, shared widgets, screen structure, colours, spacing, or `AppTheme` helpers.
- Use `FLUTTER_FRONTEND_AGENT_GUIDE.md` and `FLUTTER_PROJECT_HANDOFF.md` when work touches backend contract details or startup assumptions.
- Use `docs/visual-review-workflow.md` for the screenshot workflow.
- If a task changes UI direction or richer profile surfaces, also review the relevant docs in `docs/superpowers/specs/` and `docs/` before making broader design assumptions.

## Architecture
- This repo is a **thin Flutter client** for a separate Java backend.
- Flutter owns UI, navigation, local state, request orchestration, and presentation.
- The backend owns business rules, matching logic, moderation, verification, location resolution, stats, achievements, persistence, and other source-of-truth behavior.
- **Do not reimplement backend-owned product logic in Dart.** If the UI needs richer data, call out the backend contract gap instead of inventing compatibility scores, match reasons, moderation state, or other hidden client logic.
- Keep API concerns centralized in `lib/api/**`. Do not add `X-DatingApp-Shared-Secret` or `X-User-Id` headers ad hoc in feature or screen code.
- Use Riverpod patterns consistently: `FutureProvider` for async reads, `NotifierProvider` for mutable app state, and `Provider` for DI/controllers.
- Keep side effects in providers/controllers, not in widget `build` methods.
- Providers that require an acting user should go through `lib/shared/providers/selected_user_guard.dart`.
- Preserve selected dev-user behavior between launches.
- Keep widgets mostly declarative and follow the existing feature layout under `lib/features/<feature>/`.

## UI and product conventions
- Prefer the shared widgets when they fit: `ShellHero`, `SectionIntroCard`, `AppAsyncState`, and shared avatar/media helpers.
- Treat `docs/design-language.md` as the source of truth for hero choice, screen archetypes, semantic colours, spacing/radius tokens, surfaces, typography emphasis, and interaction patterns.
- Use `AppTheme` tokens and helpers instead of inline spacing, border-radius, shadow, or decoration values when an existing token covers the case.
- Use `Material` + `InkWell` for tappable surfaces; do not default to raw `GestureDetector` for card and tile interactions.
- No router package is used; follow the existing imperative navigation pattern and the signed-in shell structure.
- The app is Android-first and uses a dev-user picker instead of real auth.
- Keep developer-only controls visually separated and clearly labeled.
- Favor compact, people-first dating surfaces instead of generic admin-style screens.
- Avoid ambiguous safety affordances when contextual menus are clearer.

## API and environment gotchas
- Runtime config comes from Dart defines in `lib/app/env.dart` / `lib/app/app_config.dart`.
- Local `.env` values are **not** auto-loaded by Flutter; pass them explicitly with `--dart-define-from-file=.env` when needed.
- Android emulator backend access should use `http://10.0.2.2:7070`.
- Use the existing backend contract: browse is `/api/users/{id}/browse`, and chat is conversation-scoped under `/api/conversations/{conversationId}/messages`.
- Do not invent user-scoped chat message routes, fake auth flows, WebSocket chat, or offline-first sync behavior that does not exist in this repo.

## Build and test

- Common commands:
  - `flutter pub get`
  - `flutter analyze`
  - `flutter test`
  - `flutter test test/visual_inspection/screenshot_test.dart`
- After Dart/code changes, run `flutter analyze` and the **smallest relevant** test target when feasible.
- After UI changes, prefer the screenshot workflow in `docs/visual-review-workflow.md` and inspect `visual_review/latest/index.html`.
- Judge UI changes against `docs/design-language.md` during screenshot review rather than relying only on widget assertions.
- Do not claim something is fully fixed or end-to-end verified unless you actually exercised the path needed for that claim.

### No new tests during active frontend work

**Do not create widget tests, regression tests, or integration tests when the task involves frontend UI, design, visual polish, or layout changes.** The default is: no new tests. This policy is not optional and not a suggestion.

- Frontend tests are appropriate only when the UI is finalized and the user explicitly asks for tests. "In-progress" or "active iteration" on any screen, component, or visual feature means the UI is not finalized.
- If existing tests break because of a refactor, fix the broken tests — but do not add new ones.
- For visual quality assurance during frontend work, use the screenshot workflow (`flutter test test/visual_inspection/screenshot_test.dart`) and inspect the output. Do not substitute widget assertions for visual review.
- Non-frontend work (providers, models, API contracts, state logic) follows normal testing judgment.

## Working style
- Prefer small, focused changes over broad rewrites.
- Respect existing code structure and current docs instead of older assumptions.
- If a task requires backend changes, say so explicitly rather than papering over the gap in Flutter.
- Do not modify secrets or clean generated artifacts unless the user explicitly asks.
