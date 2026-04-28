# Design Language — Flutter Dating App

Extracted from the Stats screen (run-0047) as the primary reference, supplemented by the full shared widget system in `lib/shared/widgets/`.

---

## 1. Design Philosophy

**Soft, expressive, and data-forward.** The UI leans warm, using pastel gradients and semantically coloured accents to give each piece of information its own personality while staying coherent as a system. Everything feels elevated but never heavy — surfaces float slightly above the background, shadows are gentle, and corners are generously rounded.

Key principles:
- Every screen starts with a **hero summary widget** that anchors the user in context.
- Data is **colour-coded semantically** so the eye can navigate without reading labels.
- **Animated entry values** (count-up, ring fill, bar grow) make data screens feel alive on load.
- Interactivity is revealed through **InkWell ripple on all tappable surfaces** — never a raw `GestureDetector`.
- Labels are secondary; **numbers and names are primary**. Numbers are always bolder, larger, and coloured; labels are dimmed to `onSurfaceVariant`.

---

## 2. Spacing & Layout System

All spacing comes from `AppTheme` static constants. Never write magic numbers.

| Token                        | Value | Use case                                     |
|------------------------------|-------|----------------------------------------------|
| `AppTheme.pagePadding`       | 18 px | Outer `ListView` / `Column` padding          |
| `AppTheme.compactPagePadding`| 14 px | Denser screens (pickers, settings)           |
| `AppTheme.cardGap`           | 10 px | Gap between sibling cards in a grid or list  |
| `AppTheme.compactCardGap`    |  8 px | Compact grid gaps                            |
| `AppTheme.sectionGap`        | 14 px | Vertical gap between major sections          |
| `AppTheme.cardPadding`       | 16 px | Internal card content padding                |
| `AppTheme.compactCardPadding`| 14 px | Compact internal padding                     |
| `AppTheme.navBarHeight`      | 64 px | Fixed bottom navigation bar height           |

Use `AppTheme.screenPadding()`, `AppTheme.sectionPadding()`, `AppTheme.sectionSpacing()`, `AppTheme.listSpacing()` as `EdgeInsets` / `double` helpers. All have a `compact: true` variant.

---

## 3. Border Radius

| Token                  | Value     | Use case                                     |
|------------------------|-----------|----------------------------------------------|
| `AppTheme.panelRadius` | 20 px     | Primary cards, content panels, sheets        |
| `AppTheme.cardRadius`  | 20 px     | Secondary cards, icon bubbles                |
| `AppTheme.chipRadius`  | 999 px    | Pills, badges, segmented buttons, chips      |

Do **not** use inline `BorderRadius.circular(…)` values — always reference these tokens.

---

## 4. Surface System

### Standard surface (cards, tiles)
```dart
AppTheme.surfaceDecoration(context,
  color: colorScheme.surface,
  prominent: false,   // → softShadow, thin border
)
```

### Elevated hero surface (overview / summary cards)
```dart
AppTheme.surfaceDecoration(context,
  gradient: yourGradient,
  prominent: true,    // → floatingShadow, slightly stronger border
)
```

### Glass pill / badge surface
```dart
AppTheme.glassDecoration(context)
// surface × 0.7, chipRadius, thin outlineVariant × 0.20 border
// Used for ShellHeroPill and floating labels over gradients
```

### Shadows
- `softShadow(context)` — `blurRadius: 16`, `offset: (0, 4)`, opacity `0.08` light / `0.22` dark
- `floatingShadow(context)` — `blurRadius: 16`, `offset: (0, 6)`, opacity `0.12` light / `0.30` dark

### Surface border alpha
- `prominent: false` → `outlineVariant × 0.18`
- `prominent: true` → `outlineVariant × 0.32`

---

## 5. Color Palette

### Base brand palette (from `AppTheme`)

