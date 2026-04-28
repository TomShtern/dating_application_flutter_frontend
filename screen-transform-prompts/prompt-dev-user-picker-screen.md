Status: pending design-language refresh

Target file: `lib/features/auth/dev_user_picker_screen.dart`

You are a Flutter frontend coding engineer. Redesign the Dev User Picker
screen to match `docs/design-language.md`, using the run-0070 reference
screenshots as the taste target:

- `design-reference/stats-run-0070-reference.png`
- `design-reference/notifications-run-0070-reference.png`
- `design-reference/notifications-dark-run-0070-reference.png`

## Non-Negotiables

- Read `docs/design-language.md` before editing this screen.
- This is a root/dev entry screen when no user is selected. It does not need a
  back affordance, but it still needs useful screen context and polished top
  spacing.
- Keep the amber developer-only framing. It is deliberate internal-tooling
  chrome.
- Do not change providers, user selection behavior, persistence behavior,
  backend health behavior, snackbar behavior, or navigation contracts.
- Do not invent user metadata or backend session details not present in the
  model/API.
- Do not add new tests for this UI/design pass. You may run existing useful
  tests, `flutter analyze`, and the visual-review suite.

## Design Direction

This is a utility/dev-only screen. It should be compact, clear, and polished,
with softer pastel product styling around the intentionally amber dev callout.
It should not feel like a raw admin table.

## Required Outcome

- First viewport should quickly show: development sign-in context, backend
  health, current selected-user state, and the first available profiles.
- Avoid a duplicated AppBar title if the dev callout already provides the
  screen title. Do not leave invisible default-height chrome unless it serves
  status-bar/safe-area needs.
- Use soft tinted cards and decorated avatars/icon chips for current user and
  available user rows.
- Selected user state should be obvious through semantic tint, border/accent,
  and a compact `Current` pill.
- Unselected rows should remain soft and intentional, not plain white or hard
  outlined.
- Use real user names/photos/avatars only from existing data. Do not invent
  last-seen or profile details.
- Empty state should mention seeded dev users/backend health in a practical
  way.
- Keep all tap targets implemented with Material/InkWell or existing Material
  controls.

## Completion

Run `flutter analyze` and, when feasible, `flutter test
test/visual_inspection/screenshot_test.dart`. Inspect the generated
`app_home_startup__run-*.png` against the run-0070 references and the visual
checklist in `docs/design-language.md`.

Only after this screen is fully implemented and visually checked, edit this
prompt file and add this as the first line:

`implemented`
