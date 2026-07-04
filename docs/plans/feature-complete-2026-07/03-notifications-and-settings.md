# Plan 03 — Notifications & Settings

**Status:** ✅ COMPLETE — implemented and `flutter analyze` clean on 2026-07-05

Read `00-overview.md` first. Rules there apply.

## Why

- The Settings → Notifications row gives no hint that unread notifications exist, even though `notificationsUnreadCountProvider` already exists in `lib/features/notifications/notifications_provider.dart` (verify exact name there before use).
- Notification preferences (`lib/features/notifications/notification_preferences.dart` — categories: `messages`, `matchesActivity`, `safetyAccount`, `marketingProduct`, persisted device-locally by `NotificationPreferencesController`) are toggles that currently affect **nothing**. Backend has no preference endpoints (out of scope), but the client can honor them as a display filter.
- Switching seeded dev users requires logging out; a debug shortcut belongs in Settings.

## Files you will touch

- `lib/features/settings/settings_screen.dart`
- `lib/features/notifications/notifications_screen.dart`
- `lib/features/notifications/notification_preferences.dart` (one added function)

---

## Task 1 — Unread pill on the Settings → Notifications row

Anchors in `lib/features/settings/settings_screen.dart`: `SettingsScreen` is a `ConsumerWidget`; the "Quick access" section (~line 62) contains `_SettingsLinkTile` entries; the Notifications tile is at ~line 97; `_SettingsLinkTile` is defined at ~line 444.

1. Add to `_SettingsLinkTile` an optional `final String? badgeLabel;` (constructor `this.badgeLabel`). In its layout, render — between the title/subtitle block and the trailing chevron (inspect its Row and place accordingly) — when `badgeLabel != null`:
   ```dart
   DecoratedBox(
     decoration: BoxDecoration(
       color: AppTheme.matchAccent(context),
       borderRadius: BorderRadius.circular(999),
     ),
     child: Padding(
       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
       child: Text(
         badgeLabel!,
         style: Theme.of(context).textTheme.labelSmall?.copyWith(
           color: Colors.white,
           fontWeight: FontWeight.w700,
         ),
       ),
     ),
   ),
   ```
   plus an 8px `SizedBox` gap on its left. Import `app_theme.dart` if the file somehow lacks it (it won't).
2. In `SettingsScreen.build`, watch the unread count provider from `notifications_provider.dart` (open that file, use the exact provider — it returns an unread count, likely `AsyncValue<int>`):
   ```dart
   final unreadNotifications =
       ref.watch(notificationsUnreadCountProvider).value ?? 0;
   ```
   Pass to the Notifications tile: `badgeLabel: unreadNotifications > 0 ? (unreadNotifications > 99 ? '99+' : '$unreadNotifications') : null`.
3. Add the needed import of `../notifications/notifications_provider.dart`.

Decision (final): loading/error states show no badge (`.value ?? 0`). Do not add spinners to the tile.

## Task 2 — Category mapping for notification types

In `lib/features/notifications/notification_preferences.dart`, add at file scope (bottom):

```dart
/// Maps a backend notification type to the device-local preference category
/// that mutes it. Unknown types return null and are ALWAYS shown — never
/// hide content we can't classify.
NotificationPreferenceCategory? categoryForNotificationType(String type) {
  return switch (type.trim().toUpperCase()) {
    'NEW_MESSAGE' => NotificationPreferenceCategory.messages,
    'MATCH_FOUND' ||
    'FRIEND_REQUEST' ||
    'FRIEND_REQUEST_ACCEPTED' => NotificationPreferenceCategory.matchesActivity,
    'GRACEFUL_EXIT' => NotificationPreferenceCategory.safetyAccount,
    _ => null,
  };
}
```

These five types are exactly the keys of `notificationTypeRegistry` in `lib/models/notification_item.dart:106-135`. Do not import the model into the preferences file — the function takes a plain `String`.

## Task 3 — Honor muted categories in the notifications list

In `lib/features/notifications/notifications_screen.dart` (read the list-building region first — find where the fetched `List<NotificationItem>` is turned into list children):

1. Watch `notificationPreferencesProvider` (from `notification_preferences_provider.dart`) in the widget that builds the list.
2. Partition the items:
   ```dart
   final prefs = ref.watch(notificationPreferencesProvider);
   final visible = <NotificationItem>[];
   var hiddenCount = 0;
   for (final item in items) {
     final category = categoryForNotificationType(item.type);
     if (category != null && !prefs.isEnabled(category) && !_showMuted) {
       hiddenCount++;
     } else {
       visible.add(item);
     }
   }
   ```
   `_showMuted` is a new local `bool` state (add to the screen's `State`; default `false`). If the list-building widget is currently stateless/ConsumerWidget, convert the smallest enclosing widget necessary to `ConsumerStatefulWidget` — do not restructure the whole screen.
3. Render `visible` instead of `items`. When `hiddenCount > 0 && !_showMuted`, append after the last list item a low-emphasis row:
   ```dart
   TextButton.icon(
     onPressed: () => setState(() => _showMuted = true),
     icon: const Icon(Icons.visibility_outlined, size: 16),
     label: Text('$hiddenCount hidden by your preferences — show'),
   )
   ```
   styled/centered consistently with the screen (wrap in `Center` if the list children are full-width cards). When `_showMuted` is true, show everything and append instead a `TextButton` labeled `'Hide muted again'` that sets `_showMuted = false`.
4. **Do not** filter the unread *count* provider or the mark-all-read action — muting is a display concern only; counts and read-state remain backend truth. If the screen shows a header count sourced from the full list, leave it on the full list.
5. Empty-state nuance: if filtering makes `visible` empty while `items` was not, do NOT show the regular "no notifications" empty state; show the hidden-count row alone (plus the screen's normal chrome).

## Task 4 — Debug-only seeded-user switch in Settings

Anchor: `_SettingsSessionCard` (~line 333 of `settings_screen.dart`) — the "Current dev session" card that already holds the "Switch" (logout) button and is wrapped in `DeveloperOnlyCalloutCard`.

Add next to (or under, if the row is tight) the existing button, gated by `kDebugMode` (`import 'package:flutter/foundation.dart';`):

```dart
if (kDebugMode)
  TextButton.icon(
    onPressed: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const DevUserPickerScreen(),
      ),
    ),
    icon: const Icon(Icons.developer_mode_rounded),
    label: const Text('Pick seeded user'),
  ),
```

Import `../auth/dev_user_picker_screen.dart`. Do not change the existing logout behavior.

## Acceptance criteria

- `flutter analyze` → no issues.
- Settings Notifications row shows a count pill only when unread > 0; caps at "99+".
- Toggling a category off in notification preferences hides exactly the mapped types from the list, shows an accurate hidden-count row, and "show" reveals them; unknown types are never hidden.
- Mark-read / mark-all-read flows unchanged.
- Seeded-user picker reachable from Settings in debug builds only.
