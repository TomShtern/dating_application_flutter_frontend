Status: pending design-language refresh

Target file: `lib/features/browse/standouts_screen.dart`

You are a Flutter frontend coding engineer. Redesign the Standouts screen to
match `docs/design-language.md`, using the run-0070 reference screenshots as
the taste target:

- `design-reference/stats-run-0070-reference.png`
- `design-reference/notifications-run-0070-reference.png`
- `design-reference/notifications-dark-run-0070-reference.png`

## Non-Negotiables

- Read `docs/design-language.md` before editing this screen.
- This is a pushed secondary route from Discover. Keep a compact visible route
  title and back affordance through the AppBar.
- Do not change providers, models, API calls, view-mode logic, profile
  navigation, refresh behavior, ranking helpers, or reason/freshness helpers.
- Do not invent standout reasons, ranking logic, compatibility, or premium
  claims not present in the API/model.
- Every visible view toggle/filter must work.
- Do not add new tests for this UI/design pass. You may run existing useful
  tests, `flutter analyze`, and the visual-review suite.

## Design Direction

Standouts is a people/social screen with milestone/highlight energy. Use amber
and violet as the highlight language, with people and real media still central.
It should feel special, not generic, but it must stay compact and truthful.

## Required Outcome

- AppBar provides route context: back affordance, title `Standouts`, and compact
  refresh/action affordance if already present.
- First viewport should show a useful standout summary and reach real standout
  cards quickly. Avoid a ShellHero buried inside a padded scroll.
- Use portrait media thumbnails for standout people when available; do not use
  circular thumbnails where the design calls for media presence.
- Cards use soft tinted surfaces, amber/violet semantic accents, decorated rank
  chips, reason/freshness chips, and one clear profile action.
- Rank 1 or special standout may receive stronger treatment, but reserve full
  gradients for the top/special moment rather than every card.
- Grid and list modes should share the same visual grammar and not feel like
  two different themes.
- Empty state should be polished and should not imply hidden ranking logic.

## Completion

Run `flutter analyze` and, when feasible, `flutter test
test/visual_inspection/screenshot_test.dart`. Inspect the generated
`standouts__run-*.png` against the run-0070 references and the visual checklist
in `docs/design-language.md`.

Only after this screen is fully implemented and visually checked, edit this
prompt file and add this as the first line:

`implemented`
