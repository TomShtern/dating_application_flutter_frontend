import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/app_preferences.dart';

class AppPreferencesStore {
  AppPreferencesStore(this._preferences);

  static const String storageKey = 'app_preferences';

  final SharedPreferences _preferences;

  AppPreferences readCurrentPreferences() {
    final rawPreferences = _preferences.getString(storageKey);
    if (rawPreferences == null || rawPreferences.isEmpty) {
      return const AppPreferences();
    }

    try {
      final decoded = jsonDecode(rawPreferences);
      if (decoded is! Map) {
        return const AppPreferences();
      }

      return AppPreferences.fromJson(Map<String, dynamic>.from(decoded));
    } on FormatException {
      return const AppPreferences();
    }
  }

  Future<AppPreferences> readPreferences() async {
    return readCurrentPreferences();
  }

  Future<void> savePreferences(AppPreferences preferences) async {
    await _preferences.setString(storageKey, jsonEncode(preferences.toJson()));
  }
}
