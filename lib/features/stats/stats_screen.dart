import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/user_summary.dart';
import '../../models/user_stats.dart';
import '../../shared/formatting/display_text.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/app_group_label.dart';
import '../../shared/widgets/app_route_header.dart';
import '../../theme/app_theme.dart';
import 'achievements_screen.dart';
import 'stat_detail_sheet.dart';
import 'stats_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key, required this.currentUser});

  final UserSummary currentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsState = ref.watch(statsProvider);

    return Scaffold(
      body: SafeArea(
        child: statsState.when(
          data: (stats) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.pagePadding,
                  8,
                  AppTheme.pagePadding,
                  8,
                ),
                child: AppRouteHeader(
                  title: 'Stats',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: 'View achievements',
                        child: IconButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) => AchievementsScreen(
                                  currentUser: currentUser,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.workspace_premium_outlined),
                        ),
                      ),
                      Tooltip(
                        message: 'Refresh stats',
                        child: IconButton(
                          onPressed: () => ref.invalidate(statsProvider),
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _StatsDashboard(
                  currentUser: currentUser,
                  stats: stats,
                  onRefresh: () => ref.invalidate(statsProvider),
                ),
              ),
            ],
          ),
          loading: () => Padding(
            padding: AppTheme.screenPadding(),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppRouteHeader(title: 'Stats'),
                SizedBox(height: 16),
                Expanded(
                  child: AppAsyncState.loading(message: 'Loading stats…'),
                ),
              ],
            ),
          ),
          error: (error, stackTrace) => Padding(
            padding: AppTheme.screenPadding(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppRouteHeader(title: 'Stats'),
                const SizedBox(height: 16),
                Expanded(
                  child: AppAsyncState.error(
                    message: error is ApiError
                        ? error.message
                        : 'Unable to load stats right now.',
                    onRetry: () => ref.invalidate(statsProvider),
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

class _StatsDashboard extends StatelessWidget {
  const _StatsDashboard({
    required this.currentUser,
    required this.stats,
    required this.onRefresh,
  });

  final UserSummary currentUser;
  final UserStats stats;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final snapshotItems = stats.items.take(4).toList(growable: false);
    final performanceItems = stats.items.skip(4).toList(growable: false);

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppTheme.pagePadding,
          0,
          AppTheme.pagePadding,
          AppTheme.pagePadding,
        ),
        children: [
          _StatsOverviewCard(currentUser: currentUser, stats: stats),
          SizedBox(height: AppTheme.sectionSpacing()),
          if (stats.items.isEmpty)
            const AppAsyncState.empty(
              message:
                  'Stats start populating after a few likes, matches, and conversations. Check back once you\'ve been active.',
            )
          else ...[
            AppGroupLabel(
              title: 'Snapshot',
              countText: '${snapshotItems.length}',
            ),
            const SizedBox(height: AppTheme.cardGap),
            _SnapshotGrid(items: snapshotItems),
            if (performanceItems.isNotEmpty) ...[
              SizedBox(height: AppTheme.sectionSpacing()),
              AppGroupLabel(
                title: 'Performance',
                countText: '${performanceItems.length}',
              ),
              const SizedBox(height: AppTheme.cardGap),
              for (var index = 0; index < performanceItems.length; index++) ...[
                _PerformanceStatCard(item: performanceItems[index]),
                if (index != performanceItems.length - 1)
                  SizedBox(height: AppTheme.listSpacing()),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

class _SnapshotGrid extends StatelessWidget {
  const _SnapshotGrid({required this.items});

  final List<UserStatItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - AppTheme.cardGap) / 2;

        return Wrap(
          spacing: AppTheme.cardGap,
          runSpacing: AppTheme.cardGap,
          children: [
            for (var index = 0; index < items.length; index++)
              SizedBox(
                width: tileWidth,
                child: _SnapshotStatTile(item: items[index], index: index),
              ),
          ],
        );
      },
    );
  }
}

class _SnapshotStatTile extends StatelessWidget {
  const _SnapshotStatTile({required this.item, required this.index});

  final UserStatItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spec = _StatVisualSpec.forLabel(item.label);

    return Material(
      color: Colors.transparent,
      borderRadius: AppTheme.panelRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showStatDetailSheet(context: context, item: item),
        child: Ink(
          decoration: AppTheme.surfaceDecoration(
            context,
            color: _statSurfaceColor(context, spec),
            prominent: false,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        spec.color.withValues(alpha: 0.85),
                        spec.color.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 11),
                child: SizedBox(
                  height: 108,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StatIconChip(spec: spec, size: 32),
                          const Spacer(),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: spec.color.withValues(alpha: 0.08),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(999),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 7,
                              ),
                              child: _StatActivityMarks(
                                seed: item.label,
                                color: spec.color,
                                compact: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AnimatedStatValue(
                            value: item.value,
                            color: spec.color,
                            duration: Duration(milliseconds: 500 + index * 80),
                            dense: true,
                          ),
                          const SizedBox(height: 7),
                          Text(
                            item.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                    ],
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

class _PerformanceStatCard extends StatelessWidget {
  const _PerformanceStatCard({required this.item});

  final UserStatItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spec = _StatVisualSpec.forLabel(item.label);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppTheme.panelRadius,
        onTap: () => showStatDetailSheet(context: context, item: item),
        child: Ink(
          decoration: AppTheme.surfaceDecoration(
            context,
            color: _statSurfaceColor(context, spec),
            prominent: false,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppTheme.cardPadding,
              14,
              AppTheme.cardPadding,
              14,
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 56,
                  margin: const EdgeInsets.only(
                    left: 0,
                    right: 12,
                    top: 4,
                    bottom: 4,
                  ),
                  decoration: BoxDecoration(
                    color: spec.color.withValues(alpha: 0.85),
                    borderRadius: const BorderRadius.all(Radius.circular(999)),
                  ),
                ),
                _StatIconChip(spec: spec, size: 40),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      _AnimatedStatValue(
                        value: item.value,
                        color: spec.color,
                        dense: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _PerformanceAccent(
                  label: item.label,
                  value: item.value,
                  color: spec.color,
                ),
              ],
            ),
          ),
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
    final active = currentUser.state.toLowerCase() == 'active';

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD4B3).withValues(alpha: 0.98),
            const Color(0xFFD2BCFF).withValues(alpha: 0.96),
            const Color(0xFFB8E1FF).withValues(alpha: 0.95),
          ],
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
                        'Momentum for ${currentUser.name}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.sync_rounded,
                            size: 12,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.6,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Latest stats snapshot',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _AnimatedIntText(
                            value: stats.items.length,
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF4C2F88),
                              height: 0.95,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              stats.items.length == 1
                                  ? 'highlight'
                                  : 'highlights',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: const Color(0xFF4C2F88),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                DecoratedBox(
                  decoration: AppTheme.glassDecoration(
                    context,
                  ).copyWith(borderRadius: AppTheme.cardRadius),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFE35D4F),
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatsSummaryPill(
                  icon: active
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  label: '${formatDisplayLabel(currentUser.state)} profile',
                  backgroundColor: active
                      ? const Color(0xFFDDF8E7)
                      : Colors.white.withValues(alpha: 0.7),
                  foregroundColor: active
                      ? const Color(0xFF167442)
                      : colorScheme.onSurface,
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) =>
                            AchievementsScreen(currentUser: currentUser),
                      ),
                    );
                  },
                  icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                  label: const Text('Achievements'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.92),
                    foregroundColor: const Color(0xFF9A4B00),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                    ),
                    textStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
  const _StatsSummaryPill({
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
      child: Material(
        color: Colors.transparent,
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
      ),
    );
  }
}

