import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/models/pace_preferences.dart';
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

  group('pacePreferences', () {
    const complete = PacePreferences(
      messagingFrequency: 'OFTEN',
      timeToFirstDate: 'FEW_DAYS',
      communicationStyle: 'TEXT_ONLY',
      depthPreference: 'DEEP_CHAT',
    );

    test('is sent as an object when all four answers are set', () {
      expect(const ProfileUpdateRequest(pacePreferences: complete).toJson(), {
        'pacePreferences': complete.toJson(),
      });
    });

    test('is left out when partly answered, which the backend rejects', () {
      const request = ProfileUpdateRequest(
        pacePreferences: PacePreferences(messagingFrequency: 'OFTEN'),
      );

      expect(request.toJson(), isEmpty);
    });
  });

  group('withCurrentSets', () {
    test('fills interestedIn and interests when they are absent', () {
      const request = ProfileUpdateRequest(bio: 'Hi');

      final filled = request.withCurrentSets(
        currentInterestedIn: const ['MALE'],
        currentInterests: const ['Hiking'],
      );

      expect(filled.toJson(), {
        'bio': 'Hi',
        'interestedIn': ['MALE'],
        'interests': ['Hiking'],
      });
    });

    test('keeps values the caller set', () {
      const request = ProfileUpdateRequest(
        interestedIn: ['FEMALE'],
        interests: ['Chess'],
      );

      final filled = request.withCurrentSets(
        currentInterestedIn: const ['MALE'],
        currentInterests: const ['Hiking'],
      );

      expect(filled.interestedIn, ['FEMALE']);
      expect(filled.interests, ['Chess']);
    });

    test('carries every other field across', () {
      const request = ProfileUpdateRequest(
        name: 'Dana',
        birthDate: '1998-04-02',
        maxDistanceKm: 30,
        smoking: 'NEVER',
      );

      final filled = request.withCurrentSets(
        currentInterestedIn: const [],
        currentInterests: const [],
      );

      expect(filled.name, 'Dana');
      expect(filled.birthDate, '1998-04-02');
      expect(filled.maxDistanceKm, 30);
      expect(filled.smoking, 'NEVER');
    });
  });
}
