import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/models/notification_item.dart';

void main() {
  test('fromJson ignores non-map notification data payloads', () {
    final item = NotificationItem.fromJson({
      'id': 'notification-1',
      'type': 'MATCH',
      'title': 'New match',
      'message': 'You matched with Noa',
      'data': 'unexpected payload',
    });

    expect(item.data, isEmpty);
  });
}
