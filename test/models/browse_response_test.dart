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
          'primaryPhotoUrl': '/photos/noa-1.jpg',
          'photoUrls': ['/photos/noa-1.jpg', '/photos/noa-2.jpg'],
          'approximateLocation': 'Tel Aviv',
          'summaryLine': 'Designer, coffee walks, weekend hikes',
        },
      ],
      'dailyPick': {
        'userId': '33333333-3333-3333-3333-333333333333',
        'userName': 'Maya',
        'userAge': 30,
        'date': '2026-04-18',
        'reason': 'High compatibility',
        'alreadySeen': false,
        'primaryPhotoUrl': '/photos/maya-1.jpg',
        'photoUrls': ['/photos/maya-1.jpg'],
        'approximateLocation': 'Ramat Gan',
        'summaryLine': 'Product designer, sunrise runs',
      },
      'dailyPickViewed': false,
      'locationMissing': true,
    });

    expect(response.candidates, hasLength(1));
    expect(response.candidates.single.name, 'Noa');
    expect(response.candidates.single.primaryPhotoUrl, '/photos/noa-1.jpg');
    expect(response.candidates.single.photoUrls, [
      '/photos/noa-1.jpg',
      '/photos/noa-2.jpg',
    ]);
    expect(response.candidates.single.approximateLocation, 'Tel Aviv');
    expect(
      response.candidates.single.summaryLine,
      'Designer, coffee walks, weekend hikes',
    );
    expect(response.dailyPick?.userName, 'Maya');
    expect(response.dailyPick?.primaryPhotoUrl, '/photos/maya-1.jpg');
    expect(response.dailyPick?.photoUrls, ['/photos/maya-1.jpg']);
    expect(response.dailyPick?.approximateLocation, 'Ramat Gan');
    expect(response.dailyPick?.summaryLine, 'Product designer, sunrise runs');
    expect(response.dailyPickViewed, isFalse);
    expect(response.locationMissing, isTrue);
  });
}
