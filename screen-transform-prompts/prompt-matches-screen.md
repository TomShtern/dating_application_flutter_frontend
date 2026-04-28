Target file: lib/features/matches/matches_screen.dart

Design reference: docs/design-language.md (browse/social archetype, §7.1 section
label pattern, semantic colour tokens, ShellHero usage)

You are a Flutter frontend engineer. Your task is to visually refine the
MatchesScreen at `lib/features/matches/matches_screen.dart`. Do not change
providers, controllers, models, API calls, navigation logic, or the
`matchesControllerProvider` / `matchesProvider` shape. Keep
`_primaryPhotoUrl`, `_isActive`, `_isNewMatch`, and
`_formatRelativeMatchDate` exactly as written.

Constraints (read first):
- Browse/social archetype: a `ShellHero` is the visual anchor and lives
  OUTSIDE the scroll surface. Layout MUST be
  `Column → ShellHero → (filter row?) → Expanded → RefreshIndicator → ListView`.
- This is a tab screen rendered inside `SignedInShell` — there is NO
  `AppBar`, do not add one.
- Use `AppTheme` tokens (`cardRadius`, `panelRadius`, `chipRadius`,
  `pagePadding`, `cardPadding`, `cardGap`, `sectionGap`,
  `screenPadding`, `sectionSpacing`, `listSpacing`,
  `surfaceDecoration`, `softShadow`, `floatingShadow`, `accentGradient`,
  `matchAccent`, `matchTextPrimary`, `matchTextSecondary`,
  `matchTextTertiary`, `matchTintColor`, `activeColor`, `activeGreen`).
- Never inline hex literals where an `AppTheme` semantic token already
  exists. If a token is not defined in `lib/theme/app_theme.dart`, leave
  the existing literal — do NOT invent a token name.
- The `_NewBadge` accent gradient stripe and the `_FadedBio` ShaderMask
  fade are intentional brand details. Do not redesign them.

---

# Change 1 — Replace `_MatchesHeader` with `ShellHero`

Today the screen renders a plain `Row` containing a title "Your matches",
subtitle, and a circular refresh `IconButton`. This is inconsistent with
every other tab in `SignedInShell`, which uses `ShellHero`.

Delete `_MatchesHeader` entirely and replace the call site with a
`ShellHero` configured for this tab:

```dart
ShellHero(
  eyebrowLabel: 'Connections',
  title: 'Your matches',
  subtitle: matches.isEmpty
      ? 'New mutual likes will appear here.'
      : '${matches.length} ${matches.length == 1 ? 'match' : 'matches'} so far',
  trailing: IconButton(
    tooltip: 'Refresh matches',
    onPressed: () => ref.invalidate(matchesProvider),
    icon: const Icon(Icons.refresh_rounded),
  ),
),
```

If `ShellHero` requires different parameter names, read
`lib/shared/widgets/shell_hero.dart` and adapt — but the visual
result must match: an eyebrow label, the bold title, a contextual
subtitle, and a trailing refresh affordance.

The subtitle pluralises the live match count so the hero reflects state
rather than a static blurb.

---

# Change 2 — Layout: hero outside scroll, list inside RefreshIndicator

Restructure the body of `MatchesScreen.build` to the canonical
browse/social shape:

```dart
return Column(
  children: [
    ShellHero(...),                       // from Change 1
    const _MatchFilterRow(),              // from Change 3 — may shrink
    Expanded(
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(matchesProvider),
        child: matches.isEmpty
            ? AppAsyncState.empty(
                message: 'No matches yet — keep liking profiles you connect with.',
                onRefresh: () async => ref.invalidate(matchesProvider),
              )
            : ListView.separated(
                padding: AppTheme.screenPadding(),
                itemCount: matches.length,
                separatorBuilder: (_, __) =>
                    SizedBox(height: AppTheme.cardGap),
                itemBuilder: (context, index) =>
                    _MatchCard(match: matches[index]),
              ),
      ),
    ),
  ],
);
```

Remove the outer `Padding(AppTheme.screenPadding)` that currently wraps
the whole `Column` — the hero must run edge-to-edge and the inner
`ListView` carries its own `screenPadding()`.

