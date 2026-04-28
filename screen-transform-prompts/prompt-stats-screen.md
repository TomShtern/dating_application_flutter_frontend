Target file: lib/features/stats/stats_screen.dart

Design reference: docs/design-language.md (data screen archetype, §7.1 section label pattern, semantic colour tokens)

You are a Flutter frontend engineer. Your task is to visually refine the
StatsScreen at `lib/features/stats/stats_screen.dart`. Do not change
providers, models, API calls, or `showStatDetailSheet` behaviour. The
existing private widgets (`_StatsOverviewCard`, `_SnapshotGrid`,
`_SnapshotStatTile`, `_PerformanceStatCard`, `_StatIconChip`,
`_AnimatedStatValue`, `_AnimatedIntText`, `_RadialMetric`,
`_RadialMetricPainter`, `_SparkBars`, `_StatVisualSpec`,
`_tryParsePercent`, `_sparkValues`) stay — only their styling is
adjusted where called out.

Constraints (read first):
- This is a pushed screen, so an `AppBar` is required for the back button.
- The `_StatsOverviewCard` is the visual hero. Do not introduce a
  `ShellHero` on top of it.
- Keep `RefreshIndicator` and the existing scroll/list structure.
- Use `AppTheme` tokens and helpers wherever they exist (`cardRadius`,
  `panelRadius`, `chipRadius`, `cardGap`, `pagePadding`, `cardPadding`,
  `sectionGap`, `surfaceDecoration`, `softShadow`, `floatingShadow`,
  `screenPadding`, `sectionPadding`, `sectionSpacing`, `listSpacing`).
- Resolve semantic colours with `AppTheme.activeGreen`,
  `AppTheme.matchOrange`, `AppTheme.matchPink`, `AppTheme.matchCoral`
  if any of those exist in `lib/theme/app_theme.dart`. If a token isn't
  defined in `app_theme.dart`, leave the existing literal in place
  rather than guessing a name.

---

# Change 1 — AppBar: remove the duplicated title

The screen currently shows `AppBar(title: Text('Stats', …))` directly
above a colourful gradient overview card whose primary text is
"Momentum for {currentUser.name}". The title is redundant.

Replace the AppBar with an unstyled bar that keeps the back affordance
and the two actions only:

```dart
appBar: AppBar(
  title: const SizedBox.shrink(),
  backgroundColor: Colors.transparent,
  elevation: 0,
  scrolledUnderElevation: 0,
  actions: [
    Tooltip(
      message: 'View achievements',
      child: IconButton(
        onPressed: () { /* unchanged */ },
        icon: const Icon(Icons.workspace_premium_outlined),
      ),
    ),
    Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: 'Refresh stats',
        child: IconButton(
          onPressed: () => ref.invalidate(statsProvider),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ),
    ),
  ],
),
```

Do not remove the actions — they remain available so the achievements
CTA pill and the manual refresh stay reachable when the user has
scrolled past the hero card.

---

# Change 2 — `_StatsOverviewCard`: tokenise the layout & tighten the metric block

The card today uses `EdgeInsets.fromLTRB(18, 18, 18, 16)` and an inner
`SizedBox(height: 14)` for the section spacer. Replace those with the
existing tokens:

- Outer padding: `EdgeInsets.all(AppTheme.cardPadding)`
- Vertical spacer between metric row and pills: `SizedBox(height: AppTheme.sectionGap)`

Keep the gradient hero as-is (the pink → lavender → blue gradient is the
intentional "momentum" palette for this screen and must NOT be replaced
with `accentGradient`).

For the trailing flame container, replace the hand-rolled
`DecoratedBox` + manual `BoxShadow` with `AppTheme.glassDecoration(context)`
to match the pill chrome used elsewhere on the gradient hero, but keep
the size / icon / colour:

```dart
DecoratedBox(
  decoration: AppTheme.glassDecoration(context).copyWith(
    borderRadius: AppTheme.cardRadius,
  ),
  child: const Padding(
    padding: EdgeInsets.all(12),
    child: Icon(
      Icons.local_fire_department_rounded,
      color: Color(0xFFE35D4F),
      size: 30,
    ),
  ),
),
```

If `glassDecoration` is hard-coded to `chipRadius` and the result looks
wrong with a circular flame container, fall back to the original
DecoratedBox but use `AppTheme.softShadow(context)` for the shadow list
instead of the hand-rolled `BoxShadow`.

The deep-purple text colour `Color(0xFF4C2F88)` used on the highlights
number and "highlights" word stays — it is tuned to the gradient.

---

# Change 3 — `_StatsSummaryPill` row: replace the Achievements pill with a real CTA

Right now both "Active profile" status AND the Achievements navigation
are rendered as identical-looking pills in a `Wrap`. The Achievements
entry is the only navigation off this card and currently looks
indistinguishable from a status badge.

Restructure the bottom row of `_StatsOverviewCard` so the status pill
sits on the left and a `FilledButton.icon` for Achievements sits on the
right of the same row:

