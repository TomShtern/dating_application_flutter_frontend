import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/user_summary.dart';
import '../../models/user_stats.dart';
import '../../shared/formatting/display_text.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../theme/app_theme.dart';
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
        child: statsState.when(
          data: (stats) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppTheme.screenPadding(),
            children: [
              _StatsOverviewCard(currentUser: currentUser, stats: stats),
              SizedBox(height: AppTheme.sectionSpacing(compact: true)),
              if (stats.items.isEmpty)
                const AppAsyncState.empty(
                  message: 'No stats are available for this user yet.',
                )
              else ...[
                for (var index = 0; index < stats.items.length; index++) ...[
                  _StatSummaryCard(item: stats.items[index]),
                  if (index != stats.items.length - 1)
                    SizedBox(height: AppTheme.listSpacing()),
                ],
              ],
            ],
          ),
          loading: () => Padding(
            padding: AppTheme.screenPadding(),
            child: const AppAsyncState.loading(message: 'Loading stats…'),
          ),
          error: (error, stackTrace) => Padding(
            padding: AppTheme.screenPadding(),
            child: AppAsyncState.error(
              message: error is ApiError
                  ? error.message
                  : 'Unable to load stats right now.',
              onRetry: () => ref.invalidate(statsProvider),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatSummaryCard extends StatelessWidget {
  const _StatSummaryCard({required this.item});

  final UserStatItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: colorScheme.surface.withValues(alpha: 0.9),
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: const BorderRadius.all(Radius.circular(20)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  _iconForStatLabel(item.label),
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Text(item.value, style: theme.textTheme.headlineSmall),
                  if (_statDescriptor(item.label) case final descriptor?) ...[
                    const SizedBox(height: 6),
                    Text(descriptor, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsOverviewCard extends StatelessWidget {
  const _StatsOverviewCard({required this.currentUser, required this.stats});

  final UserSummary currentUser;
  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        gradient: AppTheme.heroGradient(context),
        prominent: true,
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(compact: true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.72),
                    borderRadius: const BorderRadius.all(Radius.circular(18)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.query_stats_rounded,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Momentum for ${currentUser.name}',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatsSummaryPill(
                  icon: Icons.bar_chart_rounded,
                  label: '${stats.items.length} highlights',
                ),
                _StatsSummaryPill(
                  icon: Icons.verified_user_outlined,
                  label: '${formatDisplayLabel(currentUser.state)} profile',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsSummaryPill extends StatelessWidget {
  const _StatsSummaryPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppTheme.glassDecoration(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}

IconData _iconForStatLabel(String label) {
  final normalized = label.toLowerCase();

  if (normalized.contains('match')) {
    return Icons.favorite_rounded;
  }
  if (normalized.contains('like')) {
    return Icons.thumb_up_alt_rounded;
  }
  if (normalized.contains('message') || normalized.contains('chat')) {
    return Icons.chat_bubble_rounded;
  }
  if (normalized.contains('photo') || normalized.contains('profile')) {
    return Icons.person_outline_rounded;
  }

  return Icons.bar_chart_rounded;
}

String? _statDescriptor(String label) {
  final normalized = label.toLowerCase();

  if (normalized.contains('match')) {
    return 'Connections that turned mutual.';
  }
  if (normalized.contains('like')) {
    return 'Activity from your recent swipes.';
  }
  if (normalized.contains('message') || normalized.contains('chat')) {
    return 'Conversation momentum from recent replies.';
  }
  if (normalized.contains('photo') || normalized.contains('profile')) {
    return 'How much attention your profile is drawing.';
  }

  return null;
}
