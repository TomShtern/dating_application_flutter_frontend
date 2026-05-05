import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/api/api_error.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/chat/conversation_thread_provider.dart';
import 'package:flutter_dating_application_1/models/message_dto.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';

void main() {
  test('conversation thread provider loads messages and refreshes after send', () async {
    const currentUser = UserSummary(
      id: '11111111-1111-1111-1111-111111111111',
      name: 'Dana',
      age: 27,
      state: 'ACTIVE',
    );

    final apiClient = _FakeConversationThreadApiClient(
      messageResponses: [
        [
          MessageDto(
            id: 'message-1',
            conversationId:
                '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
            senderId: '22222222-2222-2222-2222-222222222222',
            content: 'Hey Dana',
            sentAt: DateTime.parse('2026-04-18T14:20:00Z'),
          ),
        ],
        [
          MessageDto(
            id: 'message-1',
            conversationId:
                '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
            senderId: '22222222-2222-2222-2222-222222222222',
            content: 'Hey Dana',
            sentAt: DateTime.parse('2026-04-18T14:20:00Z'),
          ),
          MessageDto(
            id: 'message-2',
            conversationId:
                '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
            senderId: currentUser.id,
            content: 'Hey there',
            sentAt: DateTime.parse('2026-04-18T14:21:00Z'),
          ),
        ],
      ],
      sentMessage: MessageDto(
        id: 'message-2',
        conversationId:
            '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
        senderId: currentUser.id,
        content: 'Hey there',
        sentAt: DateTime.parse('2026-04-18T14:21:00Z'),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(apiClient),
        selectedUserProvider.overrideWith((ref) async => currentUser),
      ],
    );
    addTearDown(container.dispose);

    final initial = await container.read(
      conversationThreadProvider(
        '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
      ).future,
    );

    expect(initial.single.content, 'Hey Dana');

    await container
        .read(
          conversationThreadControllerProvider(
            '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
          ),
        )
        .sendMessage('  Hey there  ');

    final refreshed = await container.read(
      conversationThreadProvider(
        '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
      ).future,
    );

    expect(refreshed.last.content, 'Hey there');
    expect(
      apiClient.lastConversationId,
      '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
    );
    expect(apiClient.lastUserId, currentUser.id);
    expect(apiClient.lastSentContent, 'Hey there');
    expect(apiClient.getMessagesCalls, 2);
  });

  test(
    'exposes local sending and failed retry state for device-sent messages',
    () async {
      const conversationId =
          '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222';
      const currentUser = UserSummary(
        id: '11111111-1111-1111-1111-111111111111',
        name: 'Dana',
        age: 27,
        state: 'ACTIVE',
      );

      final firstSend = Completer<MessageDto>();
      final apiClient = _FakeConversationThreadApiClient(
        messageResponses: [
          [
            MessageDto(
              id: 'message-1',
              conversationId: conversationId,
              senderId: '22222222-2222-2222-2222-222222222222',
              content: 'Hey Dana',
              sentAt: DateTime.parse('2026-04-18T14:20:00Z'),
            ),
          ],
          [
            MessageDto(
              id: 'message-1',
              conversationId: conversationId,
              senderId: '22222222-2222-2222-2222-222222222222',
              content: 'Hey Dana',
              sentAt: DateTime.parse('2026-04-18T14:20:00Z'),
            ),
          ],
        ],
        sendResponses: [
          firstSend.future,
          Future.value(
            MessageDto(
              id: 'message-2',
              conversationId: conversationId,
              senderId: currentUser.id,
              content: 'Hey there',
              sentAt: DateTime.parse('2026-04-18T14:21:00Z'),
            ),
          ),
        ],
        sentMessage: MessageDto(
          id: 'message-2',
          conversationId: conversationId,
          senderId: currentUser.id,
          content: 'Hey there',
          sentAt: DateTime.parse('2026-04-18T14:21:00Z'),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          selectedUserProvider.overrideWith((ref) async => currentUser),
        ],
      );
      addTearDown(container.dispose);

      await container.read(conversationThreadProvider(conversationId).future);

      final sendFuture = container
          .read(conversationThreadControllerProvider(conversationId))
          .sendMessage('  Hey there  ');

      final pendingMessages = container.read(
        conversationThreadMessagesProvider(conversationId),
      );
      expect(pendingMessages.requireValue.last.content, 'Hey there');
      expect(
        pendingMessages.requireValue.last.localState,
        MessageLocalState.sending,
      );

      firstSend.completeError(const ApiError(message: 'Network down'));
      await expectLater(sendFuture, throwsA(isA<ApiError>()));

      final failedMessages = container.read(
        conversationThreadMessagesProvider(conversationId),
      );
      final failedMessage = failedMessages.requireValue.last;
      expect(failedMessage.localState, MessageLocalState.failed);

      await container
          .read(conversationThreadControllerProvider(conversationId))
          .retryMessage(failedMessage);

      final retriedMessages = container.read(
        conversationThreadMessagesProvider(conversationId),
      );
      expect(retriedMessages.requireValue.last.content, 'Hey there');
      expect(
        retriedMessages.requireValue.last.localState,
        MessageLocalState.none,
      );
      expect(apiClient.sentContents, ['Hey there', 'Hey there']);
    },
  );
}

class _FakeConversationThreadApiClient extends ApiClient {
  _FakeConversationThreadApiClient({
    required this.messageResponses,
    this.sendResponses = const [],
    required this.sentMessage,
  }) : super(dio: Dio());

  final List<List<MessageDto>> messageResponses;
  final List<Future<MessageDto>> sendResponses;
  final MessageDto sentMessage;
  int getMessagesCalls = 0;
  String? lastConversationId;
  String? lastUserId;
  String? lastSentContent;
  final List<String> sentContents = <String>[];
  int sendCalls = 0;

  @override
  Future<List<MessageDto>> getMessages({
    required String conversationId,
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    lastConversationId = conversationId;
    lastUserId = userId;

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
    lastConversationId = conversationId;
    lastUserId = userId;
    lastSentContent = content;
    sentContents.add(content);
    final index = sendCalls < sendResponses.length ? sendCalls : -1;
    sendCalls++;
    if (index >= 0) {
      return sendResponses[index];
    }
    return sentMessage;
  }
}
