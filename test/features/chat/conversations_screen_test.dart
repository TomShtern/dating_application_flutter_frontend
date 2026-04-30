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
  );

  testWidgets('opens a conversation thread from the primary card action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          conversationsProvider.overrideWith((ref) async => [summary]),
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
    expect(find.text('1 conversation ready to pick back up.'), findsOneWidget);
    expect(find.text('5 messages so far.'), findsOneWidget);
    expect(find.text('Updated Apr 18, 2026'), findsNothing);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);

    final conversationCard = find.ancestor(
      of: find.text('Noa'),
      matching: find.byType(InkWell),
    );
    await tester.scrollUntilVisible(conversationCard, 200);
    await tester.pumpAndSettle();
    await tester.tap(conversationCard);
    await tester.pumpAndSettle();

    expect(find.text('Conversation'), findsOneWidget);
    expect(find.text('See you at 7?'), findsOneWidget);
  });
}
