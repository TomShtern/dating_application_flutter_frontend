import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/models/location_metadata.dart';

void main() {
  test('LocationCountry compares by value', () {
    const left = LocationCountry(
      code: 'IL',
      name: 'Israel',
      flagEmoji: '🇮🇱',
      available: true,
      defaultSelection: true,
    );
    const right = LocationCountry(
      code: 'IL',
      name: 'Israel',
      flagEmoji: '🇮🇱',
      available: true,
      defaultSelection: true,
    );

    expect(left, right);
    expect(left.hashCode, right.hashCode);
  });

  test('LocationCity compares by value', () {
    const left = LocationCity(
      name: 'Tel Aviv',
      district: 'Tel Aviv',
      countryCode: 'IL',
      priority: 10,
    );
    const right = LocationCity(
      name: 'Tel Aviv',
      district: 'Tel Aviv',
      countryCode: 'IL',
      priority: 10,
    );

    expect(left, right);
    expect(left.hashCode, right.hashCode);
  });

  test('ResolvedLocation compares by value', () {
    const left = ResolvedLocation(
      label: 'Tel Aviv, Israel',
      latitude: 32.0853,
      longitude: 34.7818,
      precision: 'city',
      approximate: true,
      message: 'Approximate location resolved',
    );
    const right = ResolvedLocation(
      label: 'Tel Aviv, Israel',
      latitude: 32.0853,
      longitude: 34.7818,
      precision: 'city',
      approximate: true,
      message: 'Approximate location resolved',
    );

    expect(left, right);
    expect(left.hashCode, right.hashCode);
  });
}
