Status: pending design-language refresh

Target file: `lib/features/location/location_completion_screen.dart`

You are a Flutter frontend coding engineer. Redesign the Location Completion
screen to match `docs/design-language.md`, using the run-0070 reference
screenshots as the taste target:

- `design-reference/stats-run-0070-reference.png`
- `design-reference/notifications-run-0070-reference.png`
- `design-reference/notifications-dark-run-0070-reference.png`

## Non-Negotiables

- Read `docs/design-language.md` before editing this screen.
- This is a pushed editor/utility route. Keep a compact visible route title and
  back affordance through the AppBar.
- Do not change providers, models, API calls, save behavior, city search
  behavior, validation, country/city request construction, or navigation
  contracts.
- Do not invent location precision, geocoding certainty, or backend-owned match
  behavior.
- Do not add new tests for this UI/design pass. You may run existing useful
  tests, `flutter analyze`, and the visual-review suite.

## Design Direction

Location completion is a calm form/editing screen. It should remain softer and
quieter than Stats or Achievements, but still expressive through pastel chips,
semantic confirmation, and organized grouped surfaces.

## Required Outcome

- Top chrome is useful: compact AppBar with back affordance and title
  `Location`.
- First viewport should show the actual form quickly. Avoid a large duplicate
  intro.
- Use one compact intro/form card for country, city, optional zip, approximate
  match toggle, and save CTA.
- Group suggested cities in a second soft-tinted section with compact list rows,
  decorated place icons, city/district text, and quiet chevrons.
- Selected city confirmation should be a soft semantic confirmation surface, not
  a second CTA-like color block.
- Save button should have a clear busy state and remain the only dominant CTA.
- Country flag placeholder may remain generic if no real assets exist, but it
  should be styled as a deliberate chip.
- Empty, hint, loading, and error states inside suggestions should use
  decorated icons and concise practical copy.

## Completion

Run `flutter analyze` and, when feasible, `flutter test
test/visual_inspection/screenshot_test.dart`. Inspect the generated
`location_completion__run-*.png` against the run-0070 references and the visual
checklist in `docs/design-language.md`.

Only after this screen is fully implemented and visually checked, edit this
prompt file and add this as the first line:

`implemented`
