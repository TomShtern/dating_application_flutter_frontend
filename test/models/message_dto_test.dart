import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/models/message_dto.dart';

void main() {
  test('parses the documented message dto shape', () {
    final message = MessageDto.fromJson({
      'id': '44444444-4444-4444-4444-444444444444',
      'conversationId':
          '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
      'senderId': '11111111-1111-1111-1111-111111111111',
      'content': 'Hey there',
      'sentAt': '2026-04-18T14:20:00Z',
    });

    expect(message.id, '44444444-4444-4444-4444-444444444444');
    expect(
      message.conversationId,
      '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
    );
    expect(message.senderId, '11111111-1111-1111-1111-111111111111');
    expect(message.content, 'Hey there');
    expect(message.sentAt, DateTime.parse('2026-04-18T14:20:00Z'));
  });
}
