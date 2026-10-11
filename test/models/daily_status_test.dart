import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/models/daily_status.dart';
import 'package:flutter_dating_application_1/models/pending_liker.dart';

void main() {
  test('parses the documented daily status, including an unlimited kind', () {
    final status = DailyStatus.fromJson({
      'date': '2026-10-11',
      'resetsAt': '2026-10-11T21:00:00Z',
      'likes': {'used': 1, 'remaining': 2, 'unlimited': false},
      'superLikes': {'used': 0, 'remaining': 2, 'unlimited': false},
      'passes': {'used': 0, 'remaining': null, 'unlimited': true},
    });

    expect(status.likes.used, 1);
    expect(status.likes.remaining, 2);
    expect(status.likes.unlimited, isFalse);
    expect(status.superLikes.remaining, 2);
    expect(status.passes.unlimited, isTrue);
    expect(status.passes.remaining, isNull);
    expect(status.resetsAt, DateTime.parse('2026-10-11T21:00:00Z'));
  });

  test('a missing kind has no known remaining count', () {
    final status = DailyStatus.fromJson(const {});

    expect(status.likes.remaining, isNull);
    expect(status.likes.unlimited, isFalse);
    expect(status.resetsAt, isNull);
  });

  test('pending liker reads the superLike flag and defaults it to false', () {
    Map<String, dynamic> json({bool? superLike}) => {
      'userId': '22222222-2222-2222-2222-222222222222',
      'name': 'Noa',
      'age': 28,
      'superLike': ?superLike,
    };

    expect(PendingLiker.fromJson(json(superLike: true)).superLike, isTrue);
    expect(PendingLiker.fromJson(json()).superLike, isFalse);
  });
}
