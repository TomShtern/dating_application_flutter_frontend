import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/auth_session.dart';

/// Secure-storage-backed persistence for the auth session (Keystore /
/// Keychain). Reads migrate any legacy plaintext SharedPreferences session
/// exactly once, then delete the plaintext copy.
class AuthTokenStore {
  AuthTokenStore(this._secureStorage, this._legacyPreferences);

  static const String storageKey = 'auth_session_v1';

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _legacyPreferences;

  Future<AuthSession?> readSession() async {
    final secureRaw = await _readSecureRaw();
    if (secureRaw != null) {
      return _decode(secureRaw);
    }

    // One-time migration from the legacy plaintext store.
    final legacyRaw = _legacyPreferences.getString(storageKey);
    if (legacyRaw == null || legacyRaw.isEmpty) {
      return null;
    }

    final session = _decode(legacyRaw);
    if (session != null) {
      try {
        await _secureStorage.write(key: storageKey, value: legacyRaw);
        await _legacyPreferences.remove(storageKey);
      } catch (_) {
        // Migration is best-effort; the session itself is still valid.
      }
    }
    return session;
  }

  Future<void> saveSession(AuthSession session) async {
    await _secureStorage.write(
      key: storageKey,
      value: jsonEncode(session.toStorageJson()),
    );
  }

  Future<void> clearSession() async {
    await _legacyPreferences.remove(storageKey);
    try {
      await _secureStorage.delete(key: storageKey);
    } catch (_) {
      // A failed secure delete must not block logout.
    }
  }

  Future<String?> _readSecureRaw() async {
    try {
      return await _secureStorage.read(key: storageKey);
    } catch (_) {
      // Corrupt keystore entries (e.g. after backup/restore) must not crash
      // startup — treat as signed out.
      return null;
    }
  }

  AuthSession? _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return AuthSession.fromStorageJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }
}
