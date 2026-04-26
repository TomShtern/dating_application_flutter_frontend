import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_dating_application_1/features/profile/profile_provider.dart';

import 'visual_scenarios.dart';

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

    test('includes Stage B media fields across people surfaces', () {
      final firstCandidate = browseResponse.candidates.first;
      final firstMatch = matchesResponse.matches.first;
      final firstStandout = standoutsSnapshot.standouts.first;
      final firstPendingLiker = pendingLikers.first;

      expect(firstCandidate.primaryPhotoUrl, isNotNull);
      expect(firstCandidate.photoUrls, isNotEmpty);
      expect(firstCandidate.approximateLocation, isNotNull);
      expect(firstCandidate.summaryLine, isNotNull);

      expect(dailyPick.primaryPhotoUrl, isNotNull);
      expect(dailyPick.photoUrls, isNotEmpty);
      expect(dailyPick.approximateLocation, isNotNull);
      expect(dailyPick.summaryLine, isNotNull);

      expect(firstMatch.primaryPhotoUrl, isNotNull);
      expect(firstMatch.photoUrls, isNotEmpty);
      expect(firstMatch.approximateLocation, isNotNull);
      expect(firstMatch.summaryLine, isNotNull);

      expect(firstStandout.primaryPhotoUrl, isNotNull);
      expect(firstStandout.photoUrls, isNotEmpty);
      expect(firstStandout.approximateLocation, isNotNull);
      expect(firstStandout.summaryLine, isNotNull);

      expect(firstPendingLiker.primaryPhotoUrl, isNotNull);
      expect(firstPendingLiker.photoUrls, isNotEmpty);
      expect(firstPendingLiker.approximateLocation, isNotNull);
      expect(firstPendingLiker.summaryLine, isNotNull);
    });

    test(
      'signed-in visual overrides preload browse presentation context',
      () async {
        SharedPreferences.setMockInitialValues({});
        final preferences = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [...signedInShellOverrides(preferences)],
        );
        addTearDown(container.dispose);

        final candidateContext = await container.read(
          presentationContextProvider(
            browseResponse.candidates.first.id,
          ).future,
        );
        final dailyPickContext = await container.read(
          presentationContextProvider(dailyPick.userId).future,
        );

        expect(candidateContext.summary, contains('Shown because'));
        expect(candidateContext.reasonTags, isNotEmpty);
        expect(dailyPickContext.summary, contains('Shown because'));
        expect(dailyPickContext.reasonTags, isNotEmpty);
      },
    );

    test('signed-in visual overrides preload profile edit snapshot', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [...baseSignedInOverrides(preferences)],
      );
      addTearDown(container.dispose);

      final snapshot = await container.read(profileEditSnapshotProvider.future);

      expect(snapshot.userId, currentUser.id);
      expect(snapshot.editable.bio, isNotNull);
      expect(snapshot.readOnly.photoUrls, isNotEmpty);
    });

    test('other-user visual overrides preload presentation context', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          ...baseSignedInOverrides(preferences),
          ...otherUserProfileOverrides,
        ],
      );
      addTearDown(container.dispose);

      final contextData = await container.read(
        presentationContextProvider(otherUserProfileDetail.id).future,
      );

      expect(contextData.targetUserId, otherUserProfileDetail.id);
      expect(contextData.summary, contains('Shown because'));
      expect(contextData.details, isNotEmpty);
    });
  });
}