The `RefreshIndicator` must wrap an `AlwaysScrollableScrollPhysics`
list/empty state so pull-to-refresh works even when the list is empty.

---

# Change 3 — `_MatchFilterRow`: wire it or trim it

Today the filter row renders four `_FilterChip`s — All / New / Nearby /
Active now — but only "All" is hardcoded selected and tapping the others
does nothing. Cosmetic-only chips are misleading.

Pick ONE of the two paths below. Do not leave a half-wired row.

**Path A — wire the chips (preferred if controller plumbing already exists):**
- Add a private `Set<MatchFilter>` (or single `MatchFilter`) state on a
  `ConsumerStatefulWidget` wrapper, defaulting to `MatchFilter.all`.
- Filter the `matches` list before passing it to the `ListView`:
  - `new` → `_isNewMatch(match)`
  - `nearby` → matches whose `match.user.location` shares city with
    `currentUser.location` (string equality, ignore case)
  - `active` → `_isActive(match.user)`
- The chip selected state and `onTap` map to the filter setter.

**Path B — trim to "All" + "New" only:**
- Delete the Nearby and Active now chips; keep All and New, both wired.
- This avoids inventing filter logic that the backend may not support.

Pick Path B unless the codebase already has a `MatchFilter` enum or
controller method — search before implementing. Either way, after this
change, every visible chip MUST be functional.

The chip styling (compact pill, `chipRadius`, accent when selected) is
already correct — leave the visuals.

---

# Change 4 — `_MatchCard`: tokenise padding and shadow

The card body currently uses `EdgeInsets.all(16)` and a hand-rolled
`BoxShadow` literal. Replace with tokens:

- Inner padding → `EdgeInsets.all(AppTheme.cardPadding)`.
- Surface decoration → `AppTheme.surfaceDecoration(context)` (which
  already includes the soft shadow), and remove the inline `boxShadow:`
  list. If the card needs a slightly stronger lift than `softShadow`
  provides, pass `prominence: SurfaceProminence.raised` (or whatever
  enum value `surfaceDecoration` exposes — read `app_theme.dart` first).
- Card outer radius → `AppTheme.cardRadius`.

The `_NewBadge` left stripe (a vertical bar painted with `accentGradient`
when `_isNewMatch(match)` is true) stays unchanged — it sits on top of
the surface decoration via the existing `Stack`.

---

# Change 5 — `_MatchAvatar`: simplify the ring

Today `_MatchAvatar` draws a 96×96 `PersonMediaThumbnail` with a 48
`borderRadius` (forcing it circular), wrapped in a 2px white spacer
ring, wrapped in a 3px `accentGradient` ring. That is three nested
`Container`s for what should be a single avatar widget.

Replace the `_MatchAvatar` body with the existing `UserAvatar` shared
widget:

```dart
UserAvatar(
  user: match.user,
  size: 96,
  ringWidth: 3,
  ringGradient: AppTheme.accentGradient(context),
)
```

If `UserAvatar` does not expose `ringGradient`, pass the equivalent
parameter it does expose (read `lib/shared/widgets/user_avatar.dart`
before editing). Do NOT add a parameter to `UserAvatar` — adapt the
call to its existing API.

Keep the small green "active now" dot overlay (the `Positioned`
`activeColor` circle in the bottom-right). Token-align its border to
`AppTheme.activeGreen` and its background border to
`Theme.of(context).colorScheme.surface` if it currently uses literal
white — so it reads correctly in dark mode.

If `UserAvatar` cannot accept a custom overlay, keep `_MatchAvatar`
but collapse the two outer rings into ONE `Container` with a
gradient `BoxDecoration` (drop the white spacer entirely).

---

# Change 6 — `_MatchSummaryBlock`: drop the redundant chevron

The summary block currently renders:

```
[Name]  [chevron_right]   [NEW badge?]
[FadedBio]
[matched 3 days ago • Online · City]
```

The whole `_MatchCard` is wrapped in an `InkWell` that pushes the
conversation thread, so the chevron next to the name is redundant
visual noise. Remove it.

