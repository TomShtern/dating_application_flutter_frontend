import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../models/matches_response.dart';
import '../../models/user_summary.dart';
import '../../shared/providers/selected_user_guard.dart' as user_guard;

final matchesProvider = FutureProvider<MatchesResponse>((ref) async {
  final currentUser = await user_guard.requireSelectedUser(ref);
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
    return user_guard.requireSelectedUser(_ref);
  }
}
