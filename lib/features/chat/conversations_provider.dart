import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../models/conversation_summary.dart';
import '../../models/user_summary.dart';
import '../../shared/providers/selected_user_guard.dart' as user_guard;

final conversationsProvider = FutureProvider<List<ConversationSummary>>((
  ref,
) async {
  final currentUser = await user_guard.requireSelectedUser(ref);
  final apiClient = ref.watch(apiClientProvider);
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

  void refresh() {
    _ref.invalidate(conversationsProvider);
  }

  Future<UserSummary> requireSelectedUser() async {
    return user_guard.requireSelectedUser(_ref);
  }
}
