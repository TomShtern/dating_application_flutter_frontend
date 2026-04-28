Target file: lib/features/profile/profile_edit_screen.dart

Design reference: docs/design-language.md (utility/settings archetype for
pushed editors, AppTheme tokens, semantic colour tokens)

You are a Flutter frontend engineer. Your task is to visually refine the
ProfileEditScreen at `lib/features/profile/profile_edit_screen.dart`. Do
not change providers, controllers, models, API calls, or save / submit
logic. Keep `_handleSave`, `_validatePositiveInteger`, `_validateMaxAge`,
`_trimmedOrNull`, `_profileLocationRequestFrom`, `_normalizedOrNull`,
`_parseOptionalInt`, `_orderedInterestedInValues`, `_normalizeGender`,
`_initialFor`, the `_genderOptions` list, and the `ProfileUpdateRequest`
construction in `_handleSave` exactly as written.

Constraints (read first):
- This is a pushed editor screen, not a tab. The `AppBar` MUST stay (for
  the back affordance) but its title becomes empty — the
  `_ProfileEditHeader` is the visual anchor (utility archetype).
- Use `AppTheme` tokens (`cardRadius`, `panelRadius`, `chipRadius`,
  `pagePadding`, `cardPadding`, `cardGap`, `sectionGap`, `screenPadding`,
  `sectionPadding`, `sectionSpacing`, `listSpacing`, `surfaceDecoration`).
- Don't invent helper names. If a helper isn't in
  `lib/theme/app_theme.dart`, leave the existing literal.
- Do NOT change form validation rules, `Slider` min/max/divisions, or
  the `ExpansionTile` structure inside "Fine-tune matching".

---

# Change 1 — `_ProfileEditAppBar`: drop the duplicate title

Today the AppBar reads "Edit your profile" while `_ProfileEditHeader`
already shows the user's name + status pills + the same instructional
copy ("Edit the core details first…"). Remove the title:

```dart
class _ProfileEditAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _ProfileEditAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const SizedBox.shrink(),
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    );
  }
}
```

The back arrow remains (this is a pushed screen). The same change
applies to the loading and error branches, which already use
`_ProfileEditAppBar`.

---

# Change 2 — Sticky save bar: tokenise paddings, add a soft top border

Today the bottom save bar uses `SafeArea(minimum:
EdgeInsets.fromLTRB(24, 12, 24, 24))` directly around a `FilledButton`,
which sits on the page background with no visual separation when the
form scrolls underneath.

Wrap the button in a token-padded `DecoratedBox` so it reads as a
distinct action bar:

```dart
bottomNavigationBar: SafeArea(
  child: DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border(
        top: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant
              .withValues(alpha: 0.4),
        ),
      ),
    ),
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        AppTheme.cardGap,
        AppTheme.pagePadding,
        AppTheme.cardGap,
      ),
      child: SizedBox(
        height: 48,
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _isSaving ? null : _handleSave,
          icon: _isSaving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded),
          label: Text(_isSaving ? 'Saving…' : 'Save changes'),
        ),
      ),
    ),
  ),
),
```

Three improvements over today:
1. The save bar gains a subtle top border so it visually anchors when
   the form scrolls underneath.
2. The button gets a leading icon and an inline spinner during save,
   replacing the text-only "Saving…" state.
3. Padding switches to `pagePadding` / `cardGap` tokens.

---

# Change 3 — `_ProfileEditSection`: tokenise paddings

The section card uses `EdgeInsets.all(16)` outer padding and
`SizedBox(height: 4)` between title and description, plus
`SizedBox(height: 12)` between description and child.

Replace:
- Outer padding → `EdgeInsets.all(AppTheme.cardPadding)`.
- title→description spacer stays at `SizedBox(height: 4)` — too small
  for a token.
- description→child spacer → `SizedBox(height: AppTheme.cardGap)`.

The description `Text` already uses `colorScheme.onSurfaceVariant` —
leave it. The title uses `titleMedium` — bump to `titleLarge` so each
section is a stronger visual anchor inside the form's long scroll.

---

# Change 4 — Basics section: align Wrap spacing with token

Inside the Basics section, the two `Wrap`s use `spacing: 10, runSpacing:
10` and a hand-rolled `SizedBox(height: 18)` between Gender and
Interested in.

Change:
- Both `Wrap.spacing` and `Wrap.runSpacing` from `10` to
  `AppTheme.cardGap` if it equals 10; otherwise leave the literal.
- The Gender→Interested in spacer `SizedBox(height: 18)` →
  `SizedBox(height: AppTheme.sectionGap)` so the two sub-sections
  match the section card's internal rhythm.