| Name               | Light      | Dark       |
|--------------------|------------|------------|
| `matchPink`        | `#B85C78`  | —          |
| `matchCoral`       | `#C77768`  | —          |
| `matchOrange`      | `#D49A62`  | —          |
| `activeGreen`      | `#16A871`  | `#35C98E`  |
| `matchBackground`  | `#FFF8F8`  | `#111820`  |
| `matchTint`        | `#F9E8EE`  | `#1D2A35`  |
| `textPrimary`      | `#1A1A2E`  | `#F6EDF4`  |
| `textSecondary`    | `#555B66`  | `#CDD6D2`  |
| `textTertiary`     | `#858B96`  | `#9AA4A6`  |

The theme seed color is `matchPink` in light mode. `ColorScheme.fromSeed` derives all Material 3 tonal roles automatically.

### Hero gradients — choosing the right one

| Gradient | When to use |
|----------|-------------|
| `AppTheme.heroGradient(context)` — `surface` → `surfaceContainerLow`, adapts to dark | `ShellHero` on tab and navigation-entry screens. Default choice. |
| `AppTheme.accentGradient(context)` — `matchPink` → `matchCoral` → `matchOrange` (light) / blue-slate-amber (dark) | Accent banners, onboarding, CTA sections |
| Custom data gradient below | Data-rich summary cards (Stats, Achievements) only |

**Stats overview card gradient (data-summary screens only):**
```dart
LinearGradient(
  colors: [
    Color(0xFFFF99C2).withValues(alpha: 0.97),  // soft pink
    Color(0xFFC8AEFF).withValues(alpha: 0.96),  // lavender
    Color(0xFFADC8FF).withValues(alpha: 0.94),  // periwinkle
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)
```
This is expressive and intentional — do not use it as a general hero background.

### Semantic stat colors

Each data category has a dedicated hue. Use these consistently whenever the same category appears on any screen.

| Category                   | Color hex  | Description       |
|----------------------------|------------|-------------------|
| Likes / activity sent      | `#FF7043`  | Coral-orange      |
| Likes / affinity received  | `#E24A68`  | Rose-crimson      |
| Matches — cumulative       | `#7C4DFF`  | Deep violet       |
| Matches — this week        | `#5B6EE1`  | Indigo-blue       |
| Conversations / chat       | `#009688`  | Teal              |
| Reply rate / quality       | `#2E9D57`  | Forest green      |
| Response time              | `#D98914`  | Amber             |
| Profile views              | `#188DC8`  | Sky blue          |
| Fallback / generic stat    | `#596579`  | Slate grey        |

### Pill / badge colors

| Use case         | Background   | Foreground   |
|------------------|-------------|--------------|
| Active status    | `#DDF8E7`   | `#167442`    |
| Achievements CTA | `#FFE3C2`   | `#9A4B00`    |
| Hero fire icon bubble | `white × 0.82` | `#E35D4F` (icon) |
| Deep accent text (hero count) | — | `#4C2F88` |

---

## 6. Typography System

All styles inherit from `AppTheme._textTheme()` which layers custom weights, tracking, and line-heights onto the Material 3 base.

| Role              | Weight      | Letter spacing | Use case                                          |
|-------------------|-------------|---------------|---------------------------------------------------|
| `displaySmall`    | w800        | —             | Hero count (e.g. "8 highlights")                  |
| `headlineMedium`  | w800        | −0.9          | Primary metric value in tiles                     |
| `headlineSmall`   | w800        | −0.7          | Alternative metric value                          |
| `titleLarge`      | w700        | −0.4          | Hero card title, ShellHero title                  |
| `titleMedium`     | w700 / w800 | −0.2          | Section labels (w800), card titles, list headers  |
| `labelLarge`      | w700        | +0.1          | Tile labels, pill text, button text               |
| `labelMedium`     | w600        | —             | Secondary labels, nav bar labels (inactive)       |
| `bodyMedium`      | default     | —             | Description text, `ShellHero` description         |
| `bodySmall`       | w500        | +0.1          | Subtitle / meta lines, `CompactContextStrip`      |

