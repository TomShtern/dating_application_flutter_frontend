✅ implemented

Status: pending design-language refresh

Target file: `lib/features/chat/conversation_thread_screen.dart`

You are a Flutter frontend coding engineer. Redesign the Conversation Thread
screen to match `docs/design-language.md`, using the run-0070 reference
screenshots as the taste target:

- `design-reference/stats-run-0070-reference.png`
- `design-reference/notifications-run-0070-reference.png`
- `design-reference/notifications-dark-run-0070-reference.png`

## Non-Negotiables

- Read `docs/design-language.md` before editing this screen.
- This is a pushed secondary route. Keep a compact visible route title and
  back affordance through the AppBar.
- Do not change providers, models, API calls, send-message behavior,
  polling/refresh behavior, route parameters, or safety action behavior.
- Do not invent read receipts, typing indicators, compatibility, or message
  status not provided by the API.
- Do not add new tests for this UI/design pass. You may run existing useful
  tests, `flutter analyze`, and the visual-review suite.

## Design Direction

Messaging should be personal and calm. Use teal/cyan for conversation
semantics, with soft pastel bubbles and clear sender/recipient distinction.
The design should support reading and replying first; do not turn this into a
dashboard.

## Required Outcome

- AppBar provides route context: back affordance, participant/conversation
  title, and any existing safety/refresh actions in compact form.
- Keep the first viewport focused on the conversation itself, not a large
  intro panel.
- Message groups should be readable and compact: date/status grouping,
  sender/recipient distinction, friendly bubbles, and subtle semantic color.
- The input area should feel anchored to the task: soft surface, clear send
  button, useful disabled/busy state, and no competing decorative CTA.
- Use small motion or state transitions only where already appropriate.
- Empty thread state should invite starting the conversation without inventing
  relationship context.
- Loading and error states should preserve route context and provide retry when
  the existing controller supports it.
- Respect accessibility: text remains readable, tap targets stay practical,
  and bubbles do not collapse on narrow width.

## Completion

Run `flutter analyze` and, when feasible, `flutter test
test/visual_inspection/screenshot_test.dart`. Inspect the generated
`conversation_thread__run-*.png` or matching visual scenario against the
run-0070 references and the visual checklist in `docs/design-language.md`.

Only after this screen is fully implemented and visually checked, edit this
prompt file and add this as the first line:

`implemented`
