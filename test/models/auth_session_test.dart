import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/models/auth_session.dart';

void main() {
  group('AuthSession.fromAuthResponse', () {
    test('parses the documented login/signup response shape', () {
      final received = DateTime.utc(2026, 5, 1, 12);
      final session = AuthSession.fromAuthResponse({
        'accessToken': 'access-1',
        'refreshToken': 'refresh-1',
        'expiresInSeconds': 900,
        'user': {
          'id': '11111111-1111-1111-1111-111111111111',
          'email': 'jane@example.com',
          'displayName': null,
          'profileCompletionState': 'needs_name',
        },
      }, receivedAt: received);

      expect(session.accessToken, 'access-1');
      expect(session.refreshToken, 'refresh-1');
      expect(session.expiresAt, received.add(const Duration(seconds: 900)));
      expect(session.user.id, '11111111-1111-1111-1111-111111111111');
      expect(session.user.email, 'jane@example.com');
      expect(session.user.displayName, isNull);
      expect(session.user.profileCompletionState, 'needs_name');
      expect(session.user.isProfileComplete, isFalse);
    });

    test('throws when the user payload is missing', () {
      expect(
        () => AuthSession.fromAuthResponse({
          'accessToken': 'access',
          'refreshToken': 'refresh',
          'expiresInSeconds': 900,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws when token fields are missing or blank', () {
      final base = {
        'accessToken': 'access',
        'refreshToken': 'refresh',
        'expiresInSeconds': 900,
        'user': {
          'id': '11111111-1111-1111-1111-111111111111',
          'email': 'jane@example.com',
          'displayName': null,
          'profileCompletionState': 'complete',
        },
      };

      expect(
        () => AuthSession.fromAuthResponse({...base, 'accessToken': ''}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => AuthSession.fromAuthResponse({...base, 'refreshToken': null}),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws when expiresInSeconds is missing or invalid', () {
      final base = {
        'accessToken': 'access',
        'refreshToken': 'refresh',
        'expiresInSeconds': 900,
        'user': {
          'id': '11111111-1111-1111-1111-111111111111',
          'email': 'jane@example.com',
          'displayName': null,
          'profileCompletionState': 'complete',
        },
      };

      expect(
        () => AuthSession.fromAuthResponse({...base, 'expiresInSeconds': null}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => AuthSession.fromAuthResponse({...base, 'expiresInSeconds': 0}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => AuthSession.fromAuthResponse({...base, 'expiresInSeconds': 1.5}),
        throwsA(isA<FormatException>()),
      );
    });

    test('round-trips through storage JSON', () {
      final received = DateTime.utc(2026, 5, 1, 12);
      final original = AuthSession.fromAuthResponse({
        'accessToken': 'a',
        'refreshToken': 'r',
        'expiresInSeconds': 60,
        'user': {
          'id': 'u-1',
          'email': 'e@x',
          'displayName': 'E',
          'profileCompletionState': 'complete',
        },
      }, receivedAt: received);

      final restored = AuthSession.fromStorageJson(original.toStorageJson());

      expect(restored.accessToken, original.accessToken);
      expect(restored.refreshToken, original.refreshToken);
      expect(restored.expiresAt, original.expiresAt);
      expect(restored.user, original.user);
      expect(restored.user.isProfileComplete, isTrue);
    });

    test('isExpired honors a clock skew window', () {
      final fixedNow = DateTime.utc(2026, 5, 1, 12, 0, 30);
      final expiresAt = fixedNow.add(const Duration(seconds: 5));
      final session = AuthSession.fromStorageJson({
        'accessToken': 'a',
        'refreshToken': 'r',
        'expiresAt': expiresAt.toIso8601String(),
        'user': {
          'id': 'u',
          'email': 'e',
          'displayName': null,
          'profileCompletionState': 'complete',
        },
      });

      // Default skew is 30s — token expires in 5s from fixedNow, so it's
      // already considered expired.
      expect(session.isExpired(now: fixedNow), isTrue);
      // With zero skew the token is still valid (expiry hasn't hit).
      expect(session.isExpired(skew: Duration.zero, now: fixedNow), isFalse);
    });
  });
}
