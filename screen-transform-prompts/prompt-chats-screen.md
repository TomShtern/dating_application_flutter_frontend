Status: pending design-language refresh

Target file: `lib/features/chat/conversations_screen.dart`

You are a Flutter frontend coding engineer. Redesign the Chats/Conversations
screen to match `docs/design-language.md`, using the run-0070 reference
screenshots as the taste target:

- `design-reference/stats-run-0070-reference.png`
- `design-reference/notifications-run-0070-reference.png`
- `design-reference/notifications-dark-run-0070-reference.png`

## Non-Negotiables

- Read `docs/design-language.md` before editing this screen.
- This is a bottom-navigation tab inside `SignedInShell`. Do not add a nested
  AppBar or secondary route chrome.
- Do not change providers, models, API calls, conversation routing,
  polling/refresh contracts, or message preview semantics.
- Do not invent last-message text, compatibility, reply intent, or backend
  status that the API does not provide.
- Do not add new tests for this UI/design pass. You may run existing useful
  tests, `flutter analyze`, and the visual-review suite.

## Design Direction

Chats should feel personal and calm, with teal/cyan as the message semantic
anchor. It should be denser and more useful than a marketing hero, but less
busy than a metrics screen.

## Required Outcome

- Use compact tab-screen structure: `SafeArea(top: false) -> Column ->
  compact intro/ShellHero -> Expanded -> RefreshIndicator -> list`.
- The top intro should show `Chats`, a useful count/state, and refresh if
  needed. It must not be a blank `ShellHero` slab.
- Conversation cards use semantic list-tile anatomy: soft teal-tinted surface,
  avatar, name, compact date/status, short truthful preview/count, decorated
  message icon, and one quiet trailing cue.
- Remove redundant duplicate affordances such as both card-wide tap plus
  repeated footer button plus "tap anywhere" copy.
- Use decorated icon chips and compact metadata strips. Avoid plain Material
  demo rows.
- Preserve card-wide `Material` + `InkWell` tappability.
- Empty state should be helpful and calm, with one refresh affordance when
  available.
- Dark mode must keep the same teal/chat personality if this screen is captured
  in dark mode later.

## Completion

Run `flutter analyze` and, when feasible, `flutter test
test/visual_inspection/screenshot_test.dart`. Inspect the generated
`shell_chats__run-*.png` against the run-0070 references and the visual
checklist in `docs/design-language.md`.

Only after this screen is fully implemented and visually checked, edit this
prompt file and add this as the first line:

`implemented`