**Key rules:**
- Metric values → colour-matched to semantic color, `FontWeight.w700`
- Supporting labels → `colorScheme.onSurfaceVariant`, weight matches context
- Hero titles → `onSurface` (theme-aware), never hardcoded black

---

## 7. Feature Component Patterns

These patterns are assembled from `AppTheme` primitives. For cross-screen shared components, see §8.

### 7.1 Section Label
Vertical accent bar + bold title + fading horizontal rule.

```dart
IntrinsicHeight(
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        width: 3,
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.85),
          borderRadius: BorderRadius.all(Radius.circular(999)),
        ),
      ),
      const SizedBox(width: 10),
      Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(width: 12),
      Expanded(
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.45)),
        ),
      ),
    ],
  ),
)
```

### 7.2 Stat / Data Tile (grid, two-column)

- `Material(clipBehavior: Clip.antiAlias)` wrapper → `InkWell` ripple clipped to rounded corners
- `Ink(decoration: surfaceDecoration(...))` → paints background inside the clip
- **Full-width top color bar** `height: 4`, `spec.color × 0.70`
- Icon chip (§7.4, size 32) top-left
- Decorated spark-bar pill top-right: `spec.color × 0.08` background, `borderRadius: chipRadius`, inner padding `fromLTRB(7, 5, 7, 5)`
- Large animated value bottom-left, coloured (`headlineMedium w700`)
- Dimmed label (`onSurfaceVariant`, `labelLarge w600`) below value with `SizedBox(height: 7)`
- Fixed inner height `SizedBox(height: 100)` keeps all tiles uniform

### 7.3 Performance / List Card (full-width row)

- Same `Material` + `InkWell` + `Ink` pattern
- Left: `StatIconChip` (40×40), padding `fromLTRB(14, 12, 12, 12)`
- Center: `Expanded` column — label (`titleMedium w600`) above, animated value below, `SizedBox(height: 3)` gap
- Right: `_RadialMetric(64×64)` for `%` values; `_SparkBars(52×36)` for raw counts

### 7.4 Icon Chip

Rounded square, `spec.color × 0.16` fill, corner radius `size × 0.42`, icon size `size × 0.56`.

```dart
DecoratedBox(
  decoration: BoxDecoration(
    color: spec.color.withValues(alpha: 0.16),
    borderRadius: BorderRadius.all(Radius.circular(size * 0.42)),
  ),
  child: SizedBox.square(
    dimension: size,
    child: Icon(spec.icon, color: spec.color, size: size * 0.56),
  ),
)
```

### 7.5 Action Pill / Status Badge

`chipRadius` shape. `DecoratedBox(color, border: foreground × 0.12)` + `InkWell(borderRadius: chipRadius)`. 18 px icon, `labelLarge` text. Padding: 12 px horizontal, 8 px vertical.

### 7.6 Data-Summary Hero Card (Stats / Achievements)

For data-rich screens where the hero needs to communicate aggregated numbers. **Not for general navigation screens** — use `ShellHero` there (§8.1).

Structure:
- `DecoratedBox(decoration: surfaceDecoration(gradient: dataSummaryGradient, prominent: true))`
- Top row: `Expanded` text column (title `titleLarge w700` + `bodySmall` meta row with `sync_rounded` 12 px icon) + floating icon bubble
- Floating icon bubble: `white × 0.82`, `cardRadius`, shadow `black × 0.08 / blur 8 / offset (0,2)`
- Count row: `displaySmall w800` animated count in `#4C2F88` + baseline-aligned `titleMedium` label
- Bottom: `Wrap(spacing: 8, runSpacing: 8)` of action pills

### 7.7 Spark Bars

5-bar mini bar chart. Heights deterministic from `seed` string hash (reproducible). Last bar `opacity 0.92`, others `0.58`. Fully rounded caps. Animated `0→1` over 700 ms `easeOutCubic`.

