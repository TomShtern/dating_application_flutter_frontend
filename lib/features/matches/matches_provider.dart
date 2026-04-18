import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../api/api_error.dart';
import '../../models/matches_response.dart';
import '../../models/user_summary.dart';
import '../auth/selected_user_provider.dart';

final matchesProvider = FutureProvider<MatchesResponse>((ref) async {
  final currentUser = await ref.watch(selectedUserProvider.future);
  if (currentUser == null) {
    throw const ApiError(message: 'Please choose a dev user first.');
  }

  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getMatches(userId: currentUser.id);
});

final matchesControllerProvider = Provider<MatchesController>((ref) {
  return MatchesController(ref);
});

class MatchesController {
  MatchesController(this._ref);

  final Ref _ref;

  void refresh() {
    _ref.invalidate(matchesProvider);
  }

  Future<UserSummary> requireSelectedUser() async {
    final currentUser = await _ref.read(selectedUserProvider.future);
    if (currentUser == null) {
      throw const ApiError(message: 'Please choose a dev user first.');
    }

    return currentUser;
  }
}
