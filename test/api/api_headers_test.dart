import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/api/api_endpoints.dart';
import 'package:flutter_dating_application_1/api/api_headers.dart';

void main() {
  test('does not attach the shared secret to health requests', () {
    final headers = ApiHeaders.build(
      path: ApiEndpoints.health,
      sharedSecret: 'lan-dev-secret',
    );

    expect(headers.containsKey(ApiHeaders.sharedSecretHeader), isFalse);
  });

  test('attaches the shared secret to every other route', () {
    for (final path in [
      ApiEndpoints.authSession,
      ApiEndpoints.users,
      ApiEndpoints.userDetail('11111111-1111-1111-1111-111111111111'),
      ApiEndpoints.messages(
        '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
      ),
    ]) {
      final headers = ApiHeaders.build(
        path: path,
        sharedSecret: 'lan-dev-secret',
      );
      expect(
        headers[ApiHeaders.sharedSecretHeader],
        'lan-dev-secret',
        reason: 'shared secret missing for $path',
      );
    }
  });

  test(
    'never sends a user id header (backend derives the caller from the token)',
    () {
      final headers = ApiHeaders.build(
        path: ApiEndpoints.userDetail('u-1'),
        sharedSecret: 'lan-dev-secret',
      );

      expect(
        headers.keys.map((key) => key.toLowerCase()),
        isNot(contains('x-user-id')),
      );
    },
  );

  test(
    'static headers never include Authorization (the interceptor adds it)',
    () {
      final headers = ApiHeaders.build(
        path: ApiEndpoints.authSession,
        sharedSecret: 'lan-dev-secret',
      );

      expect(headers.containsKey(ApiHeaders.authorizationHeader), isFalse);
    },
  );

  test('needsBearer is false only for the public health probe', () {
    expect(ApiHeaders.needsBearer(ApiEndpoints.health), isFalse);
    expect(ApiHeaders.needsBearer(ApiEndpoints.authSession), isTrue);
    expect(ApiHeaders.needsBearer(ApiEndpoints.userDetail('u-1')), isTrue);
  });
}
