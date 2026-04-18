import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
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

  Future<void> clearSelection() async {
    await _store.clearSelectedUser();
    _ref.invalidate(selectedUserProvider);
  }
}
