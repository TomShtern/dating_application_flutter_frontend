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

  test('exposes stable notification routing helpers', () {
    final match = NotificationItem.fromJson({
      'id': 'notification-1',
      'type': 'MATCH_FOUND',
      'title': 'New match',
      'message': 'You have a new match',
      'data': {
        'matchId': 'match-1',
        'conversationId': 'match-1',
        'otherUserId': 'user-2',
      },
    });
    final unknown = NotificationItem.fromJson({
      'id': 'notification-2',
      'type': 'UNKNOWN_FUTURE_TYPE',
      'title': 'Heads up',
      'message': 'Render this notification without a deep link.',
      'data': {'conversationId': 'conversation-1'},
    });

    expect(match.isKnownRoutableType, isTrue);
    expect(match.matchId, 'match-1');
    expect(match.conversationId, 'match-1');
    expect(match.otherUserId, 'user-2');
    expect(unknown.isKnownRoutableType, isFalse);
    expect(unknown.conversationId, isNull);
  });

  test('keeps known types display-only when required data is missing', () {
    final message = NotificationItem.fromJson({
      'id': 'notification-3',
      'type': 'NEW_MESSAGE',
      'title': 'New message',
      'message': 'You have a fresh reply.',
      'data': {'conversationId': 'conversation-1'},
    });

    expect(message.isKnownType, isTrue);
    expect(message.isKnownRoutableType, isFalse);
    expect(message.safeRoute, isNull);
    expect(message.conversationId, isNull);
  });

  test('keeps display-only known types unrouted even with required data', () {
    final exit = NotificationItem.fromJson({
      'id': 'notification-4',
      'type': 'GRACEFUL_EXIT',
      'title': 'Conversation closed',
      'message': 'This match ended gracefully.',
      'data': {'initiatorId': 'user-2', 'matchId': 'match-1'},
    });

    expect(exit.isKnownType, isTrue);
    expect(exit.isKnownRoutableType, isFalse);
    expect(exit.safeRoute, isNull);
  });
}
