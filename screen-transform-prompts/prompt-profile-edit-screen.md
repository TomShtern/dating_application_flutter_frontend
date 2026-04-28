Status: pending design-language refresh

Target file: `lib/features/profile/profile_edit_screen.dart`

You are a Flutter frontend coding engineer. Redesign the Profile Edit screen to
match `docs/design-language.md`, using the run-0070 reference screenshots as
the taste target:

- `design-reference/stats-run-0070-reference.png`
- `design-reference/notifications-run-0070-reference.png`
- `design-reference/notifications-dark-run-0070-reference.png`

## Non-Negotiables

- Read `docs/design-language.md` before editing this screen.
- This is a pushed editor route. Keep a compact visible route title and back
  affordance through the AppBar.
- Do not change providers, models, API calls, validation rules, save behavior,
  request construction, slider semantics, or location navigation.
- Do not invent profile fields, matching logic, or backend-owned preference
  behavior.
- Do not add new tests for this UI/design pass. You may run existing useful
  tests, `flutter analyze`, and the visual-review suite.

## Design Direction

Profile editing is a calmer form screen. It should still feel like the same
playful pastel product, but with muted accents, strong grouping, and a clear
save path rather than feed-like color density.

## Required Outcome

- Top chrome is useful: compact AppBar with back affordance and title
  `Edit profile`.
- The header below the AppBar should be compact and should show current user
  identity/readiness without duplicating the route title.
- Form sections use soft tinted cards, decorated section icons, clear titles,
  concise descriptions, and consistent internal rhythm.
- Use semantic colors for field categories where useful: profile/identity blue
  or lavender, location blue/green, preferences violet/rose, validation
  serious but soft.
- Sticky save bar should be visually anchored, compact, and clearly primary,
  with a proper busy state.
- Avoid cards inside cards where simple grouping would be clearer.
- Keep fields dense enough that the first viewport reaches real inputs quickly.
- Empty/default field copy should guide without nagging.

## Completion

Run `flutter analyze` and, when feasible, `flutter test
test/visual_inspection/screenshot_test.dart`. Inspect the generated
`profile_edit__run-*.png` against the run-0070 references and the visual
checklist in `docs/design-language.md`.

Only after this screen is fully implemented and visually checked, edit this
prompt file and add this as the first line:

`implemented`
