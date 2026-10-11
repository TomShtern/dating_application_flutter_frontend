import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../api/api_error.dart';
import '../../models/browse_response.dart';
import '../../models/daily_status.dart';
import '../../models/like_result.dart';
import '../../models/undo_swipe_result.dart';
import '../../models/user_summary.dart';
import '../../shared/providers/selected_user_guard.dart' as user_guard;
import '../auth/selected_user_provider.dart';
import '../chat/conversations_provider.dart';
import '../matches/matches_provider.dart';

final browseProvider = FutureProvider<BrowseResponse>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final currentUser = await user_guard.watchSelectedUser(ref);
  return apiClient.getBrowse(userId: currentUser.id);
});

/// Today's remaining likes, super likes and passes. Decoration only: when it
/// cannot be read the counter is simply not shown.
final dailyStatusProvider = FutureProvider<DailyStatus>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final currentUser = await user_guard.watchSelectedUser(ref);
  return apiClient.getDailyStatus(userId: currentUser.id);
}, retry: (_, _) => null);

/// Which swipes the backend has refused for today (429 `RATE_LIMITED`), with
/// the backend's own message, which names the limit and its reset time.
class SwipeLimits {
  const SwipeLimits({this.likeMessage, this.passMessage, this.superLikeMessage});

  final String? likeMessage;
  final String? passMessage;
  final String? superLikeMessage;

  bool get likeReached => likeMessage != null;
  bool get passReached => passMessage != null;
  bool get superLikeReached => superLikeMessage != null;
}

final swipeLimitProvider = NotifierProvider<SwipeLimitNotifier, SwipeLimits>(
  SwipeLimitNotifier.new,
);

/// A reached limit is kept until the user refreshes Discover or a different
/// user signs in. If the limit is still in force the next swipe is refused
/// again and the flag comes back.
class SwipeLimitNotifier extends Notifier<SwipeLimits> {
  @override
  SwipeLimits build() {
    ref.watch(selectedUserProvider.select((user) => user.value?.id));
    return const SwipeLimits();
  }

  void likeLimitReached(String message) {
    state = SwipeLimits(
      likeMessage: message,
      passMessage: state.passMessage,
      superLikeMessage: state.superLikeMessage,
    );
  }

  void passLimitReached(String message) {
    state = SwipeLimits(
      likeMessage: state.likeMessage,
      passMessage: message,
      superLikeMessage: state.superLikeMessage,
    );
  }

  void superLikeLimitReached(String message) {
    state = SwipeLimits(
      likeMessage: state.likeMessage,
      passMessage: state.passMessage,
      superLikeMessage: message,
    );
  }

  void clear() {
    state = const SwipeLimits();
  }
}

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
    final LikeResult result;
    try {
      result = await _apiClient.likeUser(
        userId: currentUser.id,
        targetId: targetId,
      );
    } on ApiError catch (error) {
      if (error.isDailyLimit) {
        _ref.read(swipeLimitProvider.notifier).likeLimitReached(error.message);
      }
      rethrow;
    }
    _ref.invalidate(browseProvider);
    _ref.invalidate(dailyStatusProvider);
    if (result.isMatch) {
      _ref.invalidate(matchesProvider);
      _ref.invalidate(conversationsProvider);
    }
    return result;
  }

  Future<LikeResult> superLikeCandidate(String targetId) async {
    final currentUser = await _requireSelectedUser();
    final LikeResult result;
    try {
      result = await _apiClient.superLikeUser(
        userId: currentUser.id,
        targetId: targetId,
      );
    } on ApiError catch (error) {
      if (error.isDailyLimit) {
        _ref
            .read(swipeLimitProvider.notifier)
            .superLikeLimitReached(error.message);
      }
      rethrow;
    }
    _ref.invalidate(browseProvider);
    _ref.invalidate(dailyStatusProvider);
    if (result.isMatch) {
      _ref.invalidate(matchesProvider);
      _ref.invalidate(conversationsProvider);
    }
    return result;
  }

  Future<String> passCandidate(String targetId) async {
    final currentUser = await _requireSelectedUser();
    final String message;
    try {
      message = await _apiClient.passUser(
        userId: currentUser.id,
        targetId: targetId,
      );
    } on ApiError catch (error) {
      if (error.isDailyLimit) {
        _ref.read(swipeLimitProvider.notifier).passLimitReached(error.message);
      }
      rethrow;
    }
    _ref.invalidate(browseProvider);
    _ref.invalidate(dailyStatusProvider);
    return message;
  }

  Future<UndoSwipeResult> undoLastSwipe() async {
    final currentUser = await _requireSelectedUser();
    final result = await _apiClient.undoLastSwipe(userId: currentUser.id);
    _ref.invalidate(browseProvider);
    _ref.invalidate(dailyStatusProvider);
    if (result.matchDeleted) {
      _ref.invalidate(matchesProvider);
      _ref.invalidate(conversationsProvider);
    }
    return result;
  }

  Future<void> refresh() {
    _ref.read(swipeLimitProvider.notifier).clear();
    _ref.invalidate(dailyStatusProvider);
    return _ref.refresh(browseProvider.future);
  }

  Future<UserSummary> _requireSelectedUser() async {
    return user_guard.requireSelectedUser(_ref);
  }
}
