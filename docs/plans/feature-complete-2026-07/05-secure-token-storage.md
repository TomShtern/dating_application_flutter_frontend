# Plan 05 — Secure Token Storage (flutter_secure_storage)

**Status:** ✅ COMPLETE — implemented and `flutter analyze` clean on 2026-07-05

Read `00-overview.md` first. **Do this plan LAST.** It touches the auth path; a mistake here locks users out. Every task has a gate — if a gate fails, revert the whole plan (git checkout the touched files) and report.

## Why

`lib/features/auth/auth_token_store.dart` stores the JWT access/refresh tokens as **plaintext JSON in SharedPreferences** (its own doc comment says to fix this before any external release). We move it to `flutter_secure_storage` (Keystore on Android, Keychain on iOS) with a one-time silent migration of any existing plaintext session.

## Verified facts (do not re-derive)

- `AuthTokenStore` (`lib/features/auth/auth_token_store.dart`) has exactly three members used elsewhere: `readSession()` (currently **sync**, returns `AuthSession?`), `saveSession(AuthSession)` → `Future<void>`, `clearSession()` → `Future<void>`. Storage key: `'auth_session_v1'`.
- It is constructed in exactly one place: `authTokenStoreProvider` in `lib/features/auth/auth_controller.dart:46-48`.
- `readSession()` has exactly two call sites, **both inside async methods**, so making it async is mechanical:
  - `auth_controller.dart:69` (`restoreSession`)
  - `auth_controller.dart:152` (`_performRefresh`, inside a `switch` expression)
- Serialization helpers `AuthSession.fromStorageJson` / `toStorageJson` stay untouched.

## Task 1 — Add the dependency

```powershell
flutter pub add flutter_secure_storage
```

**Gate:** command succeeds and `flutter analyze` still passes. If pub add fails (network/version resolution), STOP the whole plan and report — do not hand-edit pubspec versions, do not vendor code.

Note: Android `minSdkVersion` must be ≥ 18 — Flutter's default (21+) already satisfies this; do not edit Gradle files. Do not add any platform-specific setup unless the build actually fails (it should not for Android, the primary target).

## Task 2 — Rewrite `AuthTokenStore`

Replace the body of `lib/features/auth/auth_token_store.dart` with:

```dart
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
```

These decisions are final: constructor takes both storages; reads fall back to + migrate the legacy key; all secure-storage exceptions degrade to "signed out" rather than crashing; `clearSession` clears both.

## Task 3 — Update the provider and the two call sites

In `lib/features/auth/auth_controller.dart`:

1. Provider (line ~46):
   ```dart
   final authTokenStoreProvider = Provider<AuthTokenStore>((ref) {
     return AuthTokenStore(
       const FlutterSecureStorage(),
       ref.watch(sharedPreferencesProvider),
     );
   });
   ```
   Add `import 'package:flutter_secure_storage/flutter_secure_storage.dart';`.
2. `restoreSession` (line ~69): `final session = _store.readSession();` → `final session = await _store.readSession();`
3. `_performRefresh` (line ~152): the switch arm `_ => _store.readSession()?.refreshToken,` → `_ => (await _store.readSession())?.refreshToken,`
   `_performRefresh` is already `async`; `await` inside a switch-expression arm is legal Dart 3. If the analyzer rejects it in this position, hoist instead:
   ```dart
   final storedSession = current is Authenticated ? null : await _store.readSession();
   final refreshToken = switch (current) {
     Authenticated(:final session) => session.refreshToken,
     _ => storedSession?.refreshToken,
   };
   ```

**Gate:** `flutter analyze` → no issues. Also run `rg -n "readSession" lib test` — if any test file calls `readSession()` synchronously, adjust those call sites minimally (`await` + async test body); if a test constructs `AuthTokenStore(prefs)` with one argument, update the construction to `AuthTokenStore(const FlutterSecureStorage(), prefs)` — but if that drags test infra into needing platform channels, mark the plan REVERTED and report instead (secure storage needs platform channels that plain dart tests don't have; this is exactly the kind of breakage we don't want to paper over).

## Task 4 — Update docs

- `AGENTS.md` dependency table: add `flutter_secure_storage` with its locked version (read it from `pubspec.lock` after Task 1) and role "secure auth token storage".
- In `AGENTS.md` and `CLAUDE.md`, if either still describes tokens as plaintext SharedPreferences, update that sentence to reflect secure storage + legacy migration.

## Acceptance criteria

- `flutter analyze` → no issues.
- No remaining `getString(storageKey)`-style plaintext **writes** of the session anywhere (`rg -n "auth_session_v1" lib` shows only `auth_token_store.dart`).
- Logout clears both stores; startup with neither store populated lands on the login screen (code-verified: `readSession()` returns null → `Unauthenticated`).
- Existing users' sessions survive the upgrade via the legacy-read migration path (code-verified by reading `readSession`).
