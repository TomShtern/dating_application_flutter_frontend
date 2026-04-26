import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/models/match_summary.dart';
import 'package:flutter_dating_application_1/models/pending_liker.dart';

void main() {
  test('MatchSummary parses additive person summary fields', () {
    final match = MatchSummary.fromJson({
      'matchId': 'match-1',
      'otherUserId': 'user-2',
      'otherUserName': 'Maya',
      'state': 'ACTIVE',
      'createdAt': '2026-04-25T10:15:00Z',
      'primaryPhotoUrl': '/photos/maya-1.jpg',
      'photoUrls': ['/photos/maya-1.jpg'],
      'approximateLocation': 'Tel Aviv',
      'summaryLine': 'Designer, coffee walks, weekend hikes',
    });

    expect(match.primaryPhotoUrl, '/photos/maya-1.jpg');
    expect(match.photoUrls, ['/photos/maya-1.jpg']);
    expect(match.approximateLocation, 'Tel Aviv');
    expect(match.summaryLine, 'Designer, coffee walks, weekend hikes');
  });

  test('PendingLiker parses additive person summary fields', () {
    final liker = PendingLiker.fromJson({
      'userId': 'user-3',
      'name': 'Noa',
      'age': 29,
      'likedAt': '2026-04-25T10:15:00Z',
      'primaryPhotoUrl': '/photos/noa-1.jpg',
      'photoUrls': ['/photos/noa-1.jpg'],
      'approximateLocation': 'Ramat Gan',
      'summaryLine': 'Runner, coffee person, weekend hiker',
    });

    expect(liker.primaryPhotoUrl, '/photos/noa-1.jpg');
    expect(liker.photoUrls, ['/photos/noa-1.jpg']);
    expect(liker.approximateLocation, 'Ramat Gan');
    expect(liker.summaryLine, 'Runner, coffee person, weekend hiker');
  });
}
