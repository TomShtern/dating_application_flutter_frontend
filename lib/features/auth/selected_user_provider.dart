import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../api/api_error.dart';
import '../../shared/persistence/shared_preferences_provider.dart';
import '../../models/user_summary.dart';
import 'selected_user_store.dart';

final selectedUserStoreProvider = Provider<SelectedUserStore>((ref) {
  final preferences = ref.watch(sharedPreferencesProvider);
  return SelectedUserStore(preferences);
});

final selectedUserProvider = FutureProvider<UserSummary?>((ref) async {
  final store = ref.watch(selectedUserStoreProvider);
  return store.readSelectedUser();
});

final availableUsersProvider = FutureProvider<List<UserSummary>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getUsers();
});

final selectUserControllerProvider = Provider<SelectUserController>((ref) {
  final store = ref.watch(selectedUserStoreProvider);
  return SelectUserController(ref, store);
});

class SelectUserController {
  SelectUserController(this._ref, this._store);

  final Ref _ref;
  final SelectedUserStore _store;

  Future<void> selectUser(UserSummary user) async {
    await _store.saveSelectedUser(user);
    _ref.invalidate(selectedUserProvider);
  }

  /// Re-reads the signed-in user's account state from the backend, so a
  /// state that changed mid-session (for example to `UNDER_REVIEW`) reaches
  /// the UI. Best effort: a failed read leaves the stored user untouched.
  Future<void> refreshAccountState() async {
    final current = await _ref.read(selectedUserProvider.future);
    if (current == null) {
      return;
    }
    try {
      final detail = await _ref
          .read(apiClientProvider)
          .getUserDetail(userId: current.id);
      if (detail.state == current.state) {
        return;
      }
      await selectUser(
        UserSummary(
          id: current.id,
          name: current.name,
          age: current.age,
          state: detail.state,
        ),
      );
    } on ApiError {
      // Keep what we have.
    }
  }

  /// Hides the signed-in user's profile from discovery. Matches and chats
  /// stay. Throws the backend's [ApiError] when the profile is not `ACTIVE`.
  Future<void> pauseProfile() => _setPaused(true);

  /// Makes a paused profile visible again. Throws the backend's [ApiError]
  /// when the profile is not `PAUSED` or is no longer complete.
  Future<void> resumeProfile() => _setPaused(false);

  Future<void> _setPaused(bool paused) async {
    final current = await _ref.read(selectedUserProvider.future);
    if (current == null) {
      return;
    }
    final apiClient = _ref.read(apiClientProvider);
    try {
      final detail = paused
          ? await apiClient.pauseProfile(userId: current.id)
          : await apiClient.resumeProfile(userId: current.id);
      await selectUser(
        UserSummary(
          id: current.id,
          name: current.name,
          age: current.age,
          state: detail.state,
        ),
      );
    } on ApiError catch (error) {
      // The stored state was out of date; show the real one.
      if (error.code == 'PROFILE_NOT_ACTIVE' ||
          error.code == 'PROFILE_NOT_PAUSED') {
        await refreshAccountState();
      }
      rethrow;
    }
  }

  Future<void> clearSelection() async {
    await _store.clearSelectedUser();
    _ref.invalidate(selectedUserProvider);
  }
}
