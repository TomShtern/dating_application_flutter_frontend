Status: pending reference-maintenance refresh

Target file: `lib/features/notifications/notifications_screen.dart`

You are a Flutter frontend coding engineer. Maintain and refine the
Notifications screen against `docs/design-language.md`, using the run-0070
reference screenshots as the taste target:

- `design-reference/stats-run-0070-reference.png`
- `design-reference/notifications-run-0070-reference.png`
- `design-reference/notifications-dark-run-0070-reference.png`

## Non-Negotiables

- Read `docs/design-language.md` before editing this screen.
- This screen is one of the canonical visual references. Do not redesign it
  from scratch unless the current implementation has visibly drifted.
- When opened as a pushed secondary route, it must provide route context through
  a compact AppBar/back affordance/title or equivalent. Standalone visual tests
  may not show the back arrow because they do not have a parent route.
- Do not change providers, models, API calls, mark-read behavior, route handling,
  refresh behavior, or date grouping logic.
- Unknown notification types must stay display-only unless payloads are known
  and complete enough for safe routing.
- Do not add new tests for this UI/design pass. You may run existing useful
  tests, `flutter analyze`, and the visual-review suite.

## Design Direction

Notifications defines the feed/status side of the design language: compact,
colorful, semantic, readable, and soft. Preserve its run-0070 strengths:
per-item semantic colors, decorated icons, compact grouping, and dark-mode
personality.

## Required Outcome

- Keep the intro compact and useful: title/context, unread/total state, filter
  or read-all action, and refresh where appropriate.
- Preserve semantic notification hues: match/violet, message/teal, trust/green,
  response/amber, likes/rose/coral, fallback slate/sky.
- Read/inactive notification rows should still keep very light semantic tint.
  Color is not only for unread state.
- Each row should have one clear trailing affordance: mark read, chevron, check,
  overflow, or nothing. Avoid crowded right edges.
- Keep section labels for time/status groups using the design-language pattern.
- Avoid one-color rose/mauve sameness and avoid plain white unfinished rows.
- Dark mode must keep similar hues, softened for dark surfaces.
- Empty state should feel designed and should respect the active filter.

## Completion

Run `flutter analyze` and, when feasible, `flutter test
test/visual_inspection/screenshot_test.dart`. Inspect `notifications__run-*.png`
and `notifications_dark__run-*.png` against the run-0070 reference files and
the visual checklist in `docs/design-language.md`.

Only after this screen is fully implemented and visually checked, edit this
prompt file and add this as the first line:

`implemented`
