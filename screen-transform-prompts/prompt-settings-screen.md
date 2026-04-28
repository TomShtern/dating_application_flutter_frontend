Target file: lib/features/settings/settings_screen.dart

Design reference: docs/design-language.md (utility/settings archetype,
ShellHero usage, AppTheme tokens, semantic colour tokens)

You are a Flutter frontend engineer. Your task is to visually refine the
SettingsScreen at `lib/features/settings/settings_screen.dart`. Do not
change providers, controllers, navigation logic, or the
`selectUserControllerProvider` / `appPreferencesControllerProvider`
contracts. Keep `_label` and `_description` exactly as written.

Constraints (read first):
- This is a bottom-nav tab screen rendered inside `SignedInShell`.
  The body must NOT wrap itself in a second `Scaffold(appBar: AppBar)`.
- Utility/settings archetype: a `ShellHero` is the screen anchor; section
  cards live inside a single scroll surface below it.
- Use `AppTheme` tokens (`cardRadius`, `panelRadius`, `chipRadius`,
  `pagePadding`, `cardPadding`, `cardGap`, `sectionGap`, `screenPadding`,
  `sectionPadding`, `sectionSpacing`, `listSpacing`, `surfaceDecoration`,
  `softShadow`).
- The `DeveloperOnlyCalloutCard` amber chrome is a deliberate dev-only
  signal — do NOT swap it for `surfaceDecoration` or restyle the amber.
- Don't invent token names. If a helper isn't in
  `lib/theme/app_theme.dart`, leave the existing literal.

---

# Change 1 — Drop the `Scaffold` + `AppBar` wrapper, add a `ShellHero`

Today the screen wraps a `ListView` in `Scaffold(appBar: AppBar(title:
Text('Settings')))`. Inside `SignedInShell`, this stacks a second AppBar
on top of the tab chrome.

Replace the `Scaffold` with `SafeArea(top: false)` and put a `ShellHero`
above the list:

```dart
return SafeArea(
  top: false,
  child: Column(
    children: [
      ShellHero(
        eyebrowLabel: 'Account',
        title: 'Settings',
        subtitle: 'Profile, appearance, and quick access.',
      ),
      Expanded(
        child: ListView(
          padding: AppTheme.screenPadding(),
          children: [
            _SettingsSessionCard(...),
            SizedBox(height: AppTheme.sectionSpacing()),
            _SettingsSectionCard(... 'Quick access' ...),
            SizedBox(height: AppTheme.sectionSpacing()),
            _SettingsSectionCard(... 'Appearance' ...),
            SizedBox(height: AppTheme.sectionSpacing(compact: true)),
          ],
        ),
      ),
    ],
  ),
);
```

If `ShellHero`'s parameter names differ, read
`lib/shared/widgets/shell_hero.dart` and adapt — the visual result must
match: an eyebrow label above a bold title, a one-line subtitle, no
trailing widget (settings has no global refresh).

The list's outer padding becomes `AppTheme.screenPadding()` instead of
the hand-rolled `EdgeInsets.fromLTRB(pagePadding, pagePadding,
pagePadding, 28)`. The bottom 28 was hand-tuned; rely on the
`screenPadding` token plus a final `SizedBox(height:
AppTheme.sectionSpacing(compact: true))` at the end of the list to
provide breathing room above the bottom nav.

---

# Change 2 — `_SettingsSectionCard`: tokenise paddings

The section card currently uses `EdgeInsets.all(16)` outer padding and
`SizedBox(height: 16)` between header and child.

Replace:
- Outer padding → `EdgeInsets.all(AppTheme.cardPadding)`.
- Header→child spacer → `SizedBox(height: AppTheme.cardGap)`.
- The leading icon container's `BorderRadius.circular(16)` and
  `EdgeInsets.all(10)` stay — they match `_PresentationContextCard` and
  `_PhotoSection` in the profile screen.

The `colorScheme.surface.withValues(alpha: 0.9)` tint on the
`surfaceDecoration` stays — it's the intentional translucent stack used
across utility cards. Do not remove the alpha.

---

# Change 3 — `_SettingsLinkTile`: align the chevron + tighten typography

The link tile renders `[icon chip] [title / subtitle column] [chevron]`.
Two refinements:

a) **Centre the chevron vertically.** Today it sits at the row's default
   alignment, which floats slightly high when the subtitle wraps to two
   lines (see "Notifications" tile in the screenshot). Wrap the
   `Icon(Icons.chevron_right_rounded, …)` in a `SizedBox.square(dimension:
   24)` so it occupies a fixed-size box, and set the parent `Row` to
   `crossAxisAlignment: CrossAxisAlignment.center`.

