import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/models/standout.dart';

void main() {
  test('StandoutsSnapshot.fromJson skips non-map entries', () {
    final snapshot = StandoutsSnapshot.fromJson({
      'standouts': [
        null,
        {
          'id': 'standout-1',
          'standoutUserId': 'user-1',
          'standoutUserName': 'Noa',
          'standoutUserAge': 29,
          'rank': 1,
          'score': 97,
          'reason': 'High compatibility',
        },
      ],
    });

    expect(snapshot.standouts, hasLength(1));
    expect(snapshot.standouts.single.standoutUserName, 'Noa');
  });
}
