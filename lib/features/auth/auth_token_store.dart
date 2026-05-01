import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/auth_session.dart';

/// SharedPreferences-backed persistence for the auth session.
///
/// Phone-alpha grade: tokens are stored in plaintext. Move to
/// flutter_secure_storage before any external release.
class AuthTokenStore {
  AuthTokenStore(this._preferences);

  static const String storageKey = 'auth_session_v1';

  final SharedPreferences _preferences;

  AuthSession? readSession() {
    final raw = _preferences.getString(storageKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return AuthSession.fromStorageJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSession(AuthSession session) {
    return _preferences.setString(
      storageKey,
      jsonEncode(session.toStorageJson()),
    );
  }

  Future<void> clearSession() => _preferences.remove(storageKey);
}
