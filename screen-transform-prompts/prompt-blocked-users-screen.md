✅ implemented

Status: pending design-language refresh

Target file: `lib/features/safety/blocked_users_screen.dart`

You are a Flutter frontend coding engineer. Redesign the Blocked Users screen
to match `docs/design-language.md`, using the run-0070 reference screenshots
as the taste target:

- `design-reference/stats-run-0070-reference.png`
- `design-reference/notifications-run-0070-reference.png`
- `design-reference/notifications-dark-run-0070-reference.png`

## Non-Negotiables

- Read `docs/design-language.md` before editing this screen.
- This is a pushed secondary route. Keep a compact visible route title and
  back affordance through the AppBar.
- Do not change providers, models, API calls, unblock confirmation behavior,
  snackbar behavior, or safety action logic.
- Do not invent block reasons, dates, moderation labels, risk levels, or
  backend-owned safety metadata.
- Do not add new tests for this UI/design pass. You may run existing useful
  tests, `flutter analyze`, and the visual-review suite.

## Design Direction

This is a safety/moderation screen. It should feel serious, clear, and soft:
not harsh red-heavy, not playful, and not sterile. Use muted rose/coral/slate
with small trust-green only for safe/confirmed outcomes.

## Required Outcome

- Top chrome is useful: compact AppBar with back affordance and title
  `Blocked users`.
- Intro area is compact and practical, with a clear count/state. Avoid a large
  empty header.
- Use a section label above the list, such as `Blocked profiles`, so the list
  does not feel dropped onto the page.
- Blocked rows use semantic list-tile anatomy: soft tinted card, serious icon
  chip, title, short supporting text, and quiet trailing overflow action.
- Keep unblock behind the row overflow/menu and confirmation dialog unless the
  existing UX already makes it clearly deliberate.
- Make overflow tooltips specific, for example `Blocked user options` or
  `Manage block`.
- Empty state should explain that blocked profiles will appear here and should
  include a decorated safety icon.
- Avoid generic undecorated icons and plain white unfinished rows.

## Completion

Run `flutter analyze` and, when feasible, `flutter test
test/visual_inspection/screenshot_test.dart`. Inspect the generated
`blocked_users__run-*.png` against the run-0070 references and the visual
checklist in `docs/design-language.md`.

Only after this screen is fully implemented and visually checked, edit this
prompt file and add this as the first line:

`implemented`
