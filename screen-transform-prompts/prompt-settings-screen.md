Status: pending design-language refresh

Target file: `lib/features/settings/settings_screen.dart`

You are a Flutter frontend coding engineer. Redesign the Settings screen to
match `docs/design-language.md`, using the run-0070 reference screenshots as
the taste target:

- `design-reference/stats-run-0070-reference.png`
- `design-reference/notifications-run-0070-reference.png`
- `design-reference/notifications-dark-run-0070-reference.png`

## Non-Negotiables

- Read `docs/design-language.md` before editing this screen.
- This is a bottom-navigation tab inside `SignedInShell`. Do not add a nested
  AppBar or pushed-route chrome.
- Do not change providers, preferences behavior, selected-user behavior,
  navigation destinations, or dev-session logic.
- Keep developer-only controls visually separated from user-facing product
  controls.
- Do not add new tests for this UI/design pass. You may run existing useful
  tests, `flutter analyze`, and the visual-review suite.

## Design Direction

Settings is a practical utility screen. It should be compact, organized, and
polished, with subtle category color and decorated icons. It should not look
like a raw Material settings demo, and it should not be as loud as Stats.

## Required Outcome

- Use compact tab-screen structure: `SafeArea(top: false) -> Column ->
  compact intro/ShellHero -> Expanded -> ListView`.
- Intro should show `Settings`, a useful account/context subtitle, and no
  decorative filler.
- Developer session card keeps its amber/internal-tooling signal but fits the
  soft surface rhythm.
- Quick access rows use semantic list-tile anatomy: tinted icon chip, title,
  muted subtitle, quiet chevron, and softened separators if needed.
- Appearance/theme controls should feel like a form section: clear grouped
  surface, functional segmented control, and concise descriptive state.
- Use category color subtly: profile/identity, notifications/status, stats/data,
  safety/moderation, verification/trust, appearance/theme.
- Avoid large empty headers, hard dividers, and plain undecorated icons.

## Completion

Run `flutter analyze` and, when feasible, `flutter test
test/visual_inspection/screenshot_test.dart`. Inspect the generated
`shell_settings__run-*.png` against the run-0070 references and the visual
checklist in `docs/design-language.md`.

Only after this screen is fully implemented and visually checked, edit this
prompt file and add this as the first line:

`implemented`
