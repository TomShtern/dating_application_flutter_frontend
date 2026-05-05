import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/features/chat/conversation_thread_provider.dart';
import 'package:flutter_dating_application_1/features/chat/conversations_provider.dart';
import 'package:flutter_dating_application_1/features/chat/conversations_screen.dart';
import 'package:flutter_dating_application_1/models/conversation_summary.dart';
import 'package:flutter_dating_application_1/models/message_dto.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';

void main() {
  const currentUser = UserSummary(
    id: '11111111-1111-1111-1111-111111111111',
    name: 'Dana',
    age: 27,
    state: 'ACTIVE',
  );

  final summary = ConversationSummary(
    id: '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
    otherUserId: '22222222-2222-2222-2222-222222222222',
    otherUserName: 'Noa',
    messageCount: 5,
    lastMessageAt: DateTime.parse('2026-04-18T14:20:00Z'),
    lastMessagePreview: 'You were right about the coffee spot.',
    unreadCount: 2,
    lastSenderId: currentUser.id,
  );

  final secondSummary = ConversationSummary(
    id: 'conversation-2',
    otherUserId: '33333333-3333-3333-3333-333333333333',
    otherUserName: 'Maya',
    messageCount: 2,
    lastMessageAt: DateTime.parse('2026-04-18T16:40:00Z'),
    lastMessagePreview: 'Want to try the museum on Sunday?',
    unreadCount: 2,
    lastSenderId: '33333333-3333-3333-3333-333333333333',
  );

  testWidgets('opens a conversation thread from the primary card action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          conversationsProvider.overrideWith(
            (ref) async => [summary, secondSummary],
          ),
          conversationThreadProvider(summary.id).overrideWith(
            (ref) async => [
              MessageDto(
                id: 'message-1',
                conversationId: summary.id,
                senderId: summary.otherUserId,
                content: 'See you at 7?',
                sentAt: DateTime.parse('2026-04-18T14:20:00Z'),
              ),
            ],
          ),
        ],
        child: MaterialApp(home: ConversationsScreen(currentUser: currentUser)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open conversations'), findsOneWidget);
    expect(find.text('Noa'), findsOneWidget);
    expect(find.text('2 conversations ready to pick back up.'), findsOneWidget);
    expect(
      find.text('You: You were right about the coffee spot.'),
      findsOneWidget,
    );
    expect(find.text('2 unread'), findsNWidgets(4));
    expect(find.text('Maya'), findsOneWidget);
    expect(find.text('Updated Apr 18, 2026'), findsNothing);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(2));
    expect(find.text('Open'), findsNWidgets(2));

    await tester.enterText(find.byType(TextField), 'coffee');
    await tester.pumpAndSettle();

    expect(find.text('Noa'), findsOneWidget);
    expect(find.text('Maya'), findsNothing);

    await tester.tap(find.text('Noa').first);
    await tester.pumpAndSettle();

    expect(find.text('Conversation'), findsOneWidget);
    expect(find.text('See you at 7?'), findsOneWidget);
  });
}
