import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../models/pending_liker.dart';
import '../../shared/providers/selected_user_guard.dart' as user_guard;

final pendingLikersProvider = FutureProvider<List<PendingLiker>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final currentUser = await user_guard.watchSelectedUser(ref);
  return apiClient.getPendingLikers(userId: currentUser.id);
});

final pendingLikersControllerProvider = Provider<PendingLikersController>((
  ref,
) {
  return PendingLikersController(ref);
});

class PendingLikersController {
  PendingLikersController(this._ref);

  final Ref _ref;

  Future<void> refresh() {
    return _ref.refresh(pendingLikersProvider.future);
  }
}
