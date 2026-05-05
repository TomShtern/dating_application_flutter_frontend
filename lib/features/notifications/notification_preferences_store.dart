import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'notification_preferences.dart';

class NotificationPreferencesStore {
  NotificationPreferencesStore(this._preferences);

  static const String storageKey = 'notification_preferences';

  final SharedPreferences _preferences;

  NotificationPreferences readCurrentPreferences() {
    final rawPreferences = _preferences.getString(storageKey);
    if (rawPreferences == null || rawPreferences.isEmpty) {
      return const NotificationPreferences();
    }

    try {
      final decoded = jsonDecode(rawPreferences);
      if (decoded is! Map) {
        return const NotificationPreferences();
      }

      return NotificationPreferences.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return const NotificationPreferences();
    }
  }

  Future<NotificationPreferences> readPreferences() async {
    return readCurrentPreferences();
  }

  Future<void> savePreferences(NotificationPreferences preferences) async {
    await _preferences.setString(storageKey, jsonEncode(preferences.toJson()));
  }
}
