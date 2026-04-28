Target file: lib/features/auth/dev_user_picker_screen.dart

Design reference: docs/design-language.md (utility/dev-only archetype,
ShellHero usage, AppTheme tokens, semantic colour tokens,
DeveloperOnlyCalloutCard usage)

You are a Flutter frontend engineer. Your task is to visually refine the
DevUserPickerScreen at `lib/features/auth/dev_user_picker_screen.dart`.
Do not change providers, controllers, navigation logic, the
`selectUserControllerProvider.selectUser(user)` call, the
`availableUsersProvider` / `selectedUserProvider` watchers, the
`BackendHealthBanner` placement, or the snackbar shown after a user is
selected.

Constraints (read first):
- This is the dev-only "auth" entry point — when no user is selected,
  the app routes here. The amber `DeveloperOnlyCalloutCard` framing is
  the deliberate signal that this is internal tooling — keep it.
- Use `AppTheme` tokens (`cardRadius`, `panelRadius`, `chipRadius`,
  `pagePadding`, `cardPadding`, `cardGap`, `sectionGap`, `screenPadding`,
  `sectionPadding`, `sectionSpacing`, `listSpacing`, `surfaceDecoration`).
- Don't invent helper names. If a helper isn't in
  `lib/theme/app_theme.dart`, leave the existing literal.
- The `ShellHeroPill` widget already used for the selected-user marker
  inside `_UserCard` is canonical — keep it.

---

# Change 1 — AppBar: drop the title

The AppBar reads "Choose a dev user" while the `DeveloperOnlyCalloutCard`
right below it carries the title "Development sign-in" and a
description. Two stacked headings.

Replace the AppBar with:

```dart
appBar: AppBar(
  title: const SizedBox.shrink(),
  backgroundColor: Colors.transparent,
  elevation: 0,
  scrolledUnderElevation: 0,
),
```

There's no back affordance because this is the root route when no user
is selected — Flutter will not draw a back arrow. Leave the AppBar in
place anyway (it gives the screen a top safe inset and a consistent
status-bar treatment).

---

# Change 2 — Tokenise the list of fixed spacers

The build currently uses `SizedBox(height: 14)`, `SizedBox(height: 14)`,
`SizedBox(height: 18)` between the four major blocks (callout → health
banner → current-user card → user list).

Replace:
- callout → health banner: `SizedBox(height: AppTheme.cardGap)`.
- health banner → current-user card: `SizedBox(height:
  AppTheme.cardGap)`.
- current-user card → user list: `SizedBox(height:
  AppTheme.sectionSpacing(compact: true))`.

The `AppTheme.listSpacing()` separator inside `ListView.separated`
stays as is.

---

# Change 3 — `_CurrentUserCard`: tokenise paddings, simplify when no user

a) Outer `EdgeInsets.all(14)` → `EdgeInsets.all(AppTheme.cardPadding)`.

b) When `user == null`, the card currently renders three lines of body
   copy:
   - title: "Current user: none selected"
   - summary: "Choose one below to jump straight into the app. Your
     selection stays saved on this device."
   - supportingCopy: "You can switch profiles again anytime from
     Settings."

   The supporting copy doesn't apply when no user is selected (the user
   isn't switching, they're choosing for the first time). Drop it for
   the no-user case:

```dart
final supportingCopy = user == null
    ? null
    : 'You can switch profiles again anytime from Settings.';
```

   And conditionally render the supporting `Text`:

```dart
if (supportingCopy != null) ...[
  const SizedBox(height: 4),
  Text(
    supportingCopy,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  ),
],
```

c) The summary `Text` picks up `bodyMedium` styling (currently uses
   default). Style it with `colorScheme.onSurface`:

```dart
Text(
  summary,
  style: Theme.of(context).textTheme.bodyMedium,
),
```

d) Switch the outer `Row` to `crossAxisAlignment: CrossAxisAlignment.center`
   so the avatar centres against the title baseline (currently
   start-aligned, pushing the avatar above the title).

---

# Change 4 — `_UserCard`: tokenise padding, align avatar, soften unselected border

a) Outer `EdgeInsets.all(14)` → `EdgeInsets.all(AppTheme.cardPadding)`.

