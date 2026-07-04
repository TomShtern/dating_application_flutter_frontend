import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../models/match_quality.dart';
import '../../models/matches_response.dart';
import '../../models/user_summary.dart';
import '../../shared/providers/selected_user_guard.dart' as user_guard;

final matchesProvider = FutureProvider<MatchesResponse>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final currentUser = await user_guard.watchSelectedUser(ref);
  return apiClient.getMatches(userId: currentUser.id);
});

final matchesControllerProvider = Provider<MatchesController>((ref) {
  return MatchesController(ref);
});

final matchQualityProvider = FutureProvider.family
    .autoDispose<MatchQuality, String>((ref, matchId) async {
      final apiClient = ref.watch(apiClientProvider);
      final currentUser = await user_guard.watchSelectedUser(ref);
      return apiClient.getMatchQuality(
        userId: currentUser.id,
        matchId: matchId,
      );
    });

class MatchesController {
  MatchesController(this._ref);

  final Ref _ref;

  Future<void> refresh() {
    return _ref.refresh(matchesProvider.future);
  }

  Future<String> archiveMatch(String matchId) async {
    final currentUser = await user_guard.requireSelectedUser(_ref);
    final message = await _ref
        .read(apiClientProvider)
        .archiveMatch(userId: currentUser.id, matchId: matchId);

    _ref.invalidate(matchesProvider);
    return message;
  }

  Future<UserSummary> requireSelectedUser() async {
    return user_guard.requireSelectedUser(_ref);
  }
}