The `_NewBadge` stays where it is (right side of the name row when
applicable). Promote the name's `Text` to wrap with `Expanded` so it
truncates with ellipsis on narrow widths.

Style the name with `AppTheme.matchTextPrimary` and the bio /
metadata lines with `AppTheme.matchTextSecondary` /
`matchTextTertiary` respectively, falling back to
`colorScheme.onSurface*` if those helpers do not exist in
`app_theme.dart`.

---

# Change 7 — Action buttons: align heights and use FilledButton.icon

The card footer currently uses `_GradientActionButton` (44px tall pill
with `accentGradient` fill, "Message" label) and `_GhostActionButton`
(44px tall outline pill with `ShaderMask`-tinted icon, "Profile"
label). The shader-masked icon is striking but inconsistent with the
`FilledButton.icon` patterns used elsewhere in the app.

Refactor to:

- **Primary action ("Message")**: keep `_GradientActionButton` — the
  accent gradient fill is the brand signature for primary CTAs in the
  matches surface. Token-align its height to a constant — declare
  `static const double _matchActionHeight = 44;` at the top of
  `_MatchCard` and use it for both buttons.
- **Secondary action ("View profile")**: replace `_GhostActionButton`
  with `OutlinedButton.icon` styled to match the height and radius
  rhythm:

  ```dart
  SizedBox(
    height: _matchActionHeight,
    child: OutlinedButton.icon(
      onPressed: onViewProfile,
      icon: const Icon(Icons.person_outline_rounded, size: 18),
      label: const Text('View profile'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.matchAccent,
        side: BorderSide(
          color: AppTheme.matchAccent.withValues(alpha: 0.4),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(999)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    ),
  ),
  ```

  Then DELETE the `_GhostActionButton` widget definition — its sole
  call site is gone.

Wrap both buttons in a `Row` whose children are `Expanded` so the two
share the footer width evenly with a `SizedBox(width: AppTheme.cardGap)`
between them.

---

# Change 8 — Empty-state copy and icon

The current empty branch in this screen renders a plain centered text.
Standardise on `AppAsyncState.empty` (used in Change 2) with copy that
hints at next steps without shaming inactivity:

> "No matches yet — keep liking profiles you connect with."

The `AppAsyncState.empty` widget already supplies a token-aligned icon
and the optional refresh action; do not hand-roll an empty illustration.

---

# Acceptance checklist

- The screen layout is `Column → ShellHero → _MatchFilterRow →
  Expanded → RefreshIndicator → ListView` with no outer padding wrapper
  around the whole tree.
- `_MatchesHeader` widget definition is deleted; no remaining
  references exist.
- The hero subtitle pluralises against the live `matches.length`.
- The filter row has only working chips — every visible chip applies
  a real filter to the list, OR the row is trimmed to chips that do.
- `_MatchCard` uses `AppTheme.cardPadding`, `AppTheme.cardRadius`, and
  `AppTheme.surfaceDecoration(context)` — no inline `EdgeInsets.all(16)`
  or `BoxShadow` literals remain in the card body.
- `_MatchAvatar` is either replaced by `UserAvatar` with an accent ring
  OR collapsed to a single gradient ring (no nested ring + spacer +
  thumbnail).
- The chevron next to the match name is removed; the name `Text` is
  wrapped in `Expanded` so it truncates with ellipsis.
- Footer has `_GradientActionButton` (Message) + `OutlinedButton.icon`
  (View profile) sharing equal width via `Expanded`, both 44px tall.
  `_GhostActionButton` widget is deleted.
- Empty list state uses `AppAsyncState.empty` with the new copy.
- `_NewBadge` accent stripe, `_FadedBio` shader fade,
  `_formatRelativeMatchDate`, `_isActive`, `_isNewMatch`, and
  `_primaryPhotoUrl` are unchanged.
- `flutter analyze` is clean.
- A visual review run produces a `shell_matches__run-XXXX…png` whose
  hierarchy reads: ShellHero with refresh action → working filter row →
  list of match cards each with avatar (single gradient ring) +
  truncated name + faded bio + matched-date metadata + balanced
  Message / View profile footer.
