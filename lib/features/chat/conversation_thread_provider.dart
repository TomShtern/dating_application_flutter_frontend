import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../api/api_error.dart';
import '../../models/message_dto.dart';
import '../../models/user_summary.dart';
import '../auth/selected_user_provider.dart';
import 'conversations_provider.dart';

final conversationThreadProvider =
    FutureProvider.family<List<MessageDto>, String>((
      ref,
      conversationId,
    ) async {
      final currentUser = await ref.watch(selectedUserProvider.future);
      if (currentUser == null) {
        throw const ApiError(message: 'Please choose a dev user first.');
      }

      final apiClient = ref.watch(apiClientProvider);
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

  void refresh() {
    _ref.invalidate(conversationThreadProvider(_conversationId));
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
    final currentUser = await _ref.read(selectedUserProvider.future);
    if (currentUser == null) {
      throw const ApiError(message: 'Please choose a dev user first.');
    }

    return currentUser;
  }
}
