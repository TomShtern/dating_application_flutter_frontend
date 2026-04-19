import 'package:flutter_test/flutter_test.dart';

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
        'bio': 'Updated bio',
        'gender': 'FEMALE',
        'interestedIn': ['MALE', 'FEMALE'],
        'maxDistanceKm': 42,
      });
    },
  );
}
