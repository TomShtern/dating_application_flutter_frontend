Target file: lib/features/notifications/notifications_screen.dart

Design reference: docs/design-language.md (utility/settings screen archetype, §7.1 section label pattern, semantic colour tokens)

You are a Flutter frontend engineer. Your task is to visually refine the
NotificationsScreen at
`lib/features/notifications/notifications_screen.dart`. Do not change
providers, controllers, models, API calls, navigation logic, the
mark-read or refresh handlers, or the date-grouping logic. Keep
`_NotificationsScreenState`, `_buildNotificationSections`,
`_notificationGroupLabel`, `_formatFriendlyNotificationTimestamp`, and
`_routePersonName` exactly as written.

Constraints (read first):
- Utility archetype: `AppBar` should hold the back affordance only, no
  title — the `_NotificationsIntroCard` is the visual anchor for the
  screen.
- Use `AppTheme` tokens (`cardRadius`, `panelRadius`, `chipRadius`,
  `cardGap`, `pagePadding`, `cardPadding`, `sectionGap`,
  `surfaceDecoration`, `screenPadding`, `sectionPadding`,
  `sectionSpacing`, `listSpacing`).
- The §7.1 `_NotificationSectionHeader` is already correct — do NOT
  edit its internals (`width: 3`, `SizedBox(width: 10)`,
  `SizedBox(width: 12)`, alpha `0.85` and `0.45`).
- Per-type categorical colours in `_NotificationSpec.forType` are
  intentional and stay as hard-coded literals.

---

# Change 1 — AppBar: drop the duplicate "Notifications" title

The `_NotificationsIntroCard` (a `SectionIntroCard`) already shows
"Notifications" as its title. Remove the `Text('Notifications', …)` from
the AppBar so the heading is not duplicated.

```dart
appBar: AppBar(
  title: const SizedBox.shrink(),
  backgroundColor: Colors.transparent,
  elevation: 0,
  scrolledUnderElevation: 0,
),
```

The intro card stays as the anchor. The back arrow remains because this
is a pushed screen.

---

# Change 2 — Intro card description: more useful counts copy

Currently:
- `unreadCount == 0` → `'All caught up'`
- otherwise → `'$unreadCount unread • $totalCount total'`

Replace with phrasing that pluralises and clarifies the filter context:

```dart
final description = switch (unreadCount) {
  0 when totalCount == 0 => 'No notifications yet',
  0 => 'All caught up — $totalCount in total',
  1 => '1 unread of $totalCount',
  _ => '$unreadCount unread of $totalCount',
};
```

If the project lints against `switch` expressions on `int`, replace
with an equivalent if/else chain — same semantics.

The intro card icon, badges, and trailing refresh button stay
unchanged.

---

# Change 3 — `_NotificationTile`: mutually-exclusive trailing affordance

Today the tile renders BOTH a chevron-right (when `route != null`) AND
a "mark read" check IconButton (when `unread`). When a notification is
both unread AND routable, the right edge is crowded with two icons of
similar size, neither obviously primary.

Make the trailing slot exactly one widget, in this priority order:

1. **If unread** → "mark read" check button (existing styling kept).
   The whole tile is still tappable to open the route via the InkWell —
   so the chevron is visually unnecessary on unread items.
2. **Else if `route != null`** → chevron-right at the existing 20px
   icon size, `colorScheme.onSurfaceVariant`.
3. **Else** → no trailing widget at all (keep the rightmost padding).

Implementation: replace the two trailing blocks
(`if (route != null) … if (unread) …`) with a single helper that
returns one Widget:

```dart
Widget? _trailing() {
  if (unread) {
    return _MarkReadButton(spec: spec, isBusy: isBusy, onPressed: onMarkRead);
  }
  if (route != null) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
  return null;
}
```

Then in the Row:

```dart
final trailing = _trailing();
…
if (trailing != null) ...[
  const SizedBox(width: 8),
  trailing,
],
```

Lift the existing `IconButton` body into a small private `_MarkReadButton`
StatelessWidget (keep all the `WidgetStateProperty` logic and the spinner
fallback — verbatim from the current code). Do not change tap targets or
tooltip messages.

---

# Change 4 — `_NotificationIconChip`: round the chip with a token-aligned radius

