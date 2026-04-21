import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/user_summary.dart';
import '../../models/user_stats.dart';
import '../../shared/formatting/display_text.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/section_intro_card.dart';
import '../../shared/widgets/shell_hero.dart';
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
              ShellHero(
                eyebrowLabel: 'Progress snapshot',
                eyebrowIcon: Icons.query_stats_rounded,
                title: "${currentUser.name}'s progress at a glance",
                description:
                    'A tidy, read-only view of the account signals the backend is already tracking for this user.',
                badges: [
                  ShellHeroPill(
                    icon: Icons.bar_chart_rounded,
                    label: '${stats.items.length} tracked stats',
                  ),
                  const ShellHeroPill(
                    icon: Icons.visibility_outlined,
                    label: 'Read-only snapshot',
                  ),
                  ShellHeroPill(
                    icon: Icons.verified_user_outlined,
                    label: formatDisplayLabel(currentUser.state),
                  ),
                ],
                footer: FilledButton.tonalIcon(
                  onPressed: () => _openAchievements(context),
                  icon: const Icon(Icons.workspace_premium_outlined),
                  label: const Text('View achievements'),
                ),
              ),
              SizedBox(height: AppTheme.sectionSpacing()),
              const SectionIntroCard(
                icon: Icons.insights_rounded,
                title: 'What these stats show',
                description:
                    'Each card highlights one backend-backed metric so you can scan progress quickly without digging through raw responses.',
              ),
              SizedBox(height: AppTheme.sectionSpacing()),
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

  void _openAchievements(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AchievementsScreen(currentUser: currentUser),
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
                  const SizedBox(height: 8),
                  Text(
                    'Latest backend snapshot',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
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
