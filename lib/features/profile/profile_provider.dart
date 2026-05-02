import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../models/profile_edit_snapshot.dart';
import '../../models/profile_presentation_context.dart';
import '../../models/profile_update_request.dart';
import '../../models/profile_update_response.dart';
import '../../models/user_detail.dart';
import '../../shared/providers/selected_user_guard.dart' as user_guard;

final profileProvider = FutureProvider<UserDetail>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final currentUser = await user_guard.watchSelectedUser(ref);
  return apiClient.getUserDetail(
    userId: currentUser.id,
    actingUserId: currentUser.id,
  );
});

final otherUserProfileProvider = FutureProvider.family<UserDetail, String>((
  ref,
  userId,
) async {
  final apiClient = ref.watch(apiClientProvider);
  final currentUser = await user_guard.watchSelectedUser(ref);
  return apiClient.getUserDetail(userId: userId, actingUserId: currentUser.id);
});

final profileEditSnapshotProvider = FutureProvider<ProfileEditSnapshot>((
  ref,
) async {
  final apiClient = ref.watch(apiClientProvider);
  final currentUser = await user_guard.watchSelectedUser(ref);
  return apiClient.getProfileEditSnapshot(userId: currentUser.id);
});

final presentationContextProvider =
    FutureProvider.family<ProfilePresentationContext, String>((
      ref,
      targetUserId,
    ) async {
      final apiClient = ref.watch(apiClientProvider);
      final currentUser = await user_guard.watchSelectedUser(ref);
      return apiClient.getProfilePresentationContext(
        viewerUserId: currentUser.id,
        targetUserId: targetUserId,
      );
    });

final profileControllerProvider = Provider<ProfileController>((ref) {
  return ProfileController(ref);
});

class ProfileController {
  ProfileController(this._ref);

  final Ref _ref;

  Future<ProfileUpdateResponse> updateProfile(
    ProfileUpdateRequest request,
  ) async {
    final currentUser = await user_guard.requireSelectedUser(_ref);
    final apiClient = _ref.read(apiClientProvider);
    final response = await apiClient.updateProfile(
      userId: currentUser.id,
      request: request,
    );

    _ref.invalidate(profileProvider);
    _ref.invalidate(profileEditSnapshotProvider);
    _ref.invalidate(otherUserProfileProvider(currentUser.id));

    return response;
  }

  void refreshCurrentUserProfile() {
    _ref.invalidate(profileProvider);
    _ref.invalidate(profileEditSnapshotProvider);
  }

  void refreshOtherUserProfile(String userId) {
    _ref.invalidate(otherUserProfileProvider(userId));
    _ref.invalidate(presentationContextProvider(userId));
  }
}
