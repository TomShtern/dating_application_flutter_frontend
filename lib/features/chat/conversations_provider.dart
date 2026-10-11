import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../models/conversation_summary.dart';
import '../../models/user_summary.dart';
import '../../shared/providers/selected_user_guard.dart' as user_guard;

final conversationsProvider = FutureProvider<List<ConversationSummary>>((
  ref,
) async {
  final apiClient = ref.watch(apiClientProvider);
  final currentUser = await user_guard.watchSelectedUser(ref);
  return apiClient.getConversations(userId: currentUser.id);
});

final conversationsControllerProvider = Provider<ConversationsController>((
  ref,
) {
  return ConversationsController(ref);
});

class ConversationsController {
  ConversationsController(this._ref);

  final Ref _ref;

  Future<void> refresh() {
    return _ref.refresh(conversationsProvider.future);
  }

  Future<void> archive(String conversationId) async {
    final currentUser = await user_guard.requireSelectedUser(_ref);
    await _ref
        .read(apiClientProvider)
        .archiveConversation(
          userId: currentUser.id,
          conversationId: conversationId,
        );
    _ref.invalidate(conversationsProvider);
  }

  Future<void> unarchive(String conversationId) async {
    final currentUser = await user_guard.requireSelectedUser(_ref);
    await _ref
        .read(apiClientProvider)
        .unarchiveConversation(
          userId: currentUser.id,
          conversationId: conversationId,
        );
    _ref.invalidate(conversationsProvider);
  }

  /// Removes the chat from the signed-in user's list only. The backend keeps
  /// the messages and shows the chat again when either person writes.
  Future<void> delete(String conversationId) async {
    final currentUser = await user_guard.requireSelectedUser(_ref);
    await _ref
        .read(apiClientProvider)
        .deleteConversation(
          userId: currentUser.id,
          conversationId: conversationId,
        );
    _ref.invalidate(conversationsProvider);
  }

  Future<UserSummary> requireSelectedUser() async {
    return user_guard.requireSelectedUser(_ref);
  }
}
