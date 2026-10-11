import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/models/profile_completion_info.dart';

void main() {
  test('parses the backend completion fields', () {
    final info = ProfileCompletionInfo.fromJson(const {
      'missingProfileFields': ['bio', 'photoUrls'],
      'missingProfileFieldLabels': ['Bio', 'Photo'],
      'requiredProfileFieldCount': 8,
      'profileComplete': false,
      'canActivate': false,
      'canBrowse': false,
    });

    expect(info.missingProfileFields, ['bio', 'photoUrls']);
    expect(info.missingProfileFieldLabels, ['Bio', 'Photo']);
    expect(info.requiredProfileFieldCount, 8);
    expect(info.profileComplete, isFalse);
  });

  test('a null or empty body reads as an incomplete profile', () {
    expect(ProfileCompletionInfo.fromJson(null).profileComplete, isFalse);
    expect(ProfileCompletionInfo.fromJson(const {}).missingProfileFields, []);
  });

  test('ignores non-string entries instead of throwing', () {
    final info = ProfileCompletionInfo.fromJson(const {
      'missingProfileFields': ['bio', 3, null],
      'missingProfileFieldLabels': 'Bio',
    });

    expect(info.missingProfileFields, ['bio']);
    expect(info.missingProfileFieldLabels, isEmpty);
  });

  test('field order matches the backend required-field keys', () {
    expect(ProfileCompletionInfo.fieldOrder, [
      'name',
      'bio',
      'birthDate',
      'gender',
      'interestedIn',
      'location',
      'photoUrls',
      'pacePreferences',
    ]);
  });

  test('every backend key has a friendly label, unknown keys fall back', () {
    for (final key in ProfileCompletionInfo.fieldOrder) {
      expect(
        ProfileCompletionInfo.defaultLabel(key),
        isNot(startsWith('Complete:')),
        reason: key,
      );
    }
    expect(
      ProfileCompletionInfo.defaultLabel('shoeSize'),
      'Complete: shoeSize',
    );
  });
}