```dart
_SparkBars(color: spec.color, seed: item.value, width: 52, height: 36)
// Snapshot tile pill variant: width: 34, height: 18
```

### 7.8 Radial Progress Ring

64×64 `CustomPainter`. Track `color × 0.18`, value arc clockwise from 12 o'clock. `strokeWidth: 6`, `StrokeCap.round`. Centre label: `labelLarge w800`. Animated `0→value` over 760 ms `easeOutCubic`.

---

## 8. Shared Widget System

These live in `lib/shared/widgets/`. **Always use them — never reinvent equivalent structure in feature code.**

### 8.1 `ShellHero` — `shell_hero.dart`

The standard hero header for tab screens, feature entry screens, and most detail screens. Uses `AppTheme.heroGradient(context)` — adapts automatically to dark mode.

```dart
ShellHero(
  title: 'Screen Title',
  description: 'One-line description of what this screen does.',
  eyebrowLabel: 'Optional pill label above title',
  eyebrowIcon: Icons.some_icon,   // optional, shown in pill
  header: someWidget,             // optional, shown above title (e.g. avatar)
  badges: [widget1, widget2],     // optional, Wrap of action chips/pills
  footer: someWidget,             // optional, shown below badges
  compact: false,                 // true for tighter padding
  centerContent: false,           // true for centred layout (onboarding)
)
```

Internally renders two subtle `_AmbientGlow` blobs (tertiary × 0.06 and primary × 0.04) positioned off the top-right and bottom-left edges for depth.

`ShellHeroPill` is the glass label pill used inside `ShellHero.eyebrowLabel`. It uses `AppTheme.glassDecoration(context)`.

### 8.2 `SectionIntroCard` — `section_intro_card.dart`

For sparse or utility screens that don't need a full hero. Renders an icon + title + description with an optional trailing widget and badge `Wrap`. Uses a neutral `surface → surfaceContainerLow` gradient (not the expressive hero gradient).

```dart
SectionIntroCard(
  icon: Icons.some_icon,
  title: 'What this section is',
  description: 'Brief explanation.',
  trailing: someActionWidget,      // optional
  badges: [badge1, badge2],        // optional
)
```

### 8.3 `AppAsyncState` — `app_async_state.dart`

Always delegate loading / error / empty states to this widget.

```dart
AppAsyncState.loading(message: 'Loading…')
AppAsyncState.error(message: msg, onRetry: () => ref.invalidate(provider))
AppAsyncState.empty(message: 'Nothing here yet.')
```

Wrap in `Padding(padding: AppTheme.screenPadding())` when it is the only body content.

### 8.4 `PersonPhotoCard` — `person_photo_card.dart`

Horizontal person row: circular photo (or monogram fallback) + name, age, optional location. Used in Discover candidates, Matches, Pending likers, Standouts.

```dart
PersonPhotoCard(
  name: person.name,
  age: person.age,          // optional
  photoUrl: person.photoUrl, // optional; monogram fallback if null
  location: person.location, // optional
  onTap: () { … },
  trailing: someWidget,      // optional, right-aligned
  compact: false,
)
```

Photo radii: 28 px standard, 22 px compact. Fallback monogram uses `surfaceContainerHighest` background.

### 8.5 `UserAvatar` — `user_avatar.dart`

Circular avatar with a subtle `outline × 0.18` ring and inner white padding. Network image with monogram fallback. Used in conversation headers, profile rows, AppBar.

```dart
UserAvatar(name: user.name, photoUrl: user.photoUrl, radius: 24)
```

Padding: 3 px for `radius ≥ 28`, 2 px otherwise. Monogram font size: `radius × 0.72`. Animated container transition on changes.

### 8.6 `PersonMediaThumbnail` — `person_media_thumbnail.dart`

Rectangular photo thumbnail with gradient fallback. Default 96×128, corner radius 24 px.

