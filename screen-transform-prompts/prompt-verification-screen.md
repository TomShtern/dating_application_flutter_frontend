Status: pending design-language refresh

Target file: `lib/features/verification/verification_screen.dart`

You are a Flutter frontend coding engineer. Redesign the Verification screen
to match `docs/design-language.md`, using the run-0070 reference screenshots
as the taste target:

- `design-reference/stats-run-0070-reference.png`
- `design-reference/notifications-run-0070-reference.png`
- `design-reference/notifications-dark-run-0070-reference.png`

## Non-Negotiables

- Read `docs/design-language.md` before editing this screen.
- This is a pushed secondary route. Keep a compact visible route title and
  back affordance through the AppBar.
- Do not change providers, models, API calls, verification start/confirm logic,
  validation, cooldowns, resend behavior, snackbar behavior, or success flow.
- Do not invent verification methods, trust claims, security guarantees, or
  backend-owned status.
- Do not add new tests for this UI/design pass. You may run existing useful
  tests, `flutter analyze`, and the visual-review suite.

## Design Direction

Verification is a form/trust screen. It should feel calm, credible, and still
expressive: green/blue/violet for trust, soft serious surfaces, compact guided
steps, and clear primary action.

## Required Outcome

- Top chrome is useful: compact AppBar with back affordance and title
  `Verification`.
- Intro/summary should be compact and trust-oriented, not a large blank slab.
- Keep guided flow structure: current step, progress, form card, supporting
  trust/explanation card, and success treatment.
- Method selector, contact/code field, and CTA should feel like one coherent
  action block.
- Primary CTA should be clear and dominant; secondary/resend/status actions
  should be softer.
- Trust copy and badges must stay truthful to existing app/backend behavior.
- Success state can use stronger green/violet celebratory treatment, but
  destructive/error states should be serious and clear.
- Empty/loading/error states should preserve route context.

## Completion

Run `flutter analyze` and, when feasible, `flutter test
test/visual_inspection/screenshot_test.dart`. Inspect the generated
`verification__run-*.png` against the run-0070 references and the visual
checklist in `docs/design-language.md`.

Only after this screen is fully implemented and visually checked, edit this
prompt file and add this as the first line:

`implemented`
