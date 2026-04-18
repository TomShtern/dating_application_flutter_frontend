import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../api/api_error.dart';
import '../../models/browse_response.dart';
import '../../models/like_result.dart';
import '../../models/user_summary.dart';
import '../auth/selected_user_provider.dart';

final browseProvider = FutureProvider<BrowseResponse>((ref) async {
  final currentUser = await ref.watch(selectedUserProvider.future);
  if (currentUser == null) {
    throw const ApiError(message: 'Please choose a dev user first.');
  }

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

  void refresh() {
    _ref.invalidate(browseProvider);
  }

  Future<UserSummary> _requireSelectedUser() async {
    final currentUser = await _ref.read(selectedUserProvider.future);
    if (currentUser == null) {
      throw const ApiError(message: 'Please choose a dev user first.');
    }

    return currentUser;
  }
}
