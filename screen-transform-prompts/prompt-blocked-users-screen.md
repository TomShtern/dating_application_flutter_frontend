# Blocked users design refinement prompt

Target file: `lib/features/safety/blocked_users_screen.dart`

Visual baseline: `visual_review/runs/run-0056__2026-04-28__08-04-08/blocked_users__run-0056__2026-04-28__08-04-08.png`

The current screen is already much closer to the desired direction than the old run-0049 prompt assumed. Do not revert it to the older instructions.

## Preserve

- Keep the AppBar title `Blocked users`.
- Keep the row overflow/kebab menu for unblock. Do not replace every row action with a visible `Unblock` button; unblock should remain a deliberate action behind the menu and confirmation dialog.
- Keep the current compact safety-row structure, generic `Blocked profile` row label, safety tint, and confirmation flow.
- Keep backend boundaries: do not invent block reasons, block dates, moderation labels, or extra safety metadata unless the existing model/API already provides them.

## Requested refinements

1. Polish the intro card title/layout.

In run 56, `Safety stays on` wraps awkwardly into two lines. Either adjust the intro card spacing so the title fits cleanly, or use a shorter title such as `Safety controls` if that reads better in the current layout.

Keep the count pill (`4 blocked profiles`) and the existing description direction.

2. Add a clearer transition into the list.

Add a small section label above the blocked-user rows, such as `Blocked profiles`, so the screen reads as:

- AppBar identity
- safety intro card
- list section label
- blocked-user rows

Use the existing design-language section-label treatment if one already exists in this file or shared widgets. Keep the spacing compact.

3. Make the row menu feel intentional.

If the row menu currently feels like a generic kebab, adjust tooltip/copy to read more specifically as block management, for example `Manage block` or `Blocked user options`.

Do not change the underlying unblock confirmation behavior.
