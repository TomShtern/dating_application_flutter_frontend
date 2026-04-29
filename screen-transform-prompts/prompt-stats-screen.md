✅ implemented

Status: pending reference-maintenance refresh

Target file: `lib/features/stats/stats_screen.dart`

You are a Flutter frontend coding engineer. Maintain and refine the Stats
screen against `docs/design-language.md`, using the run-0070 reference
screenshots as the taste target:

- `design-reference/stats-run-0070-reference.png`
- `design-reference/notifications-run-0070-reference.png`
- `design-reference/notifications-dark-run-0070-reference.png`

## Non-Negotiables

- Read `docs/design-language.md` before editing this screen.
- This screen is one of the canonical visual references. Do not redesign it
  from scratch unless the current implementation has visibly drifted.
- This is a pushed secondary route. Keep a compact visible route title and
  back affordance through the AppBar.
- Do not change providers, models, API calls, refresh behavior, achievements
  navigation, stat detail sheet behavior, animations, or parsing helpers.
- Do not invent stats, metrics, achievement meanings, or backend-owned business
  logic.
- Do not add new tests for this UI/design pass. You may run existing useful
  tests, `flutter analyze`, and the visual-review suite.

## Design Direction

Stats defines the data/status side of the design language: colorful, compact,
semantic, and premium. Preserve its run-0070 strengths: compact route chrome,
pastel gradient summary, semantic metric tiles, section labels, tinted cards,
and useful first-viewport density.

## Required Outcome

- AppBar is compact and useful: back affordance, title `Stats`, achievements
  action, and refresh action.
- Summary card remains the data hero. Do not put a blank `ShellHero` above it.
- First viewport should show the route title and meaningful stats immediately;
  keep top dead space minimal.
- Metric colors should follow the semantic map: likes/rose-coral, response
  amber, views/sky, activity/mint/green, milestones violet/amber.
- Snapshot/performance cards use the surface layer recipe: soft tinted surface,
  semantic accent, decorated icon chip, value/label, and compact detail signal.
- Section labels should remain compact and strong.
- Full gradients/color blocks are reserved for the summary or special data
  moment, not every metric card.
- Empty state should explain when stats begin to populate.

## Completion

Run `flutter analyze` and, when feasible, `flutter test
test/visual_inspection/screenshot_test.dart`. Inspect `stats__run-*.png`
against `design-reference/stats-run-0070-reference.png` and the visual
checklist in `docs/design-language.md`.

Only after this screen is fully implemented and visually checked, edit this
prompt file and add this as the first line:

`implemented`