The current chip uses `BorderRadius.all(Radius.circular(16.8))` and a
40×40 box, giving a roughly squircle look that doesn't quite match the
14-radius rhythm used on row-level chips elsewhere.

Change the icon container to:

```dart
DecoratedBox(
  decoration: BoxDecoration(
    color: spec.color.withValues(alpha: 0.16),
    borderRadius: const BorderRadius.all(Radius.circular(14)),
  ),
  child: const SizedBox.square(dimension: 40),
),
```

Keep the centred icon (size 22.4) and the unread dot Positioned overlay
unchanged. The dot's surface-coloured 1.5px border stays so the dot
reads against either the unread tinted surface or the resting surface.

---

# Change 5 — Type chip alignment with timestamp

The metadata row currently is:

```
[type chip]  [SizedBox 6]  [Expanded(timestamp ellipsis)]
```

This causes the type chip to baseline-collide with the timestamp on
narrow widths because the chip has its own `EdgeInsets.fromLTRB(7, 3, 7, 3)`
padding while the timestamp uses default `bodySmall` line height.

Wrap the row in `Row(crossAxisAlignment: CrossAxisAlignment.center, …)`
explicitly, and bump the chip horizontal padding to 8 to match the
chip's vertical optical centring:

```dart
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  child: Text(
    formatDisplayLabel(item.type),
    style: theme.textTheme.labelSmall?.copyWith(
      color: spec.color,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    ),
  ),
),
```

Add `letterSpacing: 0.2` to the type label so short labels like
"Match Found" sit more legibly inside the pill at the smaller size.

---

# Change 6 — Unread tile surface tint: use AppTheme helper if present

Currently:

```dart
final surfaceColor = unread
    ? Color.alphaBlend(
        spec.color.withValues(alpha: 0.04),
        colorScheme.surfaceContainerLow,
      )
    : colorScheme.surfaceContainerLow;
```

If `AppTheme` exposes a `tintedSurface(context, accent: …, alpha: …)`
helper or similar, use it. If it does NOT (verify by reading
`lib/theme/app_theme.dart`), keep the literal as-is — do NOT invent a
helper name.

Increase the unread tint alpha from `0.04` to `0.06` so the row is
slightly more distinguishable from read rows in light mode without
becoming aggressive in dark mode.

---

# Change 7 — Empty state copy

Current empty messages:
- unread filter on → `'No unread notifications right now.'`
- no filter → `'No notifications yet.'`

Replace with copy that hints at the filter without scolding the user:

```dart
AppAsyncState.empty(
  message: unreadOnly
      ? 'You\'re all caught up — nothing unread.'
      : 'You\'ll see matches, replies, and friend activity here.',
  onRefresh: controller.refresh,
),
```

---

# Change 8 — Section spacing tokens

Inside `_buildNotificationSections`, the inter-section spacer uses
`AppTheme.sectionSpacing(compact: true)` and the label-to-first-item
spacer uses `AppTheme.listSpacing(compact: true)` — already correct.
Verify both are present after edits, and verify the gap between the
intro card and the first section header still uses
`AppTheme.sectionSpacing(compact: true)` (unchanged from the existing
code).

---

# Acceptance checklist

- AppBar shows back arrow only — no "Notifications" title.
- Intro card description pluralises and reads naturally for 0/1/many
  unread states.
- Each tile shows EXACTLY ONE trailing affordance: check (unread) OR
  chevron (read+routable) OR nothing (read+no route). The
  `_MarkReadButton` extraction compiles and preserves the original
  busy-state spinner and disabled-state colour resolution.
- Icon chip uses `Radius.circular(14)` and the unread dot still has a
  1.5 px surface-coloured border.
- Unread surface tint alpha is `0.06` (not `0.04`).
- Type chip padding is `EdgeInsets.symmetric(horizontal: 8, vertical: 3)`
  with `letterSpacing: 0.2` on the label.
- Empty-state copy is updated for both filter states.
- `_NotificationSectionHeader` internals are byte-for-byte unchanged.
- `_NotificationSpec.forType` and its hard-coded categorical colours
  are unchanged.
- `flutter analyze` is clean.
- A visual review run produces a `notifications__run-XXXX…png` whose
  hierarchy reads: intro card with badges → Today section → tiles with
  single trailing affordance → Yesterday → Earlier.
