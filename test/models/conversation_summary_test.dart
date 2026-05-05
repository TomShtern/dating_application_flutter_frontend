import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/models/conversation_summary.dart';

void main() {
  test('parses the documented conversation summary shape', () {
    final summary = ConversationSummary.fromJson({
      'id':
          '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
      'otherUserId': '22222222-2222-2222-2222-222222222222',
      'otherUserName': 'Noa',
      'messageCount': 5,
      'lastMessageAt': '2026-04-18T14:20:00Z',
    });

    expect(summary.otherUserName, 'Noa');
    expect(summary.messageCount, 5);
    expect(summary.lastMessageAt, DateTime.parse('2026-04-18T14:20:00Z'));
  });

  test(
    'parses additive preview, unread count, and sender cues when provided',
    () {
      final summary = ConversationSummary.fromJson({
        'id':
            '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
        'otherUserId': '22222222-2222-2222-2222-222222222222',
        'otherUserName': 'Noa',
        'messageCount': 5,
        'unreadCount': 3,
        'lastMessage': {
          'content': 'Still on for tonight?',
          'senderId': '11111111-1111-1111-1111-111111111111',
          'senderName': 'Dana',
          'sentAt': '2026-04-18T14:21:00Z',
        },
      });

      expect(summary.lastMessagePreview, 'Still on for tonight?');
      expect(summary.unreadCount, 3);
      expect(summary.lastSenderId, '11111111-1111-1111-1111-111111111111');
      expect(summary.lastSenderName, 'Dana');
      expect(summary.lastMessageAt, DateTime.parse('2026-04-18T14:21:00Z'));
    },
  );
}
