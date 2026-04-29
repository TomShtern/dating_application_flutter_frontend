✅ implemented

Status: pending design-language refresh

Target file: `lib/features/profile/profile_screen.dart`

You are a Flutter frontend coding engineer. Redesign the Profile screen to
match `docs/design-language.md`, using the run-0070 reference screenshots as
the taste target:

- `design-reference/stats-run-0070-reference.png`
- `design-reference/notifications-run-0070-reference.png`
- `design-reference/notifications-dark-run-0070-reference.png`

## Non-Negotiables

- Read `docs/design-language.md` before editing this screen.
- This screen has two route modes. Current-user profile is a bottom-nav tab and
  must not add nested AppBar chrome. Other-user profile is a pushed secondary
  route and must keep back affordance plus route context.
- Do not change providers, models, API calls, profile navigation, safety action
  logic, edit navigation, refresh behavior, or helper semantics.
- Do not invent compatibility, profile readiness facts, reasons, metrics, or
  moderation data not present in the model/API.
- Do not add new tests for this UI/design pass. You may run existing useful
  tests, `flutter analyze`, and the visual-review suite.

## Design Direction

Profile is people-centered. It should lead with identity and real media when
useful, then compact truthful signals: activity, verification, location,
readiness, preferences, and safety context.

## Required Outcome

- Current-user tab: compact ShellHero/intro with edit and refresh actions,
  then scrollable profile content. No nested AppBar.
- Other-user route: compact AppBar with back affordance, short title or
  equivalent route context, safety actions, and refresh if already present.
- Hero/profile summary card should show person identity, media/avatar, headline,
  bio/readiness where available, and compact chips. Avoid oversized empty media
  or duplicate headings.
- Profile sections use consistent soft surfaces, decorated icon chips, semantic
  accents, and compact section grouping.
- Current-user completeness/readiness should be actionable but not repetitive.
  Avoid saying the same complete state in body text plus multiple pills.
- Other-user profile should support safety/context actions quietly and clearly.
- Empty bio/photos should use different copy for current user versus other user
  when the distinction already exists in the screen.

## Completion

Run `flutter analyze` and, when feasible, `flutter test
test/visual_inspection/screenshot_test.dart`. Inspect the generated
`shell_profile__run-*.png` and any other-user profile scenario against the
run-0070 references and the visual checklist in `docs/design-language.md`.

Only after this screen is fully implemented and visually checked, edit this
prompt file and add this as the first line:

`implemented`
