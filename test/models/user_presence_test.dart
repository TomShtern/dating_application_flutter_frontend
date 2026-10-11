import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/models/user_presence.dart';

void main() {
  test('parses status, typing and checkedAt', () {
    final presence = UserPresence.fromJson({
      'status': 'AWAY',
      'typing': true,
      'checkedAt': '2026-10-11T09:30:00Z',
    });

    expect(presence.status, PresenceStatus.away);
    expect(presence.typing, isTrue);
    expect(presence.checkedAt, DateTime.parse('2026-10-11T09:30:00Z'));
  });

  test('an unknown or malformed response reads as offline, never throws', () {
    for (final json in <Map<String, dynamic>>[
      {},
      {'status': 'INVISIBLE', 'typing': null},
      {'status': 3, 'typing': 'yes', 'checkedAt': 12},
    ]) {
      final presence = UserPresence.fromJson(json);

      expect(presence.status, PresenceStatus.offline);
      expect(presence.typing, isFalse);
      expect(presence.checkedAt, isNull);
    }
  });
}