class _StatIconChip extends StatelessWidget {
  const _StatIconChip({required this.spec, required this.size});

  final _StatVisualSpec spec;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: spec.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.all(Radius.circular(size * 0.42)),
      ),
      child: SizedBox.square(
        dimension: size,
        child: Icon(spec.icon, color: spec.color, size: size * 0.56),
      ),
    );
  }
}

class _AnimatedStatValue extends StatelessWidget {
  const _AnimatedStatValue({
    required this.value,
    required this.color,
    this.duration = const Duration(milliseconds: 620),
    this.dense = false,
  });

  final String value;
  final Color color;
  final Duration duration;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final intValue = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));

    if (intValue == null || intValue == 0 && !value.contains('0')) {
      return Text(
        value,
        style:
            (dense
                    ? theme.textTheme.headlineMedium
                    : theme.textTheme.headlineSmall)
                ?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  height: dense ? 1.0 : null,
                ),
      );
    }

    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: intValue),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        final rendered = value.replaceFirst(
          RegExp(r'\d+'),
          animatedValue.toString(),
        );

        return Text(
          rendered,
          style:
              (dense
                      ? theme.textTheme.headlineMedium
                      : theme.textTheme.headlineSmall)
                  ?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    height: dense ? 1.0 : null,
                  ),
        );
      },
    );
  }
}

class _AnimatedIntText extends StatelessWidget {
  const _AnimatedIntText({required this.value, required this.style});

