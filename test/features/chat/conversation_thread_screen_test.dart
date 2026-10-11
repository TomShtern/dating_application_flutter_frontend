import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/api/api_error.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/chat/conversation_thread_screen.dart';
import 'package:flutter_dating_application_1/features/presence/presence_widgets.dart';
import 'package:flutter_dating_application_1/features/profile/profile_provider.dart';
import 'package:flutter_dating_application_1/models/conversation_summary.dart';
import 'package:flutter_dating_application_1/models/message_dto.dart';
import 'package:flutter_dating_application_1/models/user_detail.dart';
import 'package:flutter_dating_application_1/models/user_presence.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';
import 'package:flutter_dating_application_1/theme/app_theme.dart';

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

  final greeting = MessageDto(
    id: 'message-1',
    conversationId: conversation.id,
    senderId: conversation.otherUserId,
    content: 'Hey Dana',
    sentAt: DateTime.parse('2026-04-18T14:20:00Z'),
  );

  Future<_FakeConversationThreadApiClient> pumpThreadWithPresence(
    WidgetTester tester, {
    UserPresence? presence,
    ApiError? presenceError,
  }) async {
    final apiClient =
        _FakeConversationThreadApiClient(
            messageResponses: [
              [greeting],
            ],
            sentMessage: greeting,
          )
          ..presence = presence
          ..presenceError = presenceError;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          selectedUserProvider.overrideWith((ref) async => currentUser),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: ConversationThreadScreen(
            currentUser: currentUser,
            conversation: conversation,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return apiClient;
  }

  testWidgets('shows Online in the header from the presence poll', (
    WidgetTester tester,
  ) async {
    final apiClient = await pumpThreadWithPresence(
      tester,
      presence: const UserPresence(
        status: PresenceStatus.online,
        typing: false,
      ),
    );

    expect(find.text('Online'), findsOneWidget);
    expect(find.text('Tap name to view profile'), findsNothing);
    expect(apiClient.presenceRequests.first, (
      conversation.otherUserId,
      conversation.id,
    ));

    apiClient.presence = const UserPresence(
      status: PresenceStatus.away,
      typing: false,
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();

    expect(find.text('Away'), findsOneWidget);
    expect(find.text('Online'), findsNothing);

    apiClient.presence = const UserPresence(
      status: PresenceStatus.offline,
      typing: false,
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();

    expect(find.text('Away'), findsNothing);
    expect(find.text('Tap name to view profile'), findsOneWidget);
  });

  testWidgets('shows and clears the typing indicator from the presence poll', (
    WidgetTester tester,
  ) async {
    final apiClient = await pumpThreadWithPresence(
      tester,
      presence: const UserPresence(status: PresenceStatus.online, typing: true),
    );

    expect(find.text('typing'), findsOneWidget);
    expect(find.byType(TypingDots), findsOneWidget);

    apiClient.presence = const UserPresence(
      status: PresenceStatus.online,
      typing: false,
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();

    expect(find.text('typing'), findsNothing);
    expect(find.byType(TypingDots), findsNothing);
    expect(find.text('Online'), findsOneWidget);
  });

  for (final status in [401, 403, 404, 429]) {
    testWidgets('a $status on presence hides the indicators silently', (
      WidgetTester tester,
    ) async {
      final apiClient = await pumpThreadWithPresence(
        tester,
        presence: const UserPresence(
          status: PresenceStatus.online,
          typing: true,
        ),
      );
      expect(find.text('typing'), findsOneWidget);

      apiClient.presenceError = ApiError(
        message: 'Refused',
        statusCode: status,
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      expect(find.text('typing'), findsNothing);
      expect(find.text('Online'), findsNothing);
      expect(find.text('Tap name to view profile'), findsOneWidget);
      expect(find.text('Refused'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      // Chat itself is untouched.
      expect(find.text('Hey Dana'), findsOneWidget);

      // And it backs off instead of asking again every poll.
      final requestsAfterFailure = apiClient.presenceRequests.length;
      await tester.pump(const Duration(seconds: 20));
      expect(apiClient.presenceRequests, hasLength(requestsAfterFailure));
    });
  }

  testWidgets('reports typing at most once per 5 seconds, only with text', (
    WidgetTester tester,
  ) async {
    final apiClient = await pumpThreadWithPresence(tester);
    final field = find.byType(TextField);

    await tester.enterText(field, 'H');
    await tester.enterText(field, 'He');
    await tester.enterText(field, 'Hey');
    await tester.pump();

    expect(apiClient.typingConversationIds, [conversation.id]);

    await tester.pump(const Duration(seconds: 4));
    await tester.enterText(field, 'Hey t');
    expect(apiClient.typingConversationIds, hasLength(1));

    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(field, 'Hey th');
    expect(apiClient.typingConversationIds, hasLength(2));

    // An emptied field stops reporting, even after the window has passed.
    await tester.pump(const Duration(seconds: 5));
    await tester.enterText(field, '');
    await tester.pump();
    expect(apiClient.typingConversationIds, hasLength(2));
  });

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
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.light,
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
    expect(find.text('Tap name to view profile'), findsOneWidget);
    expect(find.text('Hey Dana'), findsOneWidget);

    final initialSendButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.arrow_upward_rounded),
    );
    expect(initialSendButton.onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Hey there');
    await tester.pump();

    final enabledSendButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.arrow_upward_rounded),
    );
    expect(enabledSendButton.onPressed, isNotNull);

    await tester.tap(
      find.widgetWithIcon(IconButton, Icons.arrow_upward_rounded),
    );
    await tester.pumpAndSettle();

    expect(apiClient.lastSentContent, 'Hey there');
    expect(find.text('You'), findsNothing);
    expect(find.text('Hey there'), findsOneWidget);

    final incomingBubbleDecoration = _nearestDecoratedBoxDecoration(
      tester,
      find.text('Hey Dana'),
    );
    expect(incomingBubbleDecoration.color, isNotNull);

    final outgoingBubbleDecoration = _nearestDecoratedBoxDecoration(
      tester,
      find.text('Hey there'),
    );
    expect(outgoingBubbleDecoration.gradient, isA<LinearGradient>());

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
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.light,
            home: ConversationThreadScreen(
              currentUser: currentUser,
              conversation: conversation,
              refreshInterval: Duration.zero,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Apr 18'), findsOneWidget);
      expect(find.text('Apr 19'), findsOneWidget);

      expect(find.text('That sounds perfect.'), findsOneWidget);

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
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.light,
          home: ConversationThreadScreen(
            currentUser: currentUser,
            conversation: conversation,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No messages yet'), findsOneWidget);
    expect(
      find.text('Start the conversation with Noa when you\'re ready.'),
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
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.light,
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
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.light,
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
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.light,
          home: ConversationThreadScreen(
            currentUser: currentUser,
            conversation: conversation,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('View profile'), findsNothing);
    expect(find.byTooltip('Safety actions'), findsNothing);

    await tester.tap(find.byTooltip('Conversation options'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('View profile'));
    await tester.pumpAndSettle();

    expect(find.text('Always up for a museum date.'), findsOneWidget);
  });

  testWidgets('opens the other user profile from the tappable app bar title', (
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
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.light,
          home: ConversationThreadScreen(
            currentUser: currentUser,
            conversation: conversation,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Noa').first);
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
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.light,
          home: ConversationThreadScreen(
            currentUser: currentUser,
            conversation: conversation,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('View profile'), findsNothing);
    expect(find.byTooltip('Safety actions'), findsNothing);

    await tester.tap(find.byTooltip('Conversation options'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Safety actions'));
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
  final List<String> sentContents = <String>[];

  UserPresence? presence;
  ApiError? presenceError;
  final List<(String, String?)> presenceRequests = [];
  final List<String> typingConversationIds = [];

  @override
  Future<void> sendHeartbeat({required String userId}) async {}

  @override
  Future<void> sendTyping({
    required String userId,
    required String conversationId,
  }) async {
    typingConversationIds.add(conversationId);
  }

  @override
  Future<UserPresence> getPresence({
    required String userId,
    String? conversationId,
  }) async {
    presenceRequests.add((userId, conversationId));
    if (presenceError case final error?) {
      throw error;
    }
    return presence ??
        const UserPresence(status: PresenceStatus.offline, typing: false);
  }

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
    sentContents.add(content);
    return sentMessage;
  }
}

BoxDecoration _nearestDecoratedBoxDecoration(
  WidgetTester tester,
  Finder descendant,
) {
  return _ancestorDecoratedBoxDecorationWhere(tester, descendant, (_) => true);
}

BoxDecoration _ancestorDecoratedBoxDecorationWhere(
  WidgetTester tester,
  Finder descendant,
  bool Function(BoxDecoration decoration) predicate,
) {
  final element = tester.element(descendant);
  BoxDecoration? decoration;

  element.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    if (widget is DecoratedBox && widget.decoration is BoxDecoration) {
      final candidate = widget.decoration as BoxDecoration;
      if (predicate(candidate)) {
        decoration = candidate;
        return false;
      }
    }

    return true;
  });

  expect(decoration, isNotNull);
  return decoration!;
}
