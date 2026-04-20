import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../models/profile_update_request.dart';
import '../../models/user_detail.dart';
import '../../shared/providers/selected_user_guard.dart' as user_guard;

final profileProvider = FutureProvider<UserDetail>((ref) async {
  final currentUser = await user_guard.watchSelectedUser(ref);
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getUserDetail(
    userId: currentUser.id,
    actingUserId: currentUser.id,
  );
});

final otherUserProfileProvider = FutureProvider.family<UserDetail, String>((
  ref,
  userId,
) async {
  final currentUser = await user_guard.watchSelectedUser(ref);
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getUserDetail(userId: userId, actingUserId: currentUser.id);
});

final profileControllerProvider = Provider<ProfileController>((ref) {
  return ProfileController(ref);
});

class ProfileController {
  ProfileController(this._ref);

  final Ref _ref;

  Future<void> updateProfile(ProfileUpdateRequest request) async {
    final currentUser = await user_guard.requireSelectedUser(_ref);
    final apiClient = _ref.read(apiClientProvider);
    await apiClient.updateProfile(userId: currentUser.id, request: request);

    _ref.invalidate(profileProvider);
    _ref.invalidate(otherUserProfileProvider(currentUser.id));
  }

  void refreshCurrentUserProfile() {
    _ref.invalidate(profileProvider);
  }

  void refreshOtherUserProfile(String userId) {
    _ref.invalidate(otherUserProfileProvider(userId));
  }
}
