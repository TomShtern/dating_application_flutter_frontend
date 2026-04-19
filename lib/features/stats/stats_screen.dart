import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/user_summary.dart';
import '../../shared/widgets/app_async_state.dart';
import 'achievements_screen.dart';
import 'stats_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key, required this.currentUser});

  final UserSummary currentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsState = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats'),
        actions: [
          IconButton(
            tooltip: 'View achievements',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) =>
                      AchievementsScreen(currentUser: currentUser),
                ),
              );
            },
            icon: const Icon(Icons.workspace_premium_outlined),
          ),
          IconButton(
            tooltip: 'Refresh stats',
            onPressed: () => ref.invalidate(statsProvider),
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
                'Progress snapshot for ${currentUser.name}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: statsState.when(
                  data: (stats) {
                    if (stats.items.isEmpty) {
                      return const AppAsyncState.empty(
                        message: 'No stats are available for this user yet.',
                      );
                    }

                    return ListView.separated(
                      itemCount: stats.items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = stats.items[index];
                        return Card(
                          child: ListTile(
                            title: Text(item.label),
                            subtitle: Text(item.value),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const AppAsyncState.loading(message: 'Loading stats…'),
                  error: (error, stackTrace) => AppAsyncState.error(
                    message: error is ApiError
                        ? error.message
                        : 'Unable to load stats right now.',
                    onRetry: () => ref.invalidate(statsProvider),
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
