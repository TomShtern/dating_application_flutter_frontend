import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/models/like_result.dart';

void main() {
  test('parses match details from the backend response', () {
    final result = LikeResult.fromJson({
      'isMatch': true,
      'message': 'It\'s a match!',
      'match': {
        'matchId':
            '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
        'otherUserId': '22222222-2222-2222-2222-222222222222',
        'otherUserName': 'Noa',
      },
    });

    expect(result.isMatch, isTrue);
    expect(result.message, 'It\'s a match!');
    expect(
      result.matchId,
      '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
    );
    expect(result.matchedUserId, '22222222-2222-2222-2222-222222222222');
    expect(result.matchedUserName, 'Noa');
  });
}
