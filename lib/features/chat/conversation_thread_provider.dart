import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../api/api_error.dart';
import '../../models/message_dto.dart';
import '../../models/user_summary.dart';
import '../../shared/providers/selected_user_guard.dart' as user_guard;
import 'conversations_provider.dart';

final conversationThreadProvider =
    FutureProvider.family<List<MessageDto>, String>((
      ref,
      conversationId,
    ) async {
      final apiClient = ref.watch(apiClientProvider);
      final currentUser = await user_guard.watchSelectedUser(ref);
      return apiClient.getMessages(
        conversationId: conversationId,
        userId: currentUser.id,
      );
    });

final conversationThreadControllerProvider =
    Provider.family<ConversationThreadController, String>((
      ref,
      conversationId,
    ) {
      return ConversationThreadController(ref, conversationId);
    });

class ConversationThreadController {
  ConversationThreadController(this._ref, this._conversationId);

  final Ref _ref;
  final String _conversationId;

  Future<void> refresh() {
    return _ref.refresh(conversationThreadProvider(_conversationId).future);
  }

  Future<MessageDto> sendMessage(String content) async {
    final currentUser = await _requireSelectedUser();
    final trimmedContent = content.trim();

    if (trimmedContent.isEmpty) {
      throw const ApiError(message: 'Please enter a message before sending.');
    }

    final apiClient = _ref.read(apiClientProvider);
    final message = await apiClient.sendMessage(
      conversationId: _conversationId,
      userId: currentUser.id,
      content: trimmedContent,
    );

    _ref.invalidate(conversationThreadProvider(_conversationId));
    _ref.invalidate(conversationsProvider);
    return message;
  }

  Future<UserSummary> _requireSelectedUser() async {
    return user_guard.requireSelectedUser(_ref);
  }
}
