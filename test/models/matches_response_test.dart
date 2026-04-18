import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/models/matches_response.dart';

void main() {
  test('parses the documented matches response shape', () {
    final response = MatchesResponse.fromJson({
      'matches': [
        {
          'matchId':
              '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
          'otherUserId': '22222222-2222-2222-2222-222222222222',
          'otherUserName': 'Noa',
          'state': 'ACTIVE',
          'createdAt': '2026-04-18T12:34:56Z',
        },
      ],
      'totalCount': 1,
      'offset': 0,
      'limit': 20,
      'hasMore': false,
    });

    expect(response.matches, hasLength(1));
    expect(response.matches.single.otherUserName, 'Noa');
    expect(response.totalCount, 1);
    expect(response.hasMore, isFalse);
  });
}
