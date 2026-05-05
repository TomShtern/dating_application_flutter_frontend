import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/models/discovery_preferences.dart';
import 'package:flutter_dating_application_1/models/profile_edit_snapshot.dart';

void main() {
  test('fromProfileEditSnapshot extracts discovery fields', () {
    final snapshot = ProfileEditSnapshot.fromJson({
      'userId': 'user-1',
      'editable': {
        'minAge': 25,
        'maxAge': 35,
        'maxDistanceKm': 42,
        'interestedIn': ['MALE', 'NON_BINARY'],
        'dealbreakers': {
          'acceptableSmoking': ['NEVER'],
          'acceptableDrinking': ['SOCIALLY'],
          'acceptableKidsStance': ['OPEN'],
          'acceptableLookingFor': ['LONG_TERM'],
          'acceptableEducation': ['BACHELORS'],
          'minHeightCm': null,
          'maxHeightCm': null,
          'maxAgeDifference': 5,
        },
      },
      'readOnly': {
        'name': 'Dana',
        'state': 'ACTIVE',
        'photoUrls': [],
      },
    });

    final prefs = DiscoveryPreferences.fromProfileEditSnapshot(snapshot);

    expect(prefs.minAge, 25);
    expect(prefs.maxAge, 35);
    expect(prefs.maxDistanceKm, 42);
    expect(prefs.interestedIn, ['MALE', 'NON_BINARY']);
    expect(prefs.dealbreakers.acceptableSmoking, ['NEVER']);
    expect(prefs.dealbreakers.acceptableDrinking, ['SOCIALLY']);
    expect(prefs.dealbreakers.maxAgeDifference, 5);
  });

  test('toProfileUpdateRequest produces correct payload', () {
    const prefs = DiscoveryPreferences(
      minAge: 25,
      maxAge: 35,
      maxDistanceKm: 42,
      interestedIn: ['MALE'],
      dealbreakers: ProfileEditDealbreakers(
        acceptableSmoking: ['NEVER'],
        acceptableDrinking: ['SOCIALLY'],
        acceptableKidsStance: ['OPEN'],
        acceptableLookingFor: ['LONG_TERM'],
        acceptableEducation: ['BACHELORS'],
        maxAgeDifference: 5,
      ),
    );

    final request = prefs.toProfileUpdateRequest();

    expect(request.minAge, 25);
    expect(request.maxAge, 35);
    expect(request.maxDistanceKm, 42);
    expect(request.interestedIn, ['MALE']);
    expect(request.dealbreakers?.acceptableSmoking, ['NEVER']);
    expect(request.dealbreakers?.maxAgeDifference, 5);
  });

  test('toProfileUpdateRequest omits empty interestedIn', () {
    const prefs = DiscoveryPreferences(
      minAge: 25,
      interestedIn: [],
    );

    final request = prefs.toProfileUpdateRequest();

    expect(request.interestedIn, isNull);
  });

  test('copyWith updates selected fields', () {
    const prefs = DiscoveryPreferences(minAge: 25, maxAge: 35);

    final updated = prefs.copyWith(maxAge: 40, maxDistanceKm: 50);

    expect(updated.minAge, 25);
    expect(updated.maxAge, 40);
    expect(updated.maxDistanceKm, 50);
  });

  test('equality works correctly', () {
    const prefsA = DiscoveryPreferences(
      minAge: 25,
      interestedIn: ['MALE'],
    );
    const prefsB = DiscoveryPreferences(
      minAge: 25,
      interestedIn: ['MALE'],
    );
    const prefsC = DiscoveryPreferences(
      minAge: 26,
      interestedIn: ['MALE'],
    );

    expect(prefsA, prefsB);
    expect(prefsA.hashCode, prefsB.hashCode);
    expect(prefsA, isNot(prefsC));
  });
}
