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
}
