import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/models/profile_edit_snapshot.dart';
import 'package:flutter_dating_application_1/models/profile_update_request.dart';

void main() {
  test(
    'serializes the partial editable profile payload for the documented endpoint',
    () {
      const request = ProfileUpdateRequest(
        bio: '  Updated bio  ',
        gender: ' FEMALE ',
        interestedIn: [' MALE ', '', 'FEMALE '],
        maxDistanceKm: 42,
      );

      expect(request.toJson(), {
        'bio': '  Updated bio  ',
        'gender': ' FEMALE ',
        'interestedIn': [' MALE ', '', 'FEMALE '],
        'maxDistanceKm': 42,
      });
    },
  );

  test('serializes discovery-related fields added to profile update', () {
    const request = ProfileUpdateRequest(
      minAge: 25,
      maxAge: 35,
      maxDistanceKm: 50,
      smoking: 'NEVER',
      drinking: 'SOCIALLY',
      wantsKids: 'OPEN',
      lookingFor: 'LONG_TERM',
      education: 'BACHELORS',
      interests: ['COFFEE', 'HIKING'],
      dealbreakers: ProfileEditDealbreakers(
        acceptableSmoking: ['NEVER'],
        acceptableDrinking: ['SOCIALLY'],
        acceptableKidsStance: ['OPEN'],
        acceptableLookingFor: ['LONG_TERM'],
        acceptableEducation: ['BACHELORS'],
        maxAgeDifference: 5,
      ),
    );

    expect(request.toJson(), {
      'minAge': 25,
      'maxAge': 35,
      'maxDistanceKm': 50,
      'smoking': 'NEVER',
      'drinking': 'SOCIALLY',
      'wantsKids': 'OPEN',
      'lookingFor': 'LONG_TERM',
      'education': 'BACHELORS',
      'interests': ['COFFEE', 'HIKING'],
      'dealbreakers': {
        'acceptableSmoking': ['NEVER'],
        'acceptableDrinking': ['SOCIALLY'],
        'acceptableKidsStance': ['OPEN'],
        'acceptableLookingFor': ['LONG_TERM'],
        'acceptableEducation': ['BACHELORS'],
        'maxAgeDifference': 5,
      },
    });
  });

  test('omits null dealbreaker sub-fields', () {
    const request = ProfileUpdateRequest(
      dealbreakers: ProfileEditDealbreakers(
        acceptableSmoking: [],
        acceptableDrinking: [],
        acceptableKidsStance: [],
        acceptableLookingFor: [],
        acceptableEducation: [],
      ),
    );

    expect(request.toJson()['dealbreakers'], {
      'acceptableSmoking': [],
      'acceptableDrinking': [],
      'acceptableKidsStance': [],
      'acceptableLookingFor': [],
      'acceptableEducation': [],
    });
  });

  test('equality includes new discovery fields', () {
    const requestA = ProfileUpdateRequest(
      smoking: 'NEVER',
      dealbreakers: ProfileEditDealbreakers(
        acceptableSmoking: ['NEVER'],
        acceptableDrinking: [],
        acceptableKidsStance: [],
        acceptableLookingFor: [],
        acceptableEducation: [],
      ),
    );
    const requestB = ProfileUpdateRequest(
      smoking: 'NEVER',
      dealbreakers: ProfileEditDealbreakers(
        acceptableSmoking: ['NEVER'],
        acceptableDrinking: [],
        acceptableKidsStance: [],
        acceptableLookingFor: [],
        acceptableEducation: [],
      ),
    );
    const requestC = ProfileUpdateRequest(
      smoking: 'SOCIALLY',
      dealbreakers: ProfileEditDealbreakers(
        acceptableSmoking: ['NEVER'],
        acceptableDrinking: [],
        acceptableKidsStance: [],
        acceptableLookingFor: [],
        acceptableEducation: [],
      ),
    );

    expect(requestA, requestB);
    expect(requestA.hashCode, requestB.hashCode);
    expect(requestA, isNot(requestC));
  });
}
