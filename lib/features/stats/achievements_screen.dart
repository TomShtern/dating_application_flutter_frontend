import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/achievement_summary.dart';
import '../../models/user_summary.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/app_group_label.dart';
import '../../shared/widgets/app_route_header.dart';
import '../../theme/app_theme.dart';
import 'achievement_detail_sheet.dart';
import 'stats_provider.dart';

const _achievementViolet = Color(0xFF7C4DFF);
const _achievementPeriwinkle = Color(0xFF5B6EE1);
const _achievementAmber = Color(0xFFD98914);
const _achievementSlate = Color(0xFF596579);

double? _parseAchievementProgressValue(String? progress) {
  if (progress == null) {
    return null;
  }

  final normalized = progress.trim();
  final slashMatch = RegExp(
    r'^(\d+(?:\.\d+)?)\s*/\s*(\d+(?:\.\d+)?)$',
  ).firstMatch(normalized);
  if (slashMatch != null) {
    final numerator = double.tryParse(slashMatch.group(1) ?? '');
    final denominator = double.tryParse(slashMatch.group(2) ?? '');
    if (numerator != null && denominator != null && denominator > 0) {
      return (numerator / denominator).clamp(0.0, 1.0).toDouble();
    }
  }

  final percentMatch = RegExp(r'^(\d+(?:\.\d+)?)%$').firstMatch(normalized);
  if (percentMatch != null) {
    final percentage = double.tryParse(percentMatch.group(1) ?? '');
    if (percentage != null) {
      return (percentage / 100.0).clamp(0.0, 1.0).toDouble();
    }
  }

  return null;
}

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key, required this.currentUser});

  final UserSummary currentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsState = ref.watch(achievementsProvider);

    return Scaffold(
      body: SafeArea(
        child: achievementsState.when(
          data: (achievements) {
            final unlockedCount = achievements
                .where((achievement) => achievement.isUnlocked == true)
                .length;
            final inProgressCount = achievements
                .where((achievement) => achievement.isUnlocked == false)
                .length;
            final unknownCount = achievements
                .where((achievement) => achievement.isUnlocked == null)
                .length;
            final unlocked = achievements
                .where((achievement) => achievement.isUnlocked == true)
                .toList();
            final pending = achievements
                .where((achievement) => achievement.isUnlocked != true)
                .toList();
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppTheme.pagePadding,
                8,
                AppTheme.pagePadding,
                AppTheme.pagePadding,
              ),
              children: [
                AppRouteHeader(
                  title: 'Achievements',
                  trailing: IconButton(
                    tooltip: 'Refresh achievements',
                    onPressed: () => ref.invalidate(achievementsProvider),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                if (achievements.isEmpty)
                  AppAsyncState.empty(
                    message:
                        'Achievements will appear here as this profile unlocks milestones.',
                    onRefresh: () => ref.invalidate(achievementsProvider),
                  )
                else ...[
                  _AchievementsOverviewCard(
                    currentUserName: currentUser.name,
                    unlockedCount: unlockedCount,
                    totalCount: achievements.length,
                    inProgressCount: inProgressCount,
                    unknownCount: unknownCount,
                  ),
                  SizedBox(height: AppTheme.sectionSpacing()),
                  if (unlocked.isNotEmpty) ...[
                    AppGroupLabel(
                      title: 'Unlocked',
                      accentColor: _achievementAmber,
                      countText: '$unlockedCount',
                    ),
                    SizedBox(height: AppTheme.listSpacing()),
                    for (var index = 0; index < unlocked.length; index++) ...[
                      _AchievementCard(achievement: unlocked[index]),
                      if (index != unlocked.length - 1)
                        SizedBox(height: AppTheme.listSpacing()),
                    ],
                  ],
                  if (pending.isNotEmpty) ...[
                    if (unlocked.isNotEmpty)
                      SizedBox(height: AppTheme.sectionSpacing()),
                    AppGroupLabel(
                      title: 'Still building',
                      accentColor: _achievementViolet,
                      countText: '${pending.length}',
                    ),
                    SizedBox(height: AppTheme.listSpacing()),
                    for (var index = 0; index < pending.length; index++) ...[
                      _AchievementCard(achievement: pending[index]),
                      if (index != pending.length - 1)
                        SizedBox(height: AppTheme.listSpacing()),
                    ],
                  ],
                ],
              ],
            );
          },
          loading: () => Padding(
            padding: AppTheme.screenPadding(),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppRouteHeader(title: 'Achievements'),
                SizedBox(height: 16),
                Expanded(
                  child: AppAsyncState.loading(
                    message: 'Loading achievements…',
                  ),
                ),
              ],
            ),
          ),
          error: (error, stackTrace) => Padding(
            padding: AppTheme.screenPadding(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppRouteHeader(title: 'Achievements'),
                const SizedBox(height: 16),
                Expanded(
                  child: AppAsyncState.error(
                    message: error is ApiError
                        ? error.message
                        : 'Unable to load achievements right now.',
                    onRetry: () => ref.invalidate(achievementsProvider),
                  ),
                ),
              ],
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
    required this.unknownCount,
  });

  final String currentUserName;
  final int unlockedCount;
  final int totalCount;
  final int inProgressCount;
  final int unknownCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final progress = totalCount == 0 ? 0.0 : unlockedCount / totalCount;
    final titleColor = isDark
        ? const Color(0xFFF0E7FF)
        : const Color(0xFF3F2B76);
    final countColor = isDark
        ? const Color(0xFFF8F1FF)
        : const Color(0xFF4C2F88);
    final subtitleColor = isDark
        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.82)
        : const Color(0xFF6E607F);
    final progressColor = isDark
        ? const Color(0xFFF5C56C)
        : const Color(0xFF9A6500);
    final unlockedPillBackground = isDark
        ? AppTheme.activeColor(context).withValues(alpha: 0.22)
        : const Color(0xFFDDF8E7);
    final unlockedPillForeground = isDark
        ? AppTheme.activeColor(context)
        : const Color(0xFF167442);
    final progressPillBackground = _achievementPeriwinkle.withValues(
      alpha: isDark ? 0.22 : 0.12,
    );
    final progressPillForeground = isDark
        ? const Color(0xFFC5CCFF)
        : _achievementPeriwinkle;
    final pendingPillBackground = _achievementSlate.withValues(
      alpha: isDark ? 0.24 : 0.10,
    );
    final pendingPillForeground = isDark
        ? const Color(0xFFC0C8D2)
        : _achievementSlate;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF2E2348), Color(0xFF2D3358), Color(0xFF4A3A28)]
              : const [Color(0xFFE8DFF7), Color(0xFFDDE4F7), Color(0xFFF5E3C8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        prominent: true,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 15, 15, 14),
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
                        'Milestones for $currentUserName',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.workspace_premium_outlined,
                            size: 12,
                            color: subtitleColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Latest achievement snapshot',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: subtitleColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TweenAnimationBuilder<int>(
                            tween: IntTween(begin: 0, end: unlockedCount),
                            duration: const Duration(milliseconds: 620),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) => Text(
                              '$value',
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: countColor,
                                height: 0.95,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              unlockedCount == 1
                                  ? 'milestone unlocked'
                                  : 'milestones unlocked',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: titleColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                DecoratedBox(
                  decoration: AppTheme.glassDecoration(
                    context,
                  ).copyWith(borderRadius: AppTheme.cardRadius),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: isDark
                          ? const Color(0xFFF5C56C)
                          : const Color(0xFFC47A00),
                      size: 30,
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
                  icon: Icons.check_circle_rounded,
                  label: '$unlockedCount unlocked',
                  backgroundColor: unlockedPillBackground,
                  foregroundColor: unlockedPillForeground,
                ),
                _AchievementSummaryPill(
                  icon: Icons.timelapse_rounded,
                  label: inProgressCount == 1
                      ? '1 in progress'
                      : '$inProgressCount in progress',
                  backgroundColor: progressPillBackground,
                  foregroundColor: progressPillForeground,
                ),
                _AchievementSummaryPill(
                  icon: Icons.layers_outlined,
                  label: totalCount == 1 ? '1 tracked' : '$totalCount tracked',
                  backgroundColor: pendingPillBackground,
                  foregroundColor: pendingPillForeground,
                ),
                if (unknownCount > 0)
                  _AchievementSummaryPill(
                    icon: Icons.info_outline_rounded,
                    label: unknownCount == 1
                        ? '1 pending status'
                        : '$unknownCount pending',
                    backgroundColor: pendingPillBackground,
                    foregroundColor: pendingPillForeground,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'Completion',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: titleColor,
                  ),
                ),
                const Spacer(),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: (progress * 100).round()),
                  duration: const Duration(milliseconds: 620),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => Text(
                    '$value% complete',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: progressColor,
                    ),
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
                backgroundColor: Colors.white.withValues(
                  alpha: isDark ? 0.14 : 0.48,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
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
    final progress = achievement.progress;
    final progressValue = _parseAchievementProgressValue(progress);
    final spec = _AchievementVisualSpec.forAchievement(
      context,
      achievement: achievement,
    );

    return Material(
      color: Colors.transparent,
      borderRadius: AppTheme.panelRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showAchievementDetailSheet(
          context: context,
          achievement: achievement,
        ),
        child: Ink(
          decoration: AppTheme.surfaceDecoration(
            context,
            color: spec.surfaceColor,
          ),
          child: Padding(
            padding: AppTheme.sectionPadding(compact: true),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: spec.accentColor.withValues(alpha: 0.86),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _AchievementIconChip(spec: spec),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                achievement.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ],
                        ),
                        if (achievement.subtitle case final subtitle?) ...[
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.35,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _AchievementSignalChip(
                              icon: switch (achievement.isUnlocked) {
                                true => Icons.check_circle_rounded,
                                false => Icons.timelapse_rounded,
                                null => Icons.info_outline_rounded,
                              },
                              label: achievement.statusLabel,
                              backgroundColor: spec.statusBackgroundColor,
                              foregroundColor: spec.statusForegroundColor,
                            ),
                            if (progress != null &&
                                achievement.isUnlocked != true)
                              _AchievementSignalChip(
                                icon: progressValue != null
                                    ? Icons.insights_rounded
                                    : Icons.flag_rounded,
                                label: progress,
                                backgroundColor: spec.progressBackgroundColor,
                                foregroundColor: spec.progressColor,
                              ),
                          ],
                        ),
                        if (achievement.isUnlocked != true &&
                            progressValue != null) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: AppTheme.chipRadius,
                            child: LinearProgressIndicator(
                              value: progressValue,
                              minHeight: 7,
                              backgroundColor: spec.progressTrackColor,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                spec.progressBarColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AchievementSummaryPill extends StatelessWidget {
  const _AchievementSummaryPill({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppTheme.chipRadius,
        border: Border.all(color: foregroundColor.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: foregroundColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: foregroundColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementIconChip extends StatelessWidget {
  const _AchievementIconChip({required this.spec});

  final _AchievementVisualSpec spec;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: spec.iconBackgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
      ),
      child: SizedBox.square(
        dimension: 40,
        child: Icon(spec.icon, color: spec.iconColor, size: 22.4),
      ),
    );
  }
}

class _AchievementSignalChip extends StatelessWidget {
  const _AchievementSignalChip({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppTheme.chipRadius,
        border: Border.all(color: foregroundColor.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: foregroundColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementVisualSpec {
  const _AchievementVisualSpec({
    required this.icon,
    required this.accentColor,
    required this.surfaceColor,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.statusBackgroundColor,
    required this.statusForegroundColor,
    required this.progressBackgroundColor,
    required this.progressColor,
    required this.progressTrackColor,
    required this.progressBarColor,
  });

  final IconData icon;
  final Color accentColor;
  final Color surfaceColor;
  final Color iconBackgroundColor;
  final Color iconColor;
  final Color statusBackgroundColor;
  final Color statusForegroundColor;
  final Color progressBackgroundColor;
  final Color progressColor;
  final Color progressTrackColor;
  final Color progressBarColor;

  static _AchievementVisualSpec forAchievement(
    BuildContext context, {
    required AchievementSummary achievement,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final categoryHint = '${achievement.title} ${achievement.subtitle ?? ''}';
    final categoryColor = _achievementCategoryColor(categoryHint);

    if (achievement.isUnlocked == true) {
      final successColor = AppTheme.activeColor(context);
      return _AchievementVisualSpec(
        icon: Icons.workspace_premium_rounded,
        accentColor: categoryColor,
        surfaceColor: Color.alphaBlend(
          categoryColor.withValues(alpha: isDark ? 0.12 : 0.045),
          Color.alphaBlend(
            _achievementAmber.withValues(alpha: isDark ? 0.14 : 0.05),
            colorScheme.surfaceContainerLow,
          ),
        ),
        iconBackgroundColor: categoryColor.withValues(
          alpha: isDark ? 0.22 : 0.14,
        ),
        iconColor: isDark
            ? Color.alphaBlend(
                Colors.white.withValues(alpha: 0.22),
                categoryColor,
              )
            : categoryColor,
        statusBackgroundColor: successColor.withValues(
          alpha: isDark ? 0.22 : 0.14,
        ),
        statusForegroundColor: successColor,
        progressBackgroundColor: categoryColor.withValues(
          alpha: isDark ? 0.18 : 0.10,
        ),
        progressColor: isDark
            ? Color.alphaBlend(
                Colors.white.withValues(alpha: 0.22),
                categoryColor,
              )
            : categoryColor,
        progressTrackColor: categoryColor.withValues(
          alpha: isDark ? 0.24 : 0.12,
        ),
        progressBarColor: categoryColor,
      );
    }

    if (achievement.isUnlocked == false) {
      return _AchievementVisualSpec(
        icon: Icons.workspace_premium_outlined,
        accentColor: categoryColor,
        surfaceColor: Color.alphaBlend(
          categoryColor.withValues(alpha: isDark ? 0.18 : 0.065),
          colorScheme.surfaceContainerLow,
        ),
        iconBackgroundColor: categoryColor.withValues(
          alpha: isDark ? 0.26 : 0.14,
        ),
        iconColor: isDark
            ? Color.alphaBlend(
                Colors.white.withValues(alpha: 0.22),
                categoryColor,
              )
            : categoryColor,
        statusBackgroundColor: _achievementPeriwinkle.withValues(
          alpha: isDark ? 0.22 : 0.12,
        ),
        statusForegroundColor: isDark
            ? const Color(0xFFC5CCFF)
            : _achievementPeriwinkle,
        progressBackgroundColor: categoryColor.withValues(
          alpha: isDark ? 0.18 : 0.10,
        ),
        progressColor: isDark
            ? Color.alphaBlend(
                Colors.white.withValues(alpha: 0.22),
                categoryColor,
              )
            : categoryColor,
        progressTrackColor: categoryColor.withValues(
          alpha: isDark ? 0.24 : 0.12,
        ),
        progressBarColor: categoryColor,
      );
    }

    return _AchievementVisualSpec(
      icon: Icons.help_outline_rounded,
      accentColor: _achievementSlate,
      surfaceColor: Color.alphaBlend(
        _achievementSlate.withValues(alpha: isDark ? 0.12 : 0.05),
        colorScheme.surfaceContainerLow,
      ),
      iconBackgroundColor: _achievementSlate.withValues(
        alpha: isDark ? 0.22 : 0.14,
      ),
      iconColor: isDark ? const Color(0xFFC0C8D2) : _achievementSlate,
      statusBackgroundColor: _achievementSlate.withValues(
        alpha: isDark ? 0.22 : 0.12,
      ),
      statusForegroundColor: isDark
          ? const Color(0xFFC0C8D2)
          : _achievementSlate,
      progressBackgroundColor: _achievementSlate.withValues(
        alpha: isDark ? 0.18 : 0.10,
      ),
      progressColor: isDark ? const Color(0xFFC0C8D2) : _achievementSlate,
      progressTrackColor: _achievementSlate.withValues(
        alpha: isDark ? 0.24 : 0.12,
      ),
      progressBarColor: _achievementSlate,
    );
  }
}

Color _achievementCategoryColor(String categoryHint) {
  if (_hasAchievementKeyword(categoryHint, const ['photo', 'profile', 'bio'])) {
    return const Color(0xFF188DC8);
  }
  if (_hasAchievementKeyword(categoryHint, const [
    'message',
    'chat',
    'conversation',
  ])) {
    return const Color(0xFF009688);
  }
  if (_hasAchievementKeyword(categoryHint, const ['match', 'like', 'heart'])) {
    return const Color(0xFFD95F84);
  }
  if (_hasAchievementKeyword(categoryHint, const [
    'active',
    'login',
    'days',
    'daily',
    'daily_login',
    'login_streak',
    'streak',
  ])) {
    return const Color(0xFF16A871);
  }

  return _achievementAmber;
}

bool _hasAchievementKeyword(String value, List<String> keywords) {
  return keywords.any(
    (keyword) => RegExp(
      '\\b${RegExp.escape(keyword)}\\b',
      caseSensitive: false,
    ).hasMatch(value),
  );
}
