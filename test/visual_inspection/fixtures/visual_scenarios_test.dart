import 'package:flutter_test/flutter_test.dart';

import 'visual_fixture_catalog.dart';

void main() {
  group('visual fixture catalog', () {
    test('exposes richer signed-in shell data', () {
      expect(availableUsers, hasLength(2));
      expect(browseResponse.candidates, hasLength(5));
      expect(matchesResponse.matches, hasLength(5));
      expect(conversations, hasLength(5));
    });

    test('exposes richer detail and utility screen data', () {
      expect(conversationMessages, hasLength(12));
      expect(standoutsSnapshot.standouts, hasLength(5));
      expect(pendingLikers, hasLength(5));
      expect(blockedUsers, hasLength(4));
      expect(notifications, hasLength(8));
      expect(userStats.items, hasLength(8));
      expect(achievements, hasLength(5));
      expect(locationCountries, hasLength(2));
      expect(locationSuggestions, hasLength(2));
    });
  });
}