- The `SizedBox(height: 8)` between each label ("Gender" / "Interested
  in") and its `Wrap` is fine — too small to tokenise.

The chip widgets (`ChoiceChip` for Gender, `FilterChip` for Interested
in) stay — Material's chip styling already harmonises with the rest of
the app. Do NOT swap them for custom pills.

---

# Change 5 — Distance section: format the slider readout

The current slider readout shows two parallel labels:

- Left: `'Up to $_maxDistanceKm km'` (titleMedium)
- Right: `'${_distanceSliderValue.round()} km'` (labelLarge)

When `_maxDistanceKm` is set, both show the same number — duplicated
information. Collapse to a single readout that reads naturally:

```dart
Row(
  children: [
    Expanded(
      child: Text(
        _maxDistanceKm == null
            ? 'Distance not set yet'
            : 'Showing matches within',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ),
    if (_maxDistanceKm != null)
      Text(
        '${_distanceSliderValue.round()} km',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
  ],
),
```

When unset, the right side disappears entirely; when set, it shows the
distance once with the bold weight and the left side reads as a
caption.

Replace the helper text below the slider:

```dart
Text(
  _maxDistanceKm == null
      ? 'Move the slider to set how far the app should look.'
      : 'Anyone further than this won\'t show up in discover.',
  style: Theme.of(context).textTheme.bodySmall?.copyWith(
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  ),
),
```

Both copy strings are friendlier and explain consequence rather than
plumbing.

---

# Change 6 — Location section: tokenise inner card and tighten rhythm

The location section wraps a `DecoratedBox` (with custom border) inside
the `_ProfileEditSection` card — a card-inside-a-card pattern that adds
visual weight without clarity.

Simplify the inner box: drop the `DecoratedBox` border and rely on the
section card's surface to host the row directly:

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.location_on_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _approximateLocation.trim().isEmpty
                ? 'Add the area where you want to meet people.'
                : 'Showing people near $_approximateLocation.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    ),
    SizedBox(height: AppTheme.cardGap),
    Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: () async { /* unchanged */ },
        icon: const Icon(Icons.travel_explore_outlined),
        label: Text(
          _approximateLocation.trim().isEmpty
              ? 'Choose location'
              : 'Update location',
        ),
      ),
    ),
  ],
),
```

The icon now picks up `colorScheme.primary` so it visually ties to the
button below it. The `Align` keeps the button intrinsic-width on the
left rather than stretching across the section card.

---

# Change 7 — `_ProfileEditHeader`: tighten and tokenise

The header card uses `AppTheme.sectionPadding(compact: true)` (good)
and a custom 48×48 `Container` initial avatar with `borderRadius: 14`.

Two refinements:

a) The instructional copy "Edit the core details first. Optional
   filters stay lower on the page." duplicates the AppBar's purpose now
   that the title is gone. Keep the copy — it's the only on-screen
   guidance — but bump it to `bodyMedium w500` so it reads as actionable
   guidance rather than a footnote.

b) Replace the hand-rolled initial-avatar `Container` with a
   `UserAvatar` if the snapshot exposes a photo URL. If not, keep the
   custom container but switch its `BorderRadius.circular(14)` to
   `BorderRadius.circular(16)` so it matches the section header icon
   chips elsewhere (Profile, Settings, Notifications). The
   `colorScheme.primaryContainer` background and `onPrimaryContainer`
   text colour stay.

The subtitleParts join (`'Active · Tel Aviv · Verified profile'`) is
fine — leave it.

---

# Change 8 — Final spacer before save bar

The list ends with `const SizedBox(height: 24)` before the save bar.
Replace with `SizedBox(height: AppTheme.sectionSpacing(compact: true))`
so the gap rhythm matches the section spacing used everywhere else in
the form.

---

# Acceptance checklist

- AppBar title is `SizedBox.shrink()` — no "Edit your profile" text.
  Back arrow remains.
- The bottom save button is wrapped in a `DecoratedBox` with a soft
  top `outlineVariant @ 0.4` border, uses `pagePadding` / `cardGap`
  tokens, and the button gains a leading check icon (or spinner during
  save).
- `_ProfileEditSection` outer padding is
  `EdgeInsets.all(AppTheme.cardPadding)`. Section title is `titleLarge`.
- Basics section: Gender→Interested in spacer is `AppTheme.sectionGap`.
- Distance section: the redundant "Up to X km" / "X km" parallel labels
  collapse to one bold readout + caption. Helper text reads "Anyone
  further than this won't show up in discover." when set.
- Location section: the inner `DecoratedBox` border is removed. Icon
  picks up `colorScheme.primary`. The OutlinedButton sits left-aligned.
- `_ProfileEditHeader` instructional copy is `bodyMedium w500`. Initial
  avatar (if not replaced by `UserAvatar`) uses
  `BorderRadius.circular(16)`.
- The final `SizedBox(height: 24)` before the save bar is replaced
  with `AppTheme.sectionSpacing(compact: true)`.
- `flutter analyze` is clean.
- A visual review run produces a `profile_edit__run-XXXX…png` whose
  hierarchy reads: empty AppBar with back arrow → header card with
  avatar + name + status + guidance → Basics → Distance with single
  bold readout → About → Location with primary-tinted icon → Fine-tune
  → save bar with top border and icon-leading button.
