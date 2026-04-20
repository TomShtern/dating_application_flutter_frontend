import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/models/blocked_user_summary.dart';

void main() {
  test('fromJson requires a userId', () {
    expect(
      () => BlockedUserSummary.fromJson({
        'name': 'Noa',
        'statusLabel': 'Blocked profile',
      }),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('Missing userId in BlockedUserSummary.fromJson'),
        ),
      ),
    );
  });
}
