import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/chat/conversation_thread_screen.dart';
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

  final conversation = ConversationSummary(
    id: '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
    otherUserId: '22222222-2222-2222-2222-222222222222',
    otherUserName: 'Noa',
    messageCount: 1,
    lastMessageAt: DateTime.parse('2026-04-18T14:20:00Z'),
  );

  testWidgets('renders existing messages and sends a new one', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeConversationThreadApiClient(
      messageResponses: [
        [
          MessageDto(
            id: 'message-1',
            conversationId: conversation.id,
            senderId: conversation.otherUserId,
            content: 'Hey Dana',
            sentAt: DateTime.parse('2026-04-18T14:20:00Z'),
          ),
        ],
        [
          MessageDto(
            id: 'message-1',
            conversationId: conversation.id,
            senderId: conversation.otherUserId,
            content: 'Hey Dana',
            sentAt: DateTime.parse('2026-04-18T14:20:00Z'),
          ),
          MessageDto(
            id: 'message-2',
            conversationId: conversation.id,
            senderId: currentUser.id,
            content: 'Hey there',
            sentAt: DateTime.parse('2026-04-18T14:21:00Z'),
          ),
        ],
      ],
      sentMessage: MessageDto(
        id: 'message-2',
        conversationId: conversation.id,
        senderId: currentUser.id,
        content: 'Hey there',
        sentAt: DateTime.parse('2026-04-18T14:21:00Z'),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          selectedUserProvider.overrideWith((ref) async => currentUser),
        ],
        child: MaterialApp(
          home: ConversationThreadScreen(
            currentUser: currentUser,
            conversation: conversation,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Conversation with Noa'), findsOneWidget);
    expect(find.text('Hey Dana'), findsOneWidget);

    final initialSendButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Send'),
    );
    expect(initialSendButton.onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Hey there');
    await tester.pump();

    final enabledSendButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Send'),
    );
    expect(enabledSendButton.onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, 'Send'));
    await tester.pumpAndSettle();

    expect(apiClient.lastSentContent, 'Hey there');
    expect(find.text('You'), findsOneWidget);
    expect(find.text('Hey there'), findsOneWidget);

    final messageField = tester.widget<TextField>(find.byType(TextField));
    expect(messageField.controller?.text, isEmpty);
  });

  testWidgets('shows an empty state when the conversation has no messages', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeConversationThreadApiClient(
      messageResponses: const [[]],
      sentMessage: MessageDto(
        id: 'message-1',
        conversationId: conversation.id,
        senderId: currentUser.id,
        content: 'Hey there',
        sentAt: DateTime.parse('2026-04-18T14:21:00Z'),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          selectedUserProvider.overrideWith((ref) async => currentUser),
        ],
        child: MaterialApp(
          home: ConversationThreadScreen(
            currentUser: currentUser,
            conversation: conversation,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No messages yet. Say hello to start the conversation.'),
      findsOneWidget,
    );
  });

  testWidgets('refreshes the thread periodically while visible', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeConversationThreadApiClient(
      messageResponses: [
        [
          MessageDto(
            id: 'message-1',
            conversationId: conversation.id,
            senderId: conversation.otherUserId,
            content: 'Hey Dana',
            sentAt: DateTime.parse('2026-04-18T14:20:00Z'),
          ),
        ],
        [
          MessageDto(
            id: 'message-1',
            conversationId: conversation.id,
            senderId: conversation.otherUserId,
            content: 'Hey Dana',
            sentAt: DateTime.parse('2026-04-18T14:20:00Z'),
          ),
        ],
      ],
      sentMessage: MessageDto(
        id: 'message-2',
        conversationId: conversation.id,
        senderId: currentUser.id,
        content: 'Hey there',
        sentAt: DateTime.parse('2026-04-18T14:21:00Z'),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          selectedUserProvider.overrideWith((ref) async => currentUser),
        ],
        child: MaterialApp(
          home: ConversationThreadScreen(
            currentUser: currentUser,
            conversation: conversation,
            refreshInterval: const Duration(seconds: 5),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(apiClient.getMessagesCalls, 1);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump();

    expect(apiClient.getMessagesCalls, 2);
  });
}

class _FakeConversationThreadApiClient extends ApiClient {
  _FakeConversationThreadApiClient({
    required this.messageResponses,
    required this.sentMessage,
  }) : super(dio: Dio());

  final List<List<MessageDto>> messageResponses;
  final MessageDto sentMessage;
  int getMessagesCalls = 0;
  String? lastSentContent;

  @override
  Future<List<MessageDto>> getMessages({
    required String conversationId,
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    final index = getMessagesCalls < messageResponses.length
        ? getMessagesCalls
        : messageResponses.length - 1;
    getMessagesCalls++;
    return messageResponses[index];
  }

  @override
  Future<MessageDto> sendMessage({
    required String conversationId,
    required String userId,
    required String content,
  }) async {
    lastSentContent = content;
    return sentMessage;
  }
}