```dart
PersonMediaThumbnail(
  name: person.name,
  photoUrl: person.photoUrl,   // optional
  width: 96,
  height: 128,
  borderRadius: BorderRadius.all(Radius.circular(24)),
)
```

Fallback gradient is per-person (name hash shifts hue) in light mode; fixed blue-slate-amber in dark mode. `emphasizeMedia: true` when a URL was present but failed to load (shows richer gradient + white monogram).

### 8.7 `CompactContextStrip` — `compact_context_strip.dart`

Single-line metadata strip: icon + label + optional trailing. Used for location, distance, age, recency, status.

```dart
CompactContextStrip(
  leadingIcon: Icons.location_on_outlined,
  label: person.location,
  trailing: someWidget,  // optional
)
```

Icon 14 px, `onSurfaceVariant`. Label `bodySmall`, `onSurfaceVariant`. Children items spaced by 6 px leading padding each.

### 8.8 `CompactSummaryHeader` — `compact_summary_header.dart`

Name + one-line subtitle + optional trailing. Used in match cards, conversation rows, notification items.

```dart
CompactSummaryHeader(
  title: person.name,
  subtitle: 'Last message or location',
  trailing: someWidget,
  dense: false,
)
```

Title: `titleMedium w700` (or `w600` when `dense`). Subtitle: `bodySmall onSurfaceVariant`. Trailing spacing: 12 px standard, 8 px dense.

### 8.9 `CompatibilityMeter` — `compatibility_meter.dart`

Score bar 0–100 with colour-coded label.

```dart
CompatibilityMeter(score: 82, label: 'Great match', compact: false)
```

Color tiers: `score ≥ 75` → `primary` (green-ish), `score ≥ 50` → `tertiary` (amber), else → `outline` (grey). Bar: 90 px × 6 px standard; 60 px × 4 px compact. Score number: `labelMedium w800` standard, `labelSmall w800` compact.

### 8.10 `HighlightTagRow` — `highlight_tag_row.dart`

Horizontally scrollable chip row for match highlights, interest tags.

```dart
HighlightTagRow(tags: ['Active today', 'Shared interests'], icon: Icons.bolt_rounded)
```

Uses the global `Chip` theme (see `AppTheme`). Returns `SizedBox.shrink()` when `tags` is empty.

### 8.11 `ViewModeToggle` — `view_mode_toggle.dart`

List / grid segmented button toggle. Compact density, 34 px height.

```dart
ViewModeToggle(isGrid: isGrid, onChanged: (value) => setState(() => isGrid = value))
```

Selected: `primaryContainer` fill, `onPrimaryContainer` foreground. Unselected: `surfaceContainerLow` fill, `onSurfaceVariant` foreground.

### 8.12 `AppOverflowMenuButton` — `app_overflow_menu_button.dart`

Generic kebab (⋮) popup menu. `Icons.more_vert` at 22 px, `onSurfaceVariant`. Menu: 12 px radius, `surfaceContainerHigh` background, elevation 4, positioned below trigger.

```dart
AppOverflowMenuButton<String>(
  items: [
    PopupMenuItem(value: 'block', child: Text('Block')),
    PopupMenuItem(value: 'report', child: Text('Report')),
  ],
  onSelected: (value) { … },
  tooltip: 'More options',
)
```

---

## 9. Animation Principles

All data-driven animations run on first appearance (no repeat). Use `TweenAnimationBuilder` for fire-and-forget entry animations — no explicit `AnimationController` needed.

| Widget / context      | Duration   | Curve          | Tween type         |
|-----------------------|------------|----------------|--------------------|
| Integer count-up      | 620 ms     | `easeOutCubic` | `IntTween`         |
| Stat value with unit  | 500–740 ms (staggered +80 ms/index) | `easeOutCubic` | `IntTween` |
| Radial ring fill      | 760 ms     | `easeOutCubic` | `Tween<double>`    |
| Spark bar grow        | 700 ms     | `easeOutCubic` | `Tween<double>`    |
| `UserAvatar` change   | 220 ms     | `easeOutCubic` | `AnimatedContainer`|

