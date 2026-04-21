import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/achievement_summary.dart';
import '../../models/user_summary.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/section_intro_card.dart';
import '../../shared/widgets/shell_hero.dart';
import '../../theme/app_theme.dart';
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
        child: achievementsState.when(
          data: (achievements) {
            final unlockedCount = achievements
                .where((achievement) => achievement.isUnlocked == true)
                .length;
            final inProgressCount = achievements
                .where((achievement) => achievement.isUnlocked == false)
                .length;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppTheme.screenPadding(),
              children: [
                ShellHero(
                  eyebrowLabel: 'Milestone tracker',
                  eyebrowIcon: Icons.workspace_premium_outlined,
                  title: 'Achievement progress for ${currentUser.name}',
                  description:
                      'A compact readout of unlocked wins and the milestones that are still building momentum.',
                  badges: [
                    ShellHeroPill(
                      icon: Icons.emoji_events_rounded,
                      label: '$unlockedCount unlocked',
                    ),
                    ShellHeroPill(
                      icon: Icons.flag_outlined,
                      label: '$inProgressCount in progress',
                    ),
                    ShellHeroPill(
                      icon: Icons.checklist_rounded,
                      label: '${achievements.length} total',
                    ),
                  ],
                ),
                SizedBox(height: AppTheme.sectionSpacing()),
                const SectionIntroCard(
                  icon: Icons.celebration_outlined,
                  title: 'Milestones worth checking',
                  description:
                      'Unlocked achievements are ready to celebrate, while in-progress items show where the next bit of momentum is coming from.',
                ),
                SizedBox(height: AppTheme.sectionSpacing()),
                if (achievements.isEmpty)
                  const AppAsyncState.empty(
                    message: 'No achievements are available for this user yet.',
                  )
                else ...[
                  for (var index = 0; index < achievements.length; index++) ...[
                    _AchievementCard(achievement: achievements[index]),
                    if (index != achievements.length - 1)
                      SizedBox(height: AppTheme.listSpacing()),
                  ],
                ],
              ],
            );
          },
          loading: () => Padding(
            padding: AppTheme.screenPadding(),
            child: const AppAsyncState.loading(
              message: 'Loading achievements…',
            ),
          ),
          error: (error, stackTrace) => Padding(
            padding: AppTheme.screenPadding(),
            child: AppAsyncState.error(
              message: error is ApiError
                  ? error.message
                  : 'Unable to load achievements right now.',
              onRetry: () => ref.invalidate(achievementsProvider),
            ),
          ),
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});

  final AchievementSummary achievement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final unlocked = achievement.isUnlocked == true;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: (unlocked ? colorScheme.primaryContainer : colorScheme.surface)
            .withValues(alpha: unlocked ? 0.48 : 0.9),
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: unlocked
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      unlocked
                          ? Icons.emoji_events_rounded
                          : Icons.flag_outlined,
                      color: unlocked
                          ? colorScheme.onPrimary
                          : colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement.title,
                        style: theme.textTheme.titleMedium,
                      ),
                      if (achievement.subtitle case final subtitle?) ...[
                        const SizedBox(height: 6),
                        Text(subtitle, style: theme.textTheme.bodyMedium),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _AchievementStatusBadge(
                  label: achievement.statusLabel,
                  unlocked: unlocked,
                ),
              ],
            ),
            if (achievement.progress case final progress?) ...[
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.7),
                  borderRadius: const BorderRadius.all(Radius.circular(18)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Text(progress, style: theme.textTheme.bodyMedium),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AchievementStatusBadge extends StatelessWidget {
  const _AchievementStatusBadge({required this.label, required this.unlocked});

  final String label;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: unlocked
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest,
        borderRadius: AppTheme.chipRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: unlocked ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
