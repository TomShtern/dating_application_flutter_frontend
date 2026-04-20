import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../models/browse_response.dart';
import '../../models/like_result.dart';
import '../../models/undo_swipe_result.dart';
import '../../models/user_summary.dart';
import '../../shared/providers/selected_user_guard.dart' as user_guard;
import '../chat/conversations_provider.dart';
import '../matches/matches_provider.dart';

final browseProvider = FutureProvider<BrowseResponse>((ref) async {
  final currentUser = await user_guard.watchSelectedUser(ref);
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getBrowse(userId: currentUser.id);
});

final browseControllerProvider = Provider<BrowseController>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BrowseController(ref, apiClient);
});

class BrowseController {
  BrowseController(this._ref, this._apiClient);

  final Ref _ref;
  final ApiClient _apiClient;

  Future<LikeResult> likeCandidate(String targetId) async {
    final currentUser = await _requireSelectedUser();
    final result = await _apiClient.likeUser(
      userId: currentUser.id,
      targetId: targetId,
    );
    _ref.invalidate(browseProvider);
    if (result.isMatch) {
      _ref.invalidate(matchesProvider);
      _ref.invalidate(conversationsProvider);
    }
    return result;
  }

  Future<String> passCandidate(String targetId) async {
    final currentUser = await _requireSelectedUser();
    final message = await _apiClient.passUser(
      userId: currentUser.id,
      targetId: targetId,
    );
    _ref.invalidate(browseProvider);
    return message;
  }

  Future<UndoSwipeResult> undoLastSwipe() async {
    final currentUser = await _requireSelectedUser();
    final result = await _apiClient.undoLastSwipe(userId: currentUser.id);
    _ref.invalidate(browseProvider);
    if (result.matchDeleted) {
      _ref.invalidate(matchesProvider);
      _ref.invalidate(conversationsProvider);
    }
    return result;
  }

  void refresh() {
    _ref.invalidate(browseProvider);
  }

  Future<UserSummary> _requireSelectedUser() async {
    return user_guard.requireSelectedUser(_ref);
  }
}
