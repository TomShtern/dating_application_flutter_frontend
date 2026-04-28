Target file: lib/features/location/location_completion_screen.dart

Design reference: docs/design-language.md (utility/settings archetype for
pushed editors, AppTheme tokens, semantic colour tokens, SectionIntroCard
usage pattern)

You are a Flutter frontend engineer. Your task is to visually refine the
LocationCompletionScreen at
`lib/features/location/location_completion_screen.dart`. Do not change
providers, controllers, models, API calls, navigation logic, the
`_handleSave` flow, the `_resolveInitialCountryCode` helper, the
`_cityDisplayLabel` helper, or the `LocationCitySearchQuery`
construction.

Constraints (read first):
- Pushed editor screen: `AppBar` MUST stay (back affordance) but its
  title becomes empty. The first card on screen ("Your area") is the
  visual anchor.
- Use `AppTheme` tokens (`cardRadius`, `panelRadius`, `chipRadius`,
  `pagePadding`, `cardPadding`, `cardGap`, `sectionGap`, `screenPadding`,
  `sectionPadding`, `sectionSpacing`, `listSpacing`, `surfaceDecoration`).
- Don't invent helper names. If a helper isn't in
  `lib/theme/app_theme.dart`, leave the existing literal.
- The `_CountryFlagIcon` widget (a generic flag-outlined chip) is
  intentional placeholder chrome until country-specific flags ship —
  do NOT replace it with a real flag asset, but its container styling
  is fair game.
- Do NOT change `Switch` / `SwitchListTile.adaptive` placement; the
  approximate-match toggle is part of the form contract.

---

# Change 1 — AppBar: drop the duplicate title

The AppBar reads "Choose your location" and the very first card below
it is titled "Your area". Two headings stacked on top of each other.
Remove the AppBar title:

```dart
appBar: AppBar(
  title: const SizedBox.shrink(),
  backgroundColor: Colors.transparent,
  elevation: 0,
  scrolledUnderElevation: 0,
),
```

Back arrow remains (this is a pushed screen).

---

# Change 2 — "Your area" card: tokenise paddings

Today the first card uses `AppTheme.sectionPadding()` outer padding and
mixes `SizedBox(height: 6)`, `SizedBox(height: 12)`, `SizedBox(height:
4)`, `SizedBox(height: 8)`, `SizedBox(height: 10)` between rows.

Replace:
- Outer padding stays as `AppTheme.sectionPadding()` — already a token.
- The `SizedBox(height: 12)` between description→country dropdown,
  country→city, city→zip, zip→switch, button→helper text become
  `SizedBox(height: AppTheme.cardGap)`.
- The `SizedBox(height: 6)` between title→description stays at `6`
  (too small to tokenise).
- The `SizedBox(height: 4)` between zip and the switch tile stays at `4`
  — the `SwitchListTile` already has its own padding, so a small visual
  break is correct here.
- The `SizedBox(height: 12)` immediately before the FilledButton
  changes to `SizedBox(height: AppTheme.sectionGap)` so the CTA is
  visually a section break, not just another row.
- The `SizedBox(height: 10)` before `_SelectedCityCard` →
  `SizedBox(height: AppTheme.cardGap)`.

The card title "Your area" stays at `titleLarge`. The description below
it picks up `colorScheme.onSurfaceVariant` styling:

```dart
Text(
  'Choose the country and city you want us to use for nearby matches.',
  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  ),
),
```

---

# Change 3 — Save CTA: full-width with leading icon (already), tokenise wrapper

The `SizedBox(width: double.infinity, child: FilledButton.icon(...))`
already produces a full-width button with a location icon. Two
refinements:

a) Wrap the button in a `SizedBox(height: 48)` so its height matches
   the profile-edit save bar (Change 2 in the profile-edit prompt).
   Consistent CTA height across the app reads as a deliberate rhythm.
b) Replace the inline `'Saving…'` label with an inline spinner +
   "Saving…" so users see progress feedback instead of just a text
   change:

```dart
SizedBox(
  width: double.infinity,
  height: 48,
  child: FilledButton.icon(
    onPressed: _saving ? null : () => _handleSave(context),
    icon: _saving
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.location_on_outlined),
    label: Text(_saving ? 'Saving…' : 'Use this location'),
  ),
),
```

The "You can change this anytime." helper text below stays unchanged.

---

# Change 4 — `_SelectedCityCard`: lift the surface tint

Today this card uses `colorScheme.primaryContainer.withValues(alpha:
0.55)` as the fill, which produces a heavily-tinted purple slab in
light mode that competes visually with the FilledButton above it.

Soften the tint and add a hairline accent border so the card reads as
a confirmation chip rather than a second CTA surface:

```dart
DecoratedBox(
  decoration: BoxDecoration(
    color: colorScheme.primaryContainer.withValues(alpha: 0.32),
    borderRadius: AppTheme.cardRadius,
    border: Border.all(
      color: colorScheme.primary.withValues(alpha: 0.18),
    ),
  ),
  child: Padding(
    padding: const EdgeInsets.all(AppTheme.cardPadding),
    child: Row(
      children: [
        Icon(Icons.check_circle_rounded, color: colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Selected city', style: theme.textTheme.labelLarge),
              const SizedBox(height: 2),
              Text(cityLabel, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    ),
  ),
),
```

