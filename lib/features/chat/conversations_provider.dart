import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../api/api_error.dart';
import '../../models/conversation_summary.dart';
import '../../models/user_summary.dart';
import '../auth/selected_user_provider.dart';

final conversationsProvider = FutureProvider<List<ConversationSummary>>((
  ref,
) async {
  final currentUser = await ref.watch(selectedUserProvider.future);
  if (currentUser == null) {
    throw const ApiError(message: 'Please choose a dev user first.');
  }

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
    final currentUser = await _ref.read(selectedUserProvider.future);
    if (currentUser == null) {
      throw const ApiError(message: 'Please choose a dev user first.');
    }

    return currentUser;
  }
}
