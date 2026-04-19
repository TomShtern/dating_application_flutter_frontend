import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../models/user_summary.dart';
import '../../shared/providers/selected_user_guard.dart' as user_guard;
import '../browse/browse_provider.dart';
import '../chat/conversations_provider.dart';
import '../matches/matches_provider.dart';
import '../profile/profile_provider.dart';

final safetyControllerProvider = Provider<SafetyController>((ref) {
  return SafetyController(ref);
});

class SafetyController {
  SafetyController(this._ref);

  final Ref _ref;

  Future<String> blockUser(String targetId) async {
    final currentUser = await _requireActionableTarget(targetId);
    final message = await _ref
        .read(apiClientProvider)
        .blockUser(userId: currentUser.id, targetId: targetId);

    _invalidateRelationshipData(targetId);
    return message;
  }

  Future<String> unblockUser(String targetId) async {
    final currentUser = await _requireActionableTarget(targetId);
    final message = await _ref
        .read(apiClientProvider)
        .unblockUser(userId: currentUser.id, targetId: targetId);

    _invalidateRelationshipData(targetId);
    return message;
  }

  Future<String> reportUser(String targetId) async {
    final currentUser = await _requireActionableTarget(targetId);
    return _ref
        .read(apiClientProvider)
        .reportUser(userId: currentUser.id, targetId: targetId);
  }

  Future<String> unmatchUser(String targetId) async {
    final currentUser = await _requireActionableTarget(targetId);
    final message = await _ref
        .read(apiClientProvider)
        .unmatchUser(userId: currentUser.id, targetId: targetId);

    _invalidateRelationshipData(targetId);
    return message;
  }

  void _invalidateRelationshipData(String targetId) {
    _ref.invalidate(browseProvider);
    _ref.invalidate(matchesProvider);
    _ref.invalidate(conversationsProvider);
    _ref.invalidate(otherUserProfileProvider(targetId));
  }

  Future<UserSummary> _requireActionableTarget(String targetId) async {
    return user_guard.requireActionableTargetUser(_ref, targetId);
  }
}
