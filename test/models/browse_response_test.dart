import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/models/browse_response.dart';

void main() {
  test('parses the documented browse response shape', () {
    final response = BrowseResponse.fromJson({
      'candidates': [
        {
          'id': '22222222-2222-2222-2222-222222222222',
          'name': 'Noa',
          'age': 29,
          'state': 'ACTIVE',
        },
      ],
      'dailyPick': {
        'userId': '33333333-3333-3333-3333-333333333333',
        'userName': 'Maya',
        'userAge': 30,
        'date': '2026-04-18',
        'reason': 'High compatibility',
        'alreadySeen': false,
      },
      'dailyPickViewed': false,
      'locationMissing': true,
    });

    expect(response.candidates, hasLength(1));
    expect(response.candidates.single.name, 'Noa');
    expect(response.dailyPick?.userName, 'Maya');
    expect(response.dailyPickViewed, isFalse);
    expect(response.locationMissing, isTrue);
  });
}
