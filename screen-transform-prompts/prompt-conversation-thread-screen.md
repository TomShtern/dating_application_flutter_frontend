# Conversation thread design refinement prompt

Target file: `lib/features/chat/conversation_thread_screen.dart`

Visual baseline: `visual_review/runs/run-0051__2026-04-27__21-05-22/conversation_thread__run-0051__2026-04-27__21-05-22.png`

The current populated-thread screenshot intentionally shows a mid-conversation position, so a clipped top message in that visual fixture is acceptable as a testing composition. However, the real app must never open a conversation with the first visible message clipped after the user enters the screen.

## Preserve

- Keep the current AppBar identity behavior even if the screenshot does not show a traditional large AppBar: avatar, name, `Active recently`, and the overflow menu.
- Keep the warm outgoing and incoming message bubble treatments.
- Keep the upward-arrow send button.
- Keep the current long-thread density. Do not add extra match-context cards into a populated conversation.
- Keep existing provider, timer, refresh, send, scroll, and conversation action logic unless a scroll/framing bug requires a minimal localized fix.

## Requested refinements

1. Fix real-entry message framing.

When a user opens a conversation in actual use, the first visible message after the automatic scroll/positioning must not be clipped. Keep the visual-test mid-thread composition if it is intentional, but make sure the live entry behavior lands cleanly on a message boundary or at the intended bottom position without cutting a bubble.

2. Add a sparse-thread visual-review state.

The source contains a sparse-thread summary state, but the current visual suite only captures a populated conversation thread. Add a separate visual inspection screenshot for a sparse/new conversation thread with four or fewer messages so the sparse summary card can be reviewed directly.

Use a distinct scenario name and filename, for example:

- scenario: `sparse conversation thread`
- file: `conversation_thread_sparse.png`

Base the fixture on existing visual-inspection fixture patterns. Do not replace the populated thread screenshot.

3. Minor composer polish only if needed.

If the composer still feels too visually heavy after the framing work, lightly reduce its visual weight through spacing or surface treatment. Keep the current hint text and upward-arrow action.