---

## 10. Interaction Model

- Every tappable surface uses `Material` + `InkWell` — never `GestureDetector`
- When clipping to rounded corners is needed: `Material(clipBehavior: Clip.antiAlias, borderRadius: …)` + `InkWell` inside — the clip contains the ripple splash
- When no clip is needed: set `InkWell(borderRadius: …)` directly — the ripple will respect the radius without clipping the child
- Tap targets open a bottom sheet or push a new route — never inline expansion
- `Tooltip` on every icon-only action (AppBar buttons, floating bubbles)
- `AppOverflowMenuButton` for contextual actions (block, report, etc.) — never a custom popup

---

## 11. Scaffold & AppBar

```dart
Scaffold(
  appBar: AppBar(
    title: Text('Screen Name',
      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
    // centerTitle: false (global AppBarTheme default)
    // backgroundColor: scaffoldBackgroundColor — no elevation, no tint
    actions: [ /* icon buttons */ ],
  ),
  body: SafeArea(child: /* content */),
)
```

Scaffold background is `matchBackground` (`#FFF8F8` light / `#111820` dark) — a faint warm tint that separates it from pure-white `surface` cards.

---

## 12. Pull-to-Refresh Pattern

```dart
RefreshIndicator(
  onRefresh: () async => ref.invalidate(myProvider),
  child: ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: AppTheme.screenPadding(),
    children: [ … ],
  ),
)
```

---

## 13. Loading / Error / Empty States

See §8.3. Always delegate to `AppAsyncState`.

---

## 14. Screen Structure Template

There are three screen archetypes — choose the right hero for each.

### Data screen (Stats, Achievements)
```
Scaffold → SafeArea → RefreshIndicator
  └── ListView (padding: screenPadding)
      ├── DataSummaryHeroCard    ← custom gradient, prominent: true
      ├── SizedBox(sectionSpacing)
      ├── _SectionLabel
      ├── SizedBox(10)
      ├── [2-col grid of data tiles, cardGap spacing]
      ├── SizedBox(sectionSpacing)
      ├── _SectionLabel
      ├── SizedBox(10)
      └── [full-width list cards, listSpacing between each]
```

### Browse / social screen (Matches, Standouts, Pending likers)
```
Scaffold → SafeArea
  └── Column
      ├── ShellHero(title, description, badges?, footer: ViewModeToggle?)
      ├── SizedBox(sectionSpacing)
      └── Expanded → RefreshIndicator → ListView / GridView
              └── [PersonPhotoCard rows or PersonMediaThumbnail grid]
```

### Utility / settings screen (Blocked users, Notifications, Verification)
```
Scaffold → SafeArea → RefreshIndicator
  └── ListView (padding: screenPadding)
      ├── SectionIntroCard(icon, title, description)
      ├── SizedBox(sectionSpacing)
      └── [full-width list items with AppAsyncState for loading/empty/error]
```

---

## 15. Semantic Color Assignment Rules

When adding new data categories, pick a hue from the table in §5 or assign a new one following these guidelines:

- **Warm hues** (coral, rose, amber) → high-emotion, social, personal metrics
- **Cool hues** (teal, green, blue) → quality, rate, relational metrics
- **Violet / indigo** → milestone, achievement, match-strength metrics
- **Slate** → fallback only; never use as a primary semantic color for a named category

**Pattern matcher ordering rule:** In `_StatVisualSpec.forLabel`, specific terms must come before general ones. The canonical example: `reply` / `rate` must precede `conversation` / `chat` because "Conversation reply rate" matches both — first-match-wins, so the more specific check goes first.

---

*Last updated: 2026-04-27 — primary reference: `lib/features/stats/stats_screen.dart`, shared widget reference: `lib/shared/widgets/`*
