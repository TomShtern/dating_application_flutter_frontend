import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/user_summary.dart';
import '../../shared/widgets/app_async_state.dart';
import 'stats_provider.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key, required this.currentUser});

  final UserSummary currentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsState = ref.watch(achievementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        actions: [
          IconButton(
            tooltip: 'Refresh achievements',
            onPressed: () => ref.invalidate(achievementsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Milestones for ${currentUser.name}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: achievementsState.when(
                  data: (achievements) {
                    if (achievements.isEmpty) {
                      return const AppAsyncState.empty(
                        message:
                            'No achievements are available for this user yet.',
                      );
                    }

                    return ListView.separated(
                      itemCount: achievements.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final achievement = achievements[index];
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              achievement.isUnlocked == true
                                  ? Icons.emoji_events_rounded
                                  : Icons.flag_outlined,
                            ),
                            title: Text(achievement.title),
                            subtitle: Text(
                              [
                                achievement.subtitle,
                                achievement.progress,
                                achievement.statusLabel,
                              ].whereType<String>().join(' • '),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const AppAsyncState.loading(
                    message: 'Loading achievements…',
                  ),
                  error: (error, stackTrace) => AppAsyncState.error(
                    message: error is ApiError
                        ? error.message
                        : 'Unable to load achievements right now.',
                    onRetry: () => ref.invalidate(achievementsProvider),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
