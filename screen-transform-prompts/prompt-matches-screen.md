✅ implemented

Status: pending design-language refresh

Target file: `lib/features/matches/matches_screen.dart`

You are a Flutter frontend coding engineer. Redesign the Matches screen to
match `docs/design-language.md`, using the run-0070 reference screenshots as
the taste target:

- `design-reference/stats-run-0070-reference.png`
- `design-reference/notifications-run-0070-reference.png`
- `design-reference/notifications-dark-run-0070-reference.png`

## Non-Negotiables

- Read `docs/design-language.md` before editing this screen.
- This is a bottom-navigation tab inside `SignedInShell`. Do not add a nested
  AppBar or pushed-route chrome.
- Do not change providers, models, API calls, navigation behavior, refresh
  behavior, or match logic helpers.
- Do not invent compatibility, recommendation, activity, or location logic not
  present in the model/API.
- Every visible filter must work. Remove or simplify decorative filters that do
  not change content.
- Do not add new tests for this UI/design pass. You may run existing useful
  tests, `flutter analyze`, and the visual-review suite.

## Design Direction

Matches is a people/social screen. It should feel romantic and premium, with
rose/violet for affinity, green/mint for active state, and compact truth-based
signals around people. It should not become a generic card list or a giant
low-information hero.

## Required Outcome

- Use compact tab-screen structure: `SafeArea(top: false) -> Column ->
  compact intro/ShellHero -> optional functional filter strip -> Expanded ->
  RefreshIndicator -> list`.
- The top intro should show `Your matches`, a useful live count/state, and
  refresh if needed.
- Match cards should center person identity: avatar/photo, name, short bio or
  truthful fallback, match date, active/location/status signals, and clear
  actions.
- Use one primary action for messaging and one quieter secondary action for
  profile viewing. Avoid multiple equally loud CTAs.
- Cards should use soft tinted surfaces, semantic accents, decorated chips, and
  compact metadata. Avoid plain white unfinished cards.
- New-match state may receive a stronger accent, but do not make every card a
  full color block.
- Empty state should point back to liking profiles without shaming the user.

## Completion

Run `flutter analyze` and, when feasible, `flutter test
test/visual_inspection/screenshot_test.dart`. Inspect the generated
`shell_matches__run-*.png` against the run-0070 references and the visual
checklist in `docs/design-language.md`.

Only after this screen is fully implemented and visually checked, edit this
prompt file and add this as the first line:

`implemented`
