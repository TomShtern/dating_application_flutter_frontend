import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../features/auth/selected_user_provider.dart';
import '../../models/user_summary.dart';

Future<UserSummary> watchSelectedUser(
  Ref ref, {
  String message = 'Please choose a dev user first.',
}) async {
  final currentUser = await ref.watch(selectedUserProvider.future);
  if (currentUser == null) {
    throw ApiError(message: message);
  }

  return currentUser;
}

Future<UserSummary> requireSelectedUser(
  Ref ref, {
  String message = 'Please choose a dev user first.',
}) async {
  final currentUser = await ref.read(selectedUserProvider.future);
  if (currentUser == null) {
    throw ApiError(message: message);
  }

  return currentUser;
}

Future<UserSummary> requireActionableTargetUser(
  Ref ref,
  String targetId, {
  String selfActionMessage =
      'You cannot perform safety actions on your own account.',
}) async {
  final currentUser = await requireSelectedUser(ref);
  if (currentUser.id == targetId) {
    throw ApiError(message: selfActionMessage);
  }

  return currentUser;
}
