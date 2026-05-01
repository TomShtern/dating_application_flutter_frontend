import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/api/api_endpoints.dart';
import 'package:flutter_dating_application_1/api/api_headers.dart';

void main() {
  test('does not attach auth headers to health requests', () {
    final headers = ApiHeaders.build(
      path: ApiEndpoints.health,
      sharedSecret: 'lan-dev-secret',
      userId: '11111111-1111-1111-1111-111111111111',
    );

    expect(headers.containsKey(ApiHeaders.sharedSecretHeader), isFalse);
    expect(headers.containsKey(ApiHeaders.userIdHeader), isFalse);
  });

  test('attaches both auth headers to user scoped requests', () {
    final headers = ApiHeaders.build(
      path: ApiEndpoints.userDetail('11111111-1111-1111-1111-111111111111'),
      sharedSecret: 'lan-dev-secret',
      userId: '11111111-1111-1111-1111-111111111111',
    );

    expect(headers[ApiHeaders.sharedSecretHeader], 'lan-dev-secret');
    expect(
      headers[ApiHeaders.userIdHeader],
      '11111111-1111-1111-1111-111111111111',
    );
  });

  test('keeps shared secret on list requests without forcing a user id', () {
    final headers = ApiHeaders.build(
      path: ApiEndpoints.users,
      sharedSecret: 'lan-dev-secret',
    );

    expect(headers[ApiHeaders.sharedSecretHeader], 'lan-dev-secret');
    expect(headers.containsKey(ApiHeaders.userIdHeader), isFalse);
  });

  test('attaches Bearer token on protected routes when supplied', () {
    final headers = ApiHeaders.build(
      path: ApiEndpoints.userDetail('u-1'),
      sharedSecret: 'lan-dev-secret',
      userId: 'u-1',
      accessToken: 'token-1',
    );
    expect(headers[ApiHeaders.authorizationHeader], 'Bearer token-1');
  });

  test('omits Bearer token on the unauthenticated auth endpoints', () {
    for (final path in [
      ApiEndpoints.authSignup,
      ApiEndpoints.authLogin,
      ApiEndpoints.authRefresh,
      ApiEndpoints.authLogout,
    ]) {
      final headers = ApiHeaders.build(
        path: path,
        sharedSecret: 'lan-dev-secret',
        accessToken: 'token-1',
      );
      expect(
        headers.containsKey(ApiHeaders.authorizationHeader),
        isFalse,
        reason: 'Bearer should not be sent to $path',
      );
    }
  });

  test('attaches Bearer on /api/auth/me (which requires auth)', () {
    final headers = ApiHeaders.build(
      path: ApiEndpoints.authMe,
      sharedSecret: 'lan-dev-secret',
      accessToken: 'token-1',
    );
    expect(headers[ApiHeaders.authorizationHeader], 'Bearer token-1');
  });

  test('attaches both auth headers to conversation message routes', () {
    final headers = ApiHeaders.build(
      path: ApiEndpoints.messages(
        '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
      ),
      sharedSecret: 'lan-dev-secret',
      userId: '11111111-1111-1111-1111-111111111111',
    );

    expect(headers[ApiHeaders.sharedSecretHeader], 'lan-dev-secret');
    expect(
      headers[ApiHeaders.userIdHeader],
      '11111111-1111-1111-1111-111111111111',
    );
  });
}
