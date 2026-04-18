import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user_summary.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden before use.',
  );
});

class SelectedUserStore {
  SelectedUserStore(this._preferences);

  static const String storageKey = 'selected_dev_user';

  final SharedPreferences _preferences;

  Future<UserSummary?> readSelectedUser() async {
    final rawUser = _preferences.getString(storageKey);
    if (rawUser == null || rawUser.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(rawUser);
    if (decoded is! Map) {
      return null;
    }

    return UserSummary.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<void> saveSelectedUser(UserSummary user) async {
    await _preferences.setString(storageKey, jsonEncode(user.toJson()));
  }

  Future<void> clearSelectedUser() async {
    await _preferences.remove(storageKey);
  }
}