b) **Subtitle colour.** Change the subtitle `Text` style to
   `Theme.of(context).textTheme.bodyMedium?.copyWith(color:
   colorScheme.onSurfaceVariant)` so it visually de-emphasises against
   the title. The current default `bodyMedium` is too close to the
   title weight.

c) The icon chip's `BorderRadius.circular(14)` and `EdgeInsets.all(9)`
   stay — they're tuned smaller than the section header chip on
   purpose.

d) `ConstrainedBox(minHeight: 56)` stays — it's the canonical Material
   list-tile height token.

---

# Change 4 — `_SettingsLinkTile`: replace the `Divider(height: 1)` between tiles

The Quick access section currently inserts `const Divider(height: 1)`
between each `_SettingsLinkTile`. The dividers compress against the tile
padding and read as noise on the soft surface decoration.

Replace each `Divider(height: 1)` with:

```dart
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 4),
  child: Divider(
    height: 1,
    thickness: 1,
    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
  ),
),
```

This pulls the divider in from the card edge (matching the icon chip's
4px horizontal padding inside the tile) and softens it to ~40% alpha so
it reads as a separator hint rather than a hard rule.

---

# Change 5 — `_SettingsSessionCard`: align avatar with name baseline

The session card currently sets `crossAxisAlignment:
CrossAxisAlignment.start` on its inner `Row`, which pushes the
24-radius avatar to the very top while the name "Dana" sits one line
below. Switch to `CrossAxisAlignment.center` so the avatar centres
against the name + subtitle column.

Add `maxLines: 1, overflow: TextOverflow.ellipsis` to the name `Text`
so a long display name does not push the layout.

Do not touch the `DeveloperOnlyCalloutCard` widget itself or the amber
styling — only the inner `Row` is being adjusted.

---

# Change 6 — Appearance section: tokenise the description box

The description box currently uses `EdgeInsets.all(16)` and a custom
`BorderRadius.all(Radius.circular(24))`. The 24 radius is bigger than
the surrounding section card's `cardRadius` (20), making the inner box
look like a different surface family.

Change:
- The description box `BorderRadius.circular(24)` →
  `AppTheme.panelRadius` (which equals `cardRadius` = 20). If
  `panelRadius` is not exposed, use `AppTheme.cardRadius`.
- The description box `EdgeInsets.all(16)` → `EdgeInsets.all(AppTheme
  .cardPadding)`.
- The `SizedBox(height: 16)` between the SegmentedButton and the
  description box → `SizedBox(height: AppTheme.cardGap)`.

The translucent surface fill `colorScheme.surface.withValues(alpha:
0.84)` stays — it visually sets the description apart from the
SegmentedButton without reading as a separate card.

---

# Change 7 — Add a section gap above the bottom edge

Today the list ends abruptly with the Appearance card and a 28dp bottom
padding. With the screen padding now token-driven, append one final
`SizedBox(height: AppTheme.sectionSpacing(compact: true))` at the end
of the children list so the last card has consistent breathing room
against the bottom-nav.

If `screenPadding()` already includes a sufficient bottom value (verify
in `lib/theme/app_theme.dart`), skip this — the change exists to
replace the hand-rolled `28` only.

---

# Acceptance checklist

- The screen no longer wraps its body in `Scaffold(appBar: AppBar)`. A
  `ShellHero` ("Account" / "Settings" / one-line subtitle) sits above
  an `Expanded ListView` with `AppTheme.screenPadding()`.
- `_SettingsSectionCard` outer padding is
  `EdgeInsets.all(AppTheme.cardPadding)`; the header→child spacer is
  `AppTheme.cardGap`. The translucent surface tint is unchanged.
- `_SettingsLinkTile`'s chevron sits inside a `SizedBox.square(24)` with
  the parent Row set to `CrossAxisAlignment.center`. The subtitle
  `Text` uses `colorScheme.onSurfaceVariant`.
- The `Divider(height: 1)` separators are wrapped in horizontal-4
  padding and softened to `outlineVariant @ 0.4 alpha`.
- `_SettingsSessionCard`'s inner Row is `CrossAxisAlignment.center`.
  The name `Text` ellipsises on a single line. The amber
  `DeveloperOnlyCalloutCard` chrome is unchanged.
- The Appearance description box uses `panelRadius` /
  `EdgeInsets.all(AppTheme.cardPadding)`. Its 0.84-alpha surface tint
  is unchanged.
- The hand-rolled `28` bottom padding is removed; the list ends with a
  `SizedBox(height: AppTheme.sectionSpacing(compact: true))`.
- `flutter analyze` is clean.
- A visual review run produces a `shell_settings__run-XXXX…png` whose
  hierarchy reads: ShellHero → amber dev-session card → Quick access
  card with vertically centred chevrons and softened dividers →
  Appearance card with segmented button + description tile.
