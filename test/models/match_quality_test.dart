import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/models/match_quality.dart';

void main() {
  test('parses the live Stage A match-quality payload', () {
    const matchId =
        '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222';

    final matchQuality = MatchQuality.fromJson({
      'matchId': matchId,
      'perspectiveUserId': '11111111-1111-1111-1111-111111111111',
      'otherUserId': '22222222-2222-2222-2222-222222222222',
      'compatibilityScore': 85,
      'compatibilityLabel': 'Great Match',
      'starDisplay': '⭐⭐⭐⭐',
      'paceSyncLevel': 'Good Sync',
      'distanceKm': 12.4,
      'ageDifference': 2,
      'highlights': [
        'Lives nearby (12.4 km away)',
        'You both enjoy Hiking',
        'Great communication sync',
      ],
    });

    expect(matchQuality.matchId, matchId);
    expect(
      matchQuality.perspectiveUserId,
      '11111111-1111-1111-1111-111111111111',
    );
    expect(matchQuality.otherUserId, '22222222-2222-2222-2222-222222222222');
    expect(matchQuality.compatibilityScore, 85);
    expect(matchQuality.compatibilityLabel, 'Great Match');
    expect(matchQuality.starDisplay, '⭐⭐⭐⭐');
    expect(matchQuality.paceSyncLevel, 'Good Sync');
    expect(matchQuality.distanceKm, 12.4);
    expect(matchQuality.ageDifference, 2);
    expect(matchQuality.highlights, [
      'Lives nearby (12.4 km away)',
      'You both enjoy Hiking',
      'Great communication sync',
    ]);
  });

  test(
    'preserves non-null fields when the backend returns unknown distance',
    () {
      final matchQuality = MatchQuality.fromJson({
        'matchId': 'match-1',
        'perspectiveUserId': 'viewer-1',
        'otherUserId': 'other-1',
        'compatibilityScore': 41,
        'compatibilityLabel': 'Fair Match',
        'starDisplay': '⭐⭐',
        'paceSyncLevel': 'Pace Lag',
        'distanceKm': -1.0,
        'ageDifference': 0,
        'highlights': <String>[],
      });

      expect(matchQuality.distanceKm, -1.0);
      expect(matchQuality.highlights, isEmpty);
      expect(matchQuality.compatibilityLabel, isNotEmpty);
      expect(matchQuality.paceSyncLevel, isNotEmpty);
    },
  );
}
