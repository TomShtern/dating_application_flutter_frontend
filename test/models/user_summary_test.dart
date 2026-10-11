import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/models/user_summary.dart';

void main() {
  Map<String, dynamic> userJson(Object? state) {
    return {
      'id': '11111111-1111-1111-1111-111111111111',
      'name': 'Dana',
      'age': 27,
      'state': ?state,
    };
  }

  test('parses UNDER_REVIEW', () {
    final user = UserSummary.fromJson(userJson('UNDER_REVIEW'));

    expect(user.state, 'UNDER_REVIEW');
    expect(user.isUnderReview, isTrue);
  });

  test('the other known states are not under review', () {
    for (final state in ['INCOMPLETE', 'ACTIVE', 'PAUSED', 'BANNED']) {
      expect(UserSummary.fromJson(userJson(state)).isUnderReview, isFalse);
    }
  });

  test('a state this app has never seen is kept and never crashes', () {
    final user = UserSummary.fromJson(userJson('SOMETHING_NEW'));

    expect(user.state, 'SOMETHING_NEW');
    expect(user.isUnderReview, isFalse);
  });

  test('a missing state becomes UNKNOWN', () {
    final user = UserSummary.fromJson(userJson(null));

    expect(user.state, 'UNKNOWN');
    expect(user.isUnderReview, isFalse);
  });

  test('UNDER_REVIEW survives the local round trip', () {
    final user = UserSummary.fromJson(userJson('UNDER_REVIEW'));

    expect(UserSummary.fromJson(user.toJson()).isUnderReview, isTrue);
  });
}