Two specific changes:
- Alpha `0.55` → `0.32` for the fill.
- New 18%-alpha primary border so the chip has an outline.
- Inner `EdgeInsets.all(12)` → `EdgeInsets.all(AppTheme.cardPadding)`
  for token alignment.
- Icon swap from `check_circle_outline` to `check_circle_rounded` so
  the filled icon reads as a positive confirmation.

---

# Change 5 — "Suggested cities" card: tighten the list rendering

Today the suggested-cities body uses `ListTile(contentPadding:
EdgeInsets.zero, …)` with default vertical padding, producing tall
rows (the screenshot shows two cities filling almost half the section
card).

Replace each `ListTile` with a tighter `InkWell`-tappable row that
matches the design-language list-row spec:

```dart
return Column(
  children: [
    for (final city in cities)
      Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppTheme.panelRadius,
          onTap: () {
            setState(() {
              _cityController.text = city.name;
              _selectedCityLabel = _cityDisplayLabel(city);
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        city.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (city.district.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          city.district,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
  ],
);
```

This produces tighter rows with a leading place icon, and the chevron
shrinks from 24 to 20 to match the `_SettingsLinkTile` chevron rhythm.

---

# Change 6 — Loading and empty states inside Suggested cities

a) The "Type at least two letters for city suggestions." line currently
   renders as a bare `Text`. Style it with
   `colorScheme.onSurfaceVariant` and add a leading icon so it reads
   as guidance, not an error:

```dart
Row(
  children: [
    Icon(
      Icons.info_outline_rounded,
      size: 18,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
    const SizedBox(width: 8),
    Expanded(
      child: Text(
        'Type at least two letters for city suggestions.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  ],
);
```

b) The error fallback "We can't load city suggestions right now." gets
   this concrete row treatment with `Icons.error_outline_rounded` and
   `colorScheme.error` for the icon. Leave the text colour default:

```dart
Row(
  children: [
    Icon(
      Icons.error_outline_rounded,
      size: 18,
      color: Theme.of(context).colorScheme.error,
    ),
    const SizedBox(width: 8),
    Expanded(
      child: Text(
        "We can't load city suggestions right now.",
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ),
  ],
);
```

c) The loading branch stays as a centred `CircularProgressIndicator`
   inside vertical padding — fine.

---

# Change 7 — Country dropdown row: token-align flag chip

Inside the country `DropdownMenuItem`, the `_CountryFlagIcon` chip
currently has `EdgeInsets.symmetric(horizontal: 10, vertical: 6)` and
`BorderRadius.circular(12)`. Bump:

- `BorderRadius.circular(12)` → `BorderRadius.circular(10)` so the chip
  reads as a small rectangle, not a pill — it's a 18px icon, the larger
  radius makes it look bubble-y.

That's the only change to `_CountryFlagIcon`. The `Icon(Icons
.flag_outlined, size: 18, color: primary)` stays — it's a placeholder
until real flags ship.

---

# Change 8 — Section spacing between the two cards

The current code uses `SizedBox(height: AppTheme.sectionSpacing(compact:
true))` between "Your area" and "Suggested cities" — already correct.
Verify this remains after edits.

The "Suggested cities" card outer padding is currently `AppTheme
.sectionPadding(compact: true)` — leave that unchanged.

The `SizedBox(height: 12)` between the section title and the
suggestions body becomes `SizedBox(height: AppTheme.cardGap)`.

---

# Acceptance checklist

- AppBar title is `SizedBox.shrink()`. Back arrow remains.
- "Your area" card description picks up `colorScheme.onSurfaceVariant`.
  Major spacers between dropdowns / inputs use `AppTheme.cardGap`. The
  spacer above the FilledButton is `AppTheme.sectionGap`.
- Save button is wrapped in `SizedBox(height: 48)` and shows an inline
  spinner + "Saving…" during save.
- `_SelectedCityCard` fill softens to `primaryContainer @ 0.32`, gains
  a `primary @ 0.18` border, uses `EdgeInsets.all(AppTheme.cardPadding)`,
  and the icon is `check_circle_rounded`.
- Suggested cities are rendered as tight `InkWell` rows with a place
  icon, two-line city/district stack, and a 20px chevron — `ListTile`
  is removed.
- The "Type at least two letters…" hint and the error string both pick
  up a leading icon and `onSurfaceVariant` text.
- `_CountryFlagIcon` chip uses `BorderRadius.circular(10)`.
- Spacing between the two cards is `AppTheme.sectionSpacing(compact:
  true)`. Title→body gap inside Suggested cities is `AppTheme.cardGap`.
- `flutter analyze` is clean.
- A visual review run produces a `location_completion__run-XXXX…png`
  whose hierarchy reads: empty AppBar with back arrow → "Your area"
  card with country/city/zip/switch/CTA/helper → softer "Selected
  city" chip when applicable → "Suggested cities" card with tight
  list rows.
