import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/models/user_detail.dart';

void main() {
  test('parses the documented profile payload from JSON', () {
    final detail = UserDetail.fromJson({
      'id': '11111111-1111-1111-1111-111111111111',
      'name': 'Dana',
      'age': 27,
      'bio': 'Loves coffee and beach walks.',
      'gender': 'FEMALE',
      'interestedIn': ['MALE'],
      'approximateLocation': 'Tel Aviv',
      'maxDistanceKm': 50,
      'photoUrls': ['/photos/dana-1.jpg'],
      'state': 'ACTIVE',
    });

    expect(detail.id, '11111111-1111-1111-1111-111111111111');
    expect(detail.name, 'Dana');
    expect(detail.age, 27);
    expect(detail.bio, 'Loves coffee and beach walks.');
    expect(detail.gender, 'FEMALE');
    expect(detail.interestedIn, ['MALE']);
    expect(detail.approximateLocation, 'Tel Aviv');
    expect(detail.maxDistanceKm, 50);
    expect(detail.photoUrls, ['/photos/dana-1.jpg']);
    expect(detail.state, 'ACTIVE');
  });

  test('uses safe defaults when optional profile fields are missing', () {
    final detail = UserDetail.fromJson({'id': 'user-1'});

    expect(detail.id, 'user-1');
    expect(detail.name, 'Unknown user');
    expect(detail.age, 0);
    expect(detail.bio, isEmpty);
    expect(detail.gender, isEmpty);
    expect(detail.interestedIn, isEmpty);
    expect(detail.approximateLocation, isEmpty);
    expect(detail.maxDistanceKm, 0);
    expect(detail.photoUrls, isEmpty);
    expect(detail.state, 'UNKNOWN');
  });
}