b) Switch the inner `Row`'s `crossAxisAlignment` from
   `CrossAxisAlignment.start` to `CrossAxisAlignment.center` so the
   24-radius avatar centres against the multi-line text column.

c) The unselected card border uses `outlineVariant @ 0.55` alpha —
   that's heavy enough to read as a hard rule on the page background.
   Soften to `0.32` so the cards read as soft surfaces, not stamped
   borders:

```dart
side: BorderSide(
  color: isSelected
      ? colorScheme.primary.withValues(alpha: 0.34)
      : colorScheme.outlineVariant.withValues(alpha: 0.32),
),
```

The selected card border (`primary @ 0.34`) stays — it needs the
contrast to read as the active state.

d) The `ShellHeroPill(icon: Icons.check_circle_rounded, label:
'Current')` selected marker is correct — leave it. But `Wrap` the
right-side pill in a `Padding(EdgeInsets.only(left: 8))` so it doesn't
collide with a long display name on narrow widths.

---

# Change 5 — `_UserCard`: copy refinement

The unselected helper text "Tap to switch to this profile." reads as
instructional spam on every card in the list. Replace with a tiny
context line that doesn't repeat the obvious tap affordance:

```dart
Text(
  isSelected
      ? 'Saved on this device.'
      : 'Last seen: backend session',
  style: theme.textTheme.bodySmall?.copyWith(
    color: colorScheme.onSurfaceVariant,
  ),
),
```

If the user model exposes a richer "last seen" or session field (verify
by reading `lib/models/user_summary.dart` — do NOT invent a field),
prefer that. If it doesn't, fall back to the simpler "Available dev
profile" string:

```dart
Text(
  isSelected ? 'Saved on this device.' : 'Available dev profile',
  ...
)
```

The selected-state copy "Saved on this device." reads as confirmation
without restating "this is a profile" the way "Saved on this device
right now" did.

---

# Change 6 — Empty / loading / error states

The current empty state reads "No dev users are available yet." which
is fine but uninformative for a backend-down case — and the same string
shows up regardless of root cause.

Bump the empty copy to:

```dart
const AppAsyncState.empty(
  message:
      'No seeded dev users came back from the backend. Confirm the seed task ran or check the backend health banner above.',
),
```

Loading and error branches stay — the error branch already pulls from
`ApiError.message` which is the right behaviour.

---

# Change 7 — `BackendHealthBanner` placement: leave alone, but verify spacing

The `BackendHealthBanner` is a separate widget that renders a one-line
status pill (✓ Backend online / ✗ Backend unreachable). It currently
sits between the callout and the current-user card, which is correct —
backend status is most useful before the user chooses a profile.

The only adjustment is the surrounding spacing (already covered in
Change 2). Do not modify the banner internals.

---

# Acceptance checklist

- AppBar title is `SizedBox.shrink()`. The `DeveloperOnlyCalloutCard`
  remains the visual anchor.
- The four major blocks (callout / health banner / current-user card /
  user list) are separated by `AppTheme.cardGap` /
  `AppTheme.sectionSpacing(compact: true)` instead of literal 14 / 18.
- `_CurrentUserCard` outer padding is
  `EdgeInsets.all(AppTheme.cardPadding)`. Inner Row is
  `CrossAxisAlignment.center`. The supporting copy line only renders
  when a user IS selected. Summary `Text` uses `bodyMedium`.
- `_UserCard` outer padding is `EdgeInsets.all(AppTheme.cardPadding)`.
  Inner Row is `CrossAxisAlignment.center`. The unselected border is
  `outlineVariant @ 0.32`; the selected border (`primary @ 0.34`) is
  unchanged.
- The `ShellHeroPill` selected-marker has a left padding of 8 so it
  doesn't collide with the name on narrow widths.
- The unselected card helper line no longer reads "Tap to switch to
  this profile." — it reads "Available dev profile" (or a real
  last-seen string if `UserSummary` exposes one).
- Empty-state copy explains the seed-task / backend-down possibility.
- `flutter analyze` is clean.
- A visual review run produces an `app_home_startup__run-XXXX…png`
  whose hierarchy reads: empty AppBar → amber dev callout → backend
  health banner → current-user card (no avatar when null, two-line copy
  when null) → list of dev-user cards with centred avatars, softened
  unselected borders, and a single "Current" pill on the active row.
