import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/chat/conversation_thread_screen.dart';
import 'package:flutter_dating_application_1/features/profile/profile_provider.dart';
import 'package:flutter_dating_application_1/models/conversation_summary.dart';
import 'package:flutter_dating_application_1/models/message_dto.dart';
import 'package:flutter_dating_application_1/models/user_detail.dart';
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

    expect(find.text('Conversation with Noa'), findsNothing);
    expect(find.text('Keep it easy to answer.'), findsNothing);
    expect(
      find.text('A detail, a question, or a simple plan works well.'),
      findsNothing,
    );
    expect(find.text('Hey Dana'), findsOneWidget);

    final initialSendButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.send_rounded),
    );
    expect(initialSendButton.onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Hey there');
    await tester.pump();

    final enabledSendButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.send_rounded),
    );
    expect(enabledSendButton.onPressed, isNotNull);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(apiClient.lastSentContent, 'Hey there');
    expect(find.text('You'), findsNothing);
    expect(find.text('Hey there'), findsOneWidget);

    final messageField = tester.widget<TextField>(find.byType(TextField));
    expect(messageField.controller?.text, isEmpty);
  });

  testWidgets(
    'groups messages by day and anchors short threads to the latest messages',
    (WidgetTester tester) async {
      final apiClient = _FakeConversationThreadApiClient(
        messageResponses: [
          [
            MessageDto(
              id: 'message-1',
              conversationId: conversation.id,
              senderId: conversation.otherUserId,
              content: 'Coffee tomorrow?',
              sentAt: DateTime.parse('2026-04-18T14:20:00Z'),
            ),
            MessageDto(
              id: 'message-2',
              conversationId: conversation.id,
              senderId: conversation.otherUserId,
              content: 'I found a place by the water.',
              sentAt: DateTime.parse('2026-04-18T14:22:00Z'),
            ),
            MessageDto(
              id: 'message-3',
              conversationId: conversation.id,
              senderId: currentUser.id,
              content: 'That sounds perfect.',
              sentAt: DateTime.parse('2026-04-19T09:15:00Z'),
            ),
          ],
        ],
        sentMessage: MessageDto(
          id: 'message-4',
          conversationId: conversation.id,
          senderId: currentUser.id,
          content: 'See you there!',
          sentAt: DateTime.parse('2026-04-19T09:20:00Z'),
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
              refreshInterval: Duration.zero,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3 messages so far'), findsOneWidget);
      expect(find.text('Started Apr 18, 2026'), findsOneWidget);
      expect(find.text('Apr 18, 2026'), findsOneWidget);
      expect(find.text('Apr 19, 2026'), findsOneWidget);

      final summaryTop = tester.getTopLeft(find.text('3 messages so far')).dy;
      final screenHeight = tester.getSize(find.byType(Scaffold)).height;
      expect(summaryTop, lessThan(screenHeight * 0.55));

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    },
  );

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

  testWidgets('scrolls to the latest message when the thread opens', (
    WidgetTester tester,
  ) async {
    final messages = List.generate(
      30,
      (index) => MessageDto(
        id: 'message-${index + 1}',
        conversationId: conversation.id,
        senderId: index.isEven ? conversation.otherUserId : currentUser.id,
        content: 'Message ${index + 1}',
        sentAt: DateTime.parse(
          '2026-04-18T14:20:00Z',
        ).add(Duration(minutes: index)),
      ),
    );

    final apiClient = _FakeConversationThreadApiClient(
      messageResponses: [messages],
      sentMessage: MessageDto(
        id: 'message-31',
        conversationId: conversation.id,
        senderId: currentUser.id,
        content: 'Hey there',
        sentAt: DateTime.parse('2026-04-18T14:50:00Z'),
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
            refreshInterval: Duration.zero,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Message 30'), findsOneWidget);
  });

  testWidgets('opens the other user profile from the app bar action', (
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
          otherUserProfileProvider(conversation.otherUserId).overrideWith(
            (ref) async => const UserDetail(
              id: '22222222-2222-2222-2222-222222222222',
              name: 'Noa',
              age: 29,
              bio: 'Always up for a museum date.',
              gender: 'FEMALE',
              interestedIn: ['MALE'],
              approximateLocation: 'Haifa',
              maxDistanceKm: 25,
              photoUrls: ['/photos/noa-1.jpg'],
              state: 'ACTIVE',
            ),
          ),
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

    await tester.tap(find.byTooltip('View profile'));
    await tester.pumpAndSettle();

    expect(find.text('Always up for a museum date.'), findsOneWidget);
  });

  testWidgets('opens safety actions from the conversation app bar', (
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

    await tester.tap(find.byTooltip('Safety actions'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Safety actions').last);
    await tester.pumpAndSettle();

    expect(find.text('Block user'), findsOneWidget);
    expect(find.text('Report user'), findsOneWidget);
    expect(find.text('Unmatch'), findsOneWidget);
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
