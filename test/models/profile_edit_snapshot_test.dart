import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/models/profile_edit_snapshot.dart';

void main() {
  test('fromJson parses editable and read-only profile snapshot fields', () {
    final snapshot = ProfileEditSnapshot.fromJson({
      'userId': 'user-1',
      'editable': {
        'bio': 'Runner, coffee person, and weekend hiker.',
        'birthDate': '1996-07-18',
        'gender': 'FEMALE',
        'interestedIn': ['MALE'],
        'maxDistanceKm': 25,
        'minAge': 27,
        'maxAge': 38,
        'heightCm': 168,
        'smoking': 'NEVER',
        'drinking': 'SOCIALLY',
        'wantsKids': 'OPEN',
        'lookingFor': 'LONG_TERM',
        'education': 'BACHELORS',
        'interests': ['COFFEE', 'HIKING', 'TRAVEL'],
        'dealbreakers': {
          'acceptableSmoking': ['NEVER'],
          'acceptableDrinking': [],
          'acceptableKidsStance': ['OPEN', 'SOMEDAY'],
          'acceptableLookingFor': ['LONG_TERM', 'MARRIAGE'],
          'acceptableEducation': ['BACHELORS', 'MASTERS'],
          'minHeightCm': null,
          'maxHeightCm': null,
          'maxAgeDifference': 6,
        },
        'location': {
          'label': 'Tel Aviv, Tel Aviv District',
          'latitude': 32.0853,
          'longitude': 34.7818,
          'precision': 'CITY',
          'countryCode': 'IL',
          'cityName': 'Tel Aviv',
          'zipCode': null,
          'approximate': false,
        },
      },
      'readOnly': {
        'name': 'Dana',
        'state': 'ACTIVE',
        'photoUrls': ['/photos/dana-1.jpg', '/photos/dana-2.jpg'],
        'verified': true,
        'verificationMethod': 'EMAIL',
        'verifiedAt': '2026-04-24T08:30:00Z',
      },
    });

    expect(snapshot.userId, 'user-1');
    expect(snapshot.editable.bio, 'Runner, coffee person, and weekend hiker.');
    expect(snapshot.editable.interestedIn, ['MALE']);
    expect(snapshot.editable.interests, ['COFFEE', 'HIKING', 'TRAVEL']);
    expect(snapshot.editable.dealbreakers.acceptableSmoking, ['NEVER']);
    expect(snapshot.editable.dealbreakers.acceptableDrinking, isEmpty);
    expect(snapshot.editable.dealbreakers.maxAgeDifference, 6);
    expect(snapshot.editable.location?.cityName, 'Tel Aviv');
    expect(snapshot.editable.location?.countryCode, 'IL');
    expect(snapshot.readOnly.name, 'Dana');
    expect(snapshot.readOnly.photoUrls, [
      '/photos/dana-1.jpg',
      '/photos/dana-2.jpg',
    ]);
    expect(snapshot.readOnly.verified, isTrue);
    expect(snapshot.readOnly.verifiedAt, DateTime.utc(2026, 4, 24, 8, 30));
  });
}
