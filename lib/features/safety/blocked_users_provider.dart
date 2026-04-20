import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../models/blocked_user_summary.dart';
import '../../shared/providers/selected_user_guard.dart' as user_guard;

final blockedUsersProvider = FutureProvider<List<BlockedUserSummary>>((
  ref,
) async {
  final apiClient = ref.watch(apiClientProvider);
  final currentUser = await user_guard.watchSelectedUser(ref);
  return apiClient.getBlockedUsers(userId: currentUser.id);
});

final blockedUsersControllerProvider = Provider<BlockedUsersController>((ref) {
  return BlockedUsersController(ref);
});

class BlockedUsersController {
  BlockedUsersController(this._ref);

  final Ref _ref;

  Future<String> unblockUser(String targetId) async {
    final currentUser = await user_guard.requireSelectedUser(_ref);
    final apiClient = _ref.read(apiClientProvider);
    final message = await apiClient.unblockUser(
      userId: currentUser.id,
      targetId: targetId,
    );
    _ref.invalidate(blockedUsersProvider);
    return message;
  }

  Future<void> refresh() {
    return _ref.refresh(blockedUsersProvider.future);
  }
}
