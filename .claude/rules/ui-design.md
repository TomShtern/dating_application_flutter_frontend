---
paths:
  - "lib/theme/**"
  - "lib/shared/widgets/**"
  - "lib/features/**"
  - "docs/design-language.md"
---

## UI and design

`docs/design-language.md` is the canonical visual reference — spacing, surfaces,
shared widgets, hero selection, interaction rules. Read it before changing screen
composition, `AppTheme` usage, colours, typography or spacing. Use it as the
review rubric, not loose inspiration.

For per-screen intent (hero choice, layout, copy tone, do/don't) see
`screen-transform-prompts/prompt-<screen-name>.md` before redesigning a covered
screen.

**Find the design spec before redesigning.** Iterative
"fix-the-screenshot-complaint" rounds silently remove spec-mandated elements.
Treat a complaint as "where did we drift from the spec", not "abandon the spec".

### Shared widgets

`lib/shared/widgets/` **is** the inventory — list the directory rather than
trusting any enumeration, including this one. Purposes, for selection:

| Widget | Purpose |
|---|---|
| `ShellHero` | full-width hero header for tab and detail screens |
| `AppRouteHeader` | pushed-route header: back + title/subtitle + trailing |
| `SectionIntroCard` | framing card for sparse or utility screens |
| `AppGroupLabel` | sectioned list label, accent rail + optional count |
| `AppAsyncState` | unified loading / error / empty renderer |
| `PersonPhotoCard` | person card: avatar + name/age/location |
| `UserAvatar` | circular avatar, ring, monogram fallback |
| `PersonMediaThumbnail` | rectangular thumbnail with gradient fallback |
| `AppNetworkImage` | cached network image; DPR-aware cache sizing, fallback builder |
| `CompactContextStrip` | single-line metadata: icon + label |
| `CompactSummaryHeader` | name + subtitle + action row |
| `CompatibilityMeter` | 0-100 score bar with colour-coded label |
| `HighlightTagRow` | horizontally scrollable chip row |
| `ViewModeToggle` | list/grid segmented toggle |
| `AppOverflowMenuButton` | generic kebab popup menu |
| `DeveloperOnlyCalloutCard` | amber dev-only surface, for dev flows |

Prefer these over feature-local clones of the same structure.

### AppTheme tokens

`AppTheme` (`lib/theme/app_theme.dart`) — prefer these over inline
`BoxDecoration` / `BoxShadow` literals and magic numbers:

- Gradients: `heroGradient`, `accentGradient`, `avatarGradient`
- Match palette: `matchAccent`, `matchAccentSecondary`, `matchTintColor`,
  `activeColor`, `matchTextPrimary/Secondary/Tertiary`
- Shadows: `softShadow`, `floatingShadow`
- Decorations: `surfaceDecoration(context, {gradient, prominence})`,
  `glassDecoration`
- Spacing: `screenPadding`, `sectionPadding`, `sectionSpacing`, `listSpacing`
  (each has a `compact:` variant)
- Bottom-nav-aware scroll padding: `shellScrollPadding()` for tab screens,
  `bottomActionScrollPadding()` for fixed bottom action bars. Use these instead
  of hand-rolling bottom inset math.

Keep semantic colour usage consistent across repeated metric categories rather
than reassigning hues per screen. Use `Material` + `InkWell` for tappable
surfaces, never a raw `GestureDetector` for card-like interactions.

### Active design direction (2026-04-23 overhaul brief)

People-first surfaces; less purple/lavender dominance; warmer and more varied
visual language; less redundant shell chrome; overflow menus for
contextual/safety actions instead of ambiguous shield icons; compact,
information-rich cards; developer-only controls visually separated and labeled;
no invented compatibility logic or reasons in Dart.

Start screens with the right hero: `ShellHero` for navigation/social screens,
`SectionIntroCard` for sparse utility screens, data-summary hero cards only for
data-rich surfaces such as stats/achievements.

Judge UI from screenshots, never from widget tests alone.
