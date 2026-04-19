import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/api/api_error.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/chat/conversations_provider.dart';
import 'package:flutter_dating_application_1/models/conversation_summary.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';

void main() {
  const currentUser = UserSummary(
    id: '11111111-1111-1111-1111-111111111111',
    name: 'Dana',
    age: 27,
    state: 'ACTIVE',
  );

  test(
    'loads conversations for the selected user and refreshes them',
    () async {
      final apiClient = _FakeConversationsApiClient([
        [
          ConversationSummary(
            id: 'conversation-1',
            otherUserId: '22222222-2222-2222-2222-222222222222',
            otherUserName: 'Noa',
            messageCount: 3,
            lastMessageAt: DateTime.parse('2026-04-19T09:00:00Z'),
          ),
        ],
        [
          ConversationSummary(
            id: 'conversation-2',
            otherUserId: '33333333-3333-3333-3333-333333333333',
            otherUserName: 'Maya',
            messageCount: 5,
            lastMessageAt: DateTime.parse('2026-04-19T10:00:00Z'),
          ),
        ],
      ]);

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          selectedUserProvider.overrideWith((ref) async => currentUser),
        ],
      );
      addTearDown(container.dispose);

      final initial = await container.read(conversationsProvider.future);
      expect(initial.single.otherUserName, 'Noa');

      container.read(conversationsControllerProvider).refresh();
      final refreshed = await container.read(conversationsProvider.future);

      expect(refreshed.single.otherUserName, 'Maya');
      expect(apiClient.calls, 2);
      expect(apiClient.lastUserId, currentUser.id);
    },
  );

  test('requires a selected user before controlling conversations', () async {
    final container = ProviderContainer(
      overrides: [
        selectedUserProvider.overrideWithValue(
          const AsyncData<UserSummary?>(null),
        ),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(conversationsControllerProvider).requireSelectedUser(),
      throwsA(
        isA<ApiError>().having(
          (error) => error.message,
          'message',
          'Please choose a dev user first.',
        ),
      ),
    );
  });
}

class _FakeConversationsApiClient extends ApiClient {
  _FakeConversationsApiClient(this.responses) : super(dio: Dio());

  final List<List<ConversationSummary>> responses;
  int calls = 0;
  String? lastUserId;

  @override
  Future<List<ConversationSummary>> getConversations({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    lastUserId = userId;
    final index = calls < responses.length ? calls : responses.length - 1;
    calls++;
    return responses[index];
  }
}
