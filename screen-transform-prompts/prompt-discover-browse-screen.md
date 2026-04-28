Status: pending design-language refresh

Target file: `lib/features/browse/browse_screen.dart`

You are a Flutter frontend coding engineer. Redesign the Discover/Browse screen
to match `docs/design-language.md`, using the run-0070 reference screenshots
as the taste target:

- `design-reference/stats-run-0070-reference.png`
- `design-reference/notifications-run-0070-reference.png`
- `design-reference/notifications-dark-run-0070-reference.png`

## Non-Negotiables

- Read `docs/design-language.md` before editing this screen.
- This is the main discover tab inside `SignedInShell`. Do not add nested
  secondary route chrome.
- Do not change providers, browse controller logic, like/pass/undo behavior,
  Dismissible behavior, safety behavior, or navigation contracts.
- Do not invent compatibility, recommendation, "why shown" reasons, metrics,
  or profile signals. Use only backend-provided presentation context and model
  fields.
- Do not add new tests for this UI/design pass. You may run existing useful
  tests, `flutter analyze`, and the visual-review suite.

## Design Direction

Discover is the most people-centered screen. It should be colorful, pastel,
romantic, and useful, with real media where available and compact semantic
signals around each person. It should not be a blank hero plus a giant card,
and it should not collapse into one pink/mauve theme.

## Required Outcome

- First viewport should show useful discover context and the current candidate
  quickly. Avoid large blank `ShellHero` slabs.
- Use a compact intro/ShellHero only if it contains real context: current user,
  candidate count, refresh/undo state, or useful shortcut chips.
- Candidate cards should emphasize person identity and real media, then compact
  truth-based signals: location, active/verified state, presentation context,
  and available backend reasons.
- Use semantic color variety: likes/affinity rose, standout/highlight amber,
  active/trust green, messages teal when relevant, fallback slate/sky.
- Daily pick and shortcut cards should each have distinct semantic accents.
- Use decorated Material icons in pastel chips; avoid generic plain icons.
- Keep primary actions clear and emotionally appropriate. Secondary and safety
  actions should be quieter and not compete with Like/Pass.
- Keep developer/session panels visually separated from user-facing product
  surfaces.
- Preserve all gestures and backend-owned behavior.

## Completion

Run `flutter analyze` and, when feasible, `flutter test
test/visual_inspection/screenshot_test.dart`. Inspect the generated
`shell_discover__run-*.png` or matching browse visual against the run-0070
references and the visual checklist in `docs/design-language.md`.

Only after this screen is fully implemented and visually checked, edit this
prompt file and add this as the first line:

`implemented`