```dart
Row(
  children: [
    _StatsSummaryPill(
      icon: active
          ? Icons.check_circle_rounded
          : Icons.info_outline_rounded,
      label: '${formatDisplayLabel(currentUser.state)} profile',
      backgroundColor: active
          ? const Color(0xFFDDF8E7)
          : Colors.white.withValues(alpha: 0.7),
      foregroundColor: active
          ? const Color(0xFF167442)
          : colorScheme.onSurface,
    ),
    const Spacer(),
    FilledButton.icon(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) =>
                AchievementsScreen(currentUser: currentUser),
          ),
        );
      },
      icon: const Icon(Icons.workspace_premium_rounded, size: 18),
      label: const Text('Achievements'),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        foregroundColor: const Color(0xFF9A4B00),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(999)),
        ),
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  ],
),
```

When you do this, **delete** the `_AchievementsCta` widget and remove
its sole call site. The `_StatsSummaryPill` widget itself stays — the
status pill still uses it.

---

# Change 4 — `_SnapshotStatTile`: align the icon chip / value typography

The snapshot tile already has the correct shape (top accent bar,
icon chip, sparkline pill, value, label). Two refinements:

a) Replace the hand-rolled top accent `Container(height: 4, color: …)`
   with a slightly thicker bar that picks up `cardRadius` continuity at
   the top corners:

   ```dart
   ClipRRect(
     borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
     child: Container(
       height: 4,
       decoration: BoxDecoration(
         gradient: LinearGradient(
           colors: [
             spec.color.withValues(alpha: 0.85),
             spec.color.withValues(alpha: 0.55),
           ],
         ),
       ),
     ),
   ),
   ```

   `Radius.circular(20)` matches `AppTheme.cardRadius`; if that constant
   is exposed numerically in `app_theme.dart`, prefer the constant over
   the literal `20`.

b) The fixed `SizedBox(height: 100)` on the inner column survives many
   value lengths but truncates two-line labels when the value is long.
   Increase to `height: 108` to give two-line labels breathing room
   without changing the grid rhythm.

Do NOT change the `_AnimatedStatValue` typography or the staggered
`Duration(milliseconds: 500 + index * 80)` — the staggered count-up is
intentional.

---

# Change 5 — `_PerformanceStatCard`: tighten and align with snapshot tiles

a) The current card uses `EdgeInsets.fromLTRB(14, 12, 12, 12)`. Replace
   with `EdgeInsets.fromLTRB(AppTheme.cardPadding, 14, AppTheme.cardPadding, 14)`.

b) Add a left accent bar similar to the section label so the
   performance row visually echoes the top accent on snapshot tiles.
   Wrap the existing `Padding(...)` body in a `Row` whose first child is:

   ```dart
   Container(
     width: 4,
     height: 56,
     margin: const EdgeInsets.only(left: 0, right: 12, top: 4, bottom: 4),
     decoration: BoxDecoration(
       color: spec.color.withValues(alpha: 0.85),
       borderRadius: const BorderRadius.all(Radius.circular(999)),
     ),
   ),
   ```

   Insert it BEFORE the existing `_StatIconChip(spec: spec, size: 40)`,
   and remove the `SizedBox(width: 12)` that previously sat between
   the chip and the column (the bar's `right: 12` margin replaces it).

c) Where the radial metric is shown (`_RadialMetric(value: percent, color: spec.color)`),
   wrap it in a `Tooltip(message: 'Tap for details')` so users discover
   the tile is interactive. Same for the `_SparkBars` fallback.

---

# Change 6 — `_SectionLabel`: extract spacing constants

The `_SectionLabel` currently uses `width: 3`, `SizedBox(width: 10)`,
`SizedBox(width: 12)`, alpha `0.85` and `0.45`. These already match the
canonical §7.1 section label spec — leave them unchanged.

The only fix here is the surrounding spacing in `_StatsDashboard.build`:
replace `const SizedBox(height: 10)` after each section label with
`SizedBox(height: AppTheme.cardGap)` so the label-to-content rhythm uses
the token instead of a literal.

---

# Change 7 — Empty-state copy

The current empty state reads "No stats are available for this user yet."
Replace with a more on-brand line that matches the screen's tone:

```dart
const AppAsyncState.empty(
  message:
      'Stats start populating after a few likes, matches, and conversations. Check back once you\'ve been active.',
),
```

---

# Acceptance checklist

- AppBar shows back affordance and the two actions only — no "Stats" title.
- The hero gradient palette and the deep-purple `0xFF4C2F88` highlight
  number/label colour are unchanged.
- The bottom row of the overview card has a status pill on the left
  and a `FilledButton.icon` "Achievements" on the right; the
  `_AchievementsCta` widget has been deleted and is no longer
  referenced.
- Snapshot tiles have a clipped gradient accent on top and 108px tall
  inner content area.
- Performance cards have a left accent bar in the same colour family as
  the icon chip; the radial metric / spark fallback is wrapped in a
  Tooltip.
- All hard-coded paddings replaced with `AppTheme.cardPadding`,
  `AppTheme.cardGap`, `AppTheme.sectionGap`, `AppTheme.sectionSpacing()`
  where applicable. The section label internals stay verbatim (§7.1
  spec).
- `flutter analyze` is clean.
- A visual review run produces a `stats__run-XXXX…png` whose hierarchy
  reads: gradient hero with prominent Achievements button → Snapshot
  section label → 2x2 snapshot grid → Performance section label →
  vertical performance cards.
