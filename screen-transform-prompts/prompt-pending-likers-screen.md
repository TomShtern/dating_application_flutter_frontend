✅ implemented

Status: pending design-language refresh

Target file: `lib/features/browse/pending_likers_screen.dart`

You are a Flutter frontend coding engineer. Redesign the Pending Likers screen
to match `docs/design-language.md`, using the run-0070 reference screenshots
as the taste target:

- `design-reference/stats-run-0070-reference.png`
- `design-reference/notifications-run-0070-reference.png`
- `design-reference/notifications-dark-run-0070-reference.png`

## Non-Negotiables

- Read `docs/design-language.md` before editing this screen.
- This is a pushed secondary route from Discover/Settings context. Keep a
  compact visible route title and back affordance through the AppBar.
- Do not change providers, models, API calls, profile navigation, safety action
  behavior, refresh behavior, or date formatting helpers.
- Do not invent who-liked-you reasons, compatibility, ranking, or safety
  metadata not present in the model/API.
- Do not add new tests for this UI/design pass. You may run existing useful
  tests, `flutter analyze`, and the visual-review suite.

## Design Direction

Pending Likers is a people/social screen with affinity energy. Use rose/coral
for received likes, violet for match potential, and compact people signals.
It should be colorful and warm, but not a one-color pink screen.

## Required Outcome

- AppBar provides route context: back affordance, title such as `Likes you`, and
  any existing refresh action in compact form.
- First viewport should show a useful count/state quickly, then real liker rows.
  Avoid putting a large ShellHero inside a padded scroll.
- Use person/social card anatomy: real photo or polished avatar, name, location
  when available, liked-at timing, safety/context action, and one clear profile
  affordance.
- Use soft tinted card surfaces with semantic rose/coral accents and decorated
  icon chips.
- Use functional compact metadata chips/strips; avoid custom duplicated rows
  when shared widgets already fit.
- Safety actions should remain quiet and deliberate, not louder than profile
  exploration.
- Empty state should be warm and clear without inventing interest.

## Completion

Run `flutter analyze` and, when feasible, `flutter test
test/visual_inspection/screenshot_test.dart`. Inspect the generated
`pending_likers__run-*.png` against the run-0070 references and the visual
checklist in `docs/design-language.md`.

Only after this screen is fully implemented and visually checked, edit this
prompt file and add this as the first line:

`implemented`