  final int value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Text('$animatedValue', style: style);
      },
    );
  }
}

class _PerformanceAccent extends StatelessWidget {
  const _PerformanceAccent({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final percent = _tryParsePercent(value);

    if (percent != null) {
      return _StatCurrentValueRing(percent: percent, color: color);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.16 : 0.08,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: _StatActivityMarks(seed: '$label-$value', color: color),
      ),
    );
  }
}

class _StatActivityMarks extends StatelessWidget {
  const _StatActivityMarks({
    required this.seed,
    required this.color,
    this.compact = false,
  });

  final String seed;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pattern = _activityPattern(seed);
    final maxHeight = compact ? 16.0 : 30.0;
    final barWidth = compact ? 4.0 : 6.0;
    final spacing = compact ? 3.0 : 4.0;

    return SizedBox(
      height: maxHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var index = 0; index < pattern.length; index++) ...[
            DecoratedBox(
              decoration: BoxDecoration(
                color: color.withValues(alpha: compact ? 0.72 : 0.64),
                borderRadius: const BorderRadius.all(Radius.circular(999)),
              ),
              child: SizedBox(
                width: barWidth,
                height: maxHeight * pattern[index],
              ),
            ),
            if (index != pattern.length - 1) SizedBox(width: spacing),
          ],
        ],
      ),
    );
  }
}

class _StatCurrentValueRing extends StatelessWidget {
  const _StatCurrentValueRing({required this.percent, required this.color});

  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final displayPercent = (percent * 100).round();

    return SizedBox.square(
      dimension: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.square(
            dimension: 60,
            child: CircularProgressIndicator(
              value: percent,
              strokeWidth: 5,
              backgroundColor: color.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Text(
            '$displayPercent%',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

double? _tryParsePercent(String value) {
  final match = RegExp(r'(\d+)\s*%').firstMatch(value);
  if (match == null) {
    return null;
  }

  final parsed = double.tryParse(match.group(1)!);
  if (parsed == null) {
    return null;
  }

  return (parsed / 100).clamp(0.0, 1.0);
}

List<double> _activityPattern(String seed) {
  const patterns = <List<double>>[
    [0.44, 0.78, 0.52, 0.86, 0.60],
    [0.62, 0.38, 0.80, 0.50, 0.72],
    [0.54, 0.84, 0.42, 0.74, 0.58],
    [0.70, 0.48, 0.64, 0.40, 0.82],
  ];

  final hash = seed.runes.fold<int>(0, (total, rune) => total + rune);
  return patterns[hash % patterns.length];
}

class _StatVisualSpec {
  const _StatVisualSpec({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  static _StatVisualSpec forLabel(String label) {
    final normalized = label.toLowerCase();

    if (normalized.contains('sent')) {
      return const _StatVisualSpec(
        icon: Icons.send_rounded,
        color: Color(0xFFFF7043),
      );
    }
    if (normalized.contains('received') || normalized.contains('like')) {
      return const _StatVisualSpec(
        icon: Icons.favorite_rounded,
        color: Color(0xFFE24A68),
      );
    }
    if (normalized.contains('week') || normalized.contains('calendar')) {
      return const _StatVisualSpec(
        icon: Icons.calendar_today_rounded,
        color: Color(0xFF5B6EE1),
      );
    }
    if (normalized.contains('match')) {
      return const _StatVisualSpec(
        icon: Icons.bolt_rounded,
        color: Color(0xFF7C4DFF),
      );
    }
    if (normalized.contains('reply') || normalized.contains('rate')) {
      return const _StatVisualSpec(
        icon: Icons.reply_rounded,
        color: Color(0xFF2E9D57),
      );
    }
    if (normalized.contains('conversation') || normalized.contains('chat')) {
      return const _StatVisualSpec(
        icon: Icons.chat_bubble_outline_rounded,
        color: Color(0xFF009688),
      );
    }
    if (normalized.contains('time') || normalized.contains('response')) {
      return const _StatVisualSpec(
        icon: Icons.timer_outlined,
        color: Color(0xFFD98914),
      );
    }
    if (normalized.contains('view')) {
      return const _StatVisualSpec(
        icon: Icons.visibility_rounded,
        color: Color(0xFF188DC8),
      );
    }

    return const _StatVisualSpec(
      icon: Icons.query_stats_rounded,
      color: Color(0xFF596579),
    );
  }
}

Color _statSurfaceColor(BuildContext context, _StatVisualSpec spec) {
  final colorScheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Color.alphaBlend(
    spec.color.withValues(alpha: isDark ? 0.08 : 0.035),
    colorScheme.surfaceContainerLow,
  );
}
