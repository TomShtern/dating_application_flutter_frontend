Status: pending design-language refresh

Target file: `lib/features/stats/achievements_screen.dart`

You are a Flutter frontend coding engineer. Redesign the Achievements screen
to match `docs/design-language.md`, using the run-0070 reference screenshots
as the taste target:

- `design-reference/stats-run-0070-reference.png`
- `design-reference/notifications-run-0070-reference.png`
- `design-reference/notifications-dark-run-0070-reference.png`

## Non-Negotiables

- Read `docs/design-language.md` before editing this screen.
- This is a pushed secondary route. Keep a compact visible route title and
  back affordance through the AppBar.
- Do not change providers, models, API calls, refresh behavior, achievement
  detail behavior, or backend-owned achievement logic.
- Do not invent achievement categories, eligibility, progress, or motivational
  claims not present in the model/API.
- Do not add new tests for this UI/design pass. You may run existing useful
  tests, `flutter analyze`, and the visual-review suite.

## Design Direction

Achievements should feel like the celebratory sibling of Stats: compact,
data-informed, pastel, and premium. Use violet/periwinkle plus amber as the
main milestone language, with green only for completed/success state. The
screen should not become a flat list of white cards or a one-color purple
screen.

## Required Outcome

- Top chrome is useful: compact AppBar with back affordance and title
  `Achievements`.
- First viewport reaches real achievement content quickly after a compact
  summary. Avoid a large blank or low-information hero slab.
- Use a data-summary card only if it contains useful state: total unlocked,
  in-progress count, completion percent, or recent milestone.
- Split achievements into clear sections such as `Unlocked` and `Still
  building` when the data supports it.
- Use the design-language section label pattern for groups: semantic accent
  bar, bold compact title, fading rule.
- Achievement cards use the surface layer recipe: soft tinted surface, one
  semantic accent, decorated icon/status chip, progress or status signal.
- In-progress achievements should show progress text and, when parsable, a
  compact progress bar.
- Unlocked achievements should feel complete and celebratory without every
  card becoming a saturated gradient block. Reserve full gradient/color-block
  treatment for a summary, top milestone, or special state.
- Keep icons decorated and semantic. Prefer Material icons in tinted chips.
- Keep empty/loading/error states polished and useful.

## Completion

Run `flutter analyze` and, when feasible, `flutter test
test/visual_inspection/screenshot_test.dart`. Inspect the generated
`achievements__run-*.png` against the run-0070 references and the visual
checklist in `docs/design-language.md`.

Only after this screen is fully implemented and visually checked, edit this
prompt file and add this as the first line:

`implemented`
