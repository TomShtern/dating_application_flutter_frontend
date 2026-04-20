import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../models/achievement_summary.dart';
import '../../models/user_stats.dart';
import '../../shared/providers/selected_user_guard.dart';

final statsProvider = FutureProvider<UserStats>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final currentUser = await watchSelectedUser(ref);
  return apiClient.getStats(userId: currentUser.id);
});

final achievementsProvider = FutureProvider<List<AchievementSummary>>((
  ref,
) async {
  final apiClient = ref.watch(apiClientProvider);
  final currentUser = await watchSelectedUser(ref);
  return apiClient.getAchievements(userId: currentUser.id);
});
