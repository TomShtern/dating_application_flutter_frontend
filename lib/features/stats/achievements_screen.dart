import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/achievement_summary.dart';
import '../../models/user_summary.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../theme/app_theme.dart';
import 'achievement_detail_sheet.dart';
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
                if (achievements.isNotEmpty) ...[
                  _AchievementsOverviewCard(
                    currentUserName: currentUser.name,
                    unlockedCount: unlockedCount,
                    totalCount: achievements.length,
                    inProgressCount: inProgressCount,
                  ),
                  SizedBox(height: AppTheme.sectionSpacing(compact: true)),
                ],
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

class _AchievementsOverviewCard extends StatelessWidget {
  const _AchievementsOverviewCard({
    required this.currentUserName,
    required this.unlockedCount,
    required this.totalCount,
    required this.inProgressCount,
  });

  final String currentUserName;
  final int unlockedCount;
  final int totalCount;
  final int inProgressCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = totalCount == 0 ? 0.0 : unlockedCount / totalCount;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$currentUserName's achievement progress",
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Overall progress',
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$unlockedCount of $totalCount unlocked',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        inProgressCount == 0
                            ? 'Everything here is unlocked.'
                            : '$inProgressCount still building',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient(context),
                    borderRadius: const BorderRadius.all(Radius.circular(18)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _AchievementSummaryPill(
                  icon: Icons.emoji_events_rounded,
                  label: '$unlockedCount unlocked',
                ),
                _AchievementSummaryPill(
                  icon: Icons.flag_outlined,
                  label: inProgressCount == 1
                      ? '1 in progress'
                      : '$inProgressCount in progress',
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text('Progress', style: theme.textTheme.labelLarge),
                const Spacer(),
                Text(
                  '${(progress * 100).round()}% complete',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(999)),
              child: LinearProgressIndicator(
                key: const ValueKey('achievements-overview-progress'),
                value: progress,
                minHeight: 10,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
          ],
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppTheme.panelRadius,
        onTap: () => showAchievementDetailSheet(
          context: context,
          achievement: achievement,
        ),
        child: Ink(
          decoration: AppTheme.surfaceDecoration(
            context,
            gradient: unlocked
                ? LinearGradient(
                    colors: [
                      colorScheme.primaryContainer.withValues(alpha: 0.96),
                      colorScheme.tertiaryContainer.withValues(alpha: 0.92),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: unlocked ? null : colorScheme.surface.withValues(alpha: 0.9),
            prominent: unlocked,
          ),
          child: Padding(
            padding: AppTheme.sectionPadding(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: unlocked
                        ? AppTheme.accentGradient(context)
                        : null,
                    color: unlocked
                        ? null
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.all(Radius.circular(18)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(11),
                    child: Icon(
                      unlocked
                          ? Icons.workspace_premium_rounded
                          : Icons.flag_outlined,
                      color: unlocked
                          ? colorScheme.onPrimary
                          : colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
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
                      if (achievement.progress case final progress?) ...[
                        const SizedBox(height: 8),
                        Text(
                          progress,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
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
          ),
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
        gradient: unlocked ? AppTheme.accentGradient(context) : null,
        color: unlocked ? null : colorScheme.surfaceContainerHighest,
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

class _AchievementSummaryPill extends StatelessWidget {
  const _AchievementSummaryPill({required this.icon, required this.label});

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
