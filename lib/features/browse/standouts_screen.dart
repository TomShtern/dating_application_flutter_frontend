import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/standout.dart';
import '../../shared/formatting/date_formatting.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/person_media_thumbnail.dart';
import '../../theme/app_theme.dart';
import '../profile/profile_screen.dart';
import 'standouts_provider.dart';

enum _StandoutsViewMode { grid, list }

enum _StandoutCardMode { grid, list }

const double _standoutsCardGap = 16;
const double _standoutsPhoneListBreakpoint = 520;
const _standoutAmber = Color(0xFFD98914);
const _standoutViolet = Color(0xFF8E6DE8);
const _standoutRose = Color(0xFFD95F84);

class StandoutsScreen extends ConsumerStatefulWidget {
  const StandoutsScreen({super.key});

  @override
  ConsumerState<StandoutsScreen> createState() => _StandoutsScreenState();
}

class _StandoutsScreenState extends ConsumerState<StandoutsScreen> {
  _StandoutsViewMode? _viewModeOverride;

  _StandoutsViewMode _resolveViewMode(double width) {
    return _viewModeOverride ??
        (width < _standoutsPhoneListBreakpoint
            ? _StandoutsViewMode.list
            : _StandoutsViewMode.grid);
  }

  @override
  Widget build(BuildContext context) {
    final standoutsState = ref.watch(standoutsProvider);
    final controller = ref.read(standoutsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        toolbarHeight: 44,
        title: Text(
          'Standouts',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        actionsPadding: const EdgeInsets.only(right: AppTheme.pagePadding - 8),
        actions: [
          IconButton(
            tooltip: 'Refresh standouts',
            onPressed: controller.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: standoutsState.when(
          data: (snapshot) => LayoutBuilder(
            builder: (context, constraints) {
              final viewMode = _resolveViewMode(constraints.maxWidth);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StandoutsHero(
                    snapshot: snapshot,
                    viewMode: viewMode,
                    onViewModeChanged: (_StandoutsViewMode nextMode) {
                      setState(() {
                        _viewModeOverride = nextMode;
                      });
                    },
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: controller.refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: AppTheme.screenPadding(),
                        children: [
                          SizedBox(
                            height: AppTheme.sectionSpacing(compact: true),
                          ),
                          if (snapshot.standouts.isEmpty)
                            AppAsyncState.empty(
                              message:
                                  'No standouts are ready right now. Check back soon.',
                              onRefresh: controller.refresh,
                            )
                          else if (viewMode == _StandoutsViewMode.grid)
                            _StandoutsGrid(standouts: snapshot.standouts)
                          else
                            _StandoutsList(standouts: snapshot.standouts),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          loading: () =>
              const AppAsyncState.loading(message: 'Loading standouts…'),
          error: (error, _) => AppAsyncState.error(
            message: error is ApiError
                ? error.message
                : 'Unable to load standouts right now.',
            onRetry: controller.refresh,
          ),
        ),
      ),
    );
  }
}

class _StandoutsHero extends StatelessWidget {
  const _StandoutsHero({
    required this.snapshot,
    required this.viewMode,
    required this.onViewModeChanged,
  });

  final StandoutsSnapshot snapshot;
  final _StandoutsViewMode viewMode;
  final ValueChanged<_StandoutsViewMode> onViewModeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        0,
        AppTheme.pagePadding,
        10,
      ),
      child: DecoratedBox(
        decoration: AppTheme.surfaceDecoration(
          context,
          color: _standoutSurfaceColor(
            context,
            _standoutAmber,
            prominent: true,
          ),
          prominent: true,
        ),
        child: Padding(
          padding: AppTheme.sectionPadding(compact: true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _humanizeStandoutsIntro(snapshot.message),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _StandoutInfoPill(
                    icon: Icons.auto_awesome_rounded,
                    label: snapshot.totalCandidates == 1
                        ? '1 standout ready'
                        : '${snapshot.totalCandidates} standouts ready',
                    color: _standoutAmber,
                  ),
                  _StandoutInfoPill(
                    icon: snapshot.fromCache
                        ? Icons.cloud_outlined
                        : Icons.bolt_rounded,
                    label: snapshot.fromCache
                        ? 'Cached results'
                        : 'Fresh picks',
                    color: _standoutViolet,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  Text(
                    'View',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SegmentedButton<_StandoutsViewMode>(
                    key: const ValueKey('standouts-view-toggle'),
                    segments: const [
                      ButtonSegment<_StandoutsViewMode>(
                        value: _StandoutsViewMode.grid,
                        icon: Icon(Icons.grid_view_rounded),
                        label: Text('Grid'),
                      ),
                      ButtonSegment<_StandoutsViewMode>(
                        value: _StandoutsViewMode.list,
                        icon: Icon(Icons.view_agenda_outlined),
                        label: Text('List'),
                      ),
                    ],
                    selected: {viewMode},
                    onSelectionChanged: (selection) {
                      onViewModeChanged(selection.first);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StandoutsGrid extends StatelessWidget {
  const _StandoutsGrid({required this.standouts});

  final List<Standout> standouts;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 720
            ? 3
            : constraints.maxWidth >= 360
            ? 2
            : 1;
        final availableWidth =
            constraints.maxWidth - (_standoutsCardGap * (crossAxisCount - 1));
        final tileWidth = availableWidth / crossAxisCount;
        final mainAxisExtent = tileWidth >= 220 ? 272.0 : 260.0;

        return GridView.builder(
          key: const ValueKey('standouts-grid'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: standouts.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: _standoutsCardGap,
            mainAxisSpacing: _standoutsCardGap,
            mainAxisExtent: mainAxisExtent,
          ),
          itemBuilder: (context, index) {
            return _StandoutCard(
              standout: standouts[index],
              mode: _StandoutCardMode.grid,
            );
          },
        );
      },
    );
  }
}

class _StandoutsList extends StatelessWidget {
  const _StandoutsList({required this.standouts});

  final List<Standout> standouts;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('standouts-list'),
      children: standouts
          .map(
            (standout) => Padding(
              padding: const EdgeInsets.only(bottom: _standoutsCardGap),
              child: _StandoutCard(
                standout: standout,
                mode: _StandoutCardMode.list,
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _StandoutCard extends StatelessWidget {
  const _StandoutCard({required this.standout, required this.mode});

  final Standout standout;
  final _StandoutCardMode mode;

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProfileScreen.otherUser(
          userId: standout.standoutUserId,
          userName: standout.standoutUserName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = standout.rank == 1 ? _standoutAmber : _standoutViolet;

    return DecoratedBox(
      key: ValueKey('standout-card-${standout.id}'),
      decoration: AppTheme.surfaceDecoration(
        context,
        color: _standoutSurfaceColor(
          context,
          accentColor,
          prominent: standout.rank == 1,
        ),
        prominent: standout.rank == 1,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppTheme.panelRadius,
          onTap: () => _openProfile(context),
          child: Padding(
            padding: mode == _StandoutCardMode.grid
                ? const EdgeInsets.all(12)
                : AppTheme.sectionPadding(compact: true),
            child: mode == _StandoutCardMode.grid
                ? _StandoutGridContent(
                    standout: standout,
                    onOpenProfile: () => _openProfile(context),
                  )
                : _StandoutListContent(
                    standout: standout,
                    onOpenProfile: () => _openProfile(context),
                  ),
          ),
        ),
      ),
    );
  }
}

class _StandoutListContent extends StatelessWidget {
  const _StandoutListContent({
    required this.standout,
    required this.onOpenProfile,
  });

  final Standout standout;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = _standoutFreshness(standout);
    final location = standout.approximateLocation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PersonMediaThumbnail(
              key: ValueKey('standout-media-${standout.id}'),
              name: standout.standoutUserName,
              photoUrl: _primaryPhotoUrl(
                standout.primaryPhotoUrl,
                standout.photoUrls,
              ),
              width: 80,
              height: 104,
              borderRadius: AppTheme.cardRadius,
            ),
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
                          _standoutDisplayName(standout),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (_rankLabel(standout) != null) ...[
                        const SizedBox(width: 8),
                        _StandoutRankBadge(standout: standout),
                      ],
                    ],
                  ),
                  if (standout.summaryLine case final summary?) ...[
                    const SizedBox(height: 6),
                    Text(
                      summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (location != null && location.isNotEmpty)
                        _StandoutInfoPill(
                          icon: Icons.location_on_outlined,
                          label: location,
                          color: _standoutViolet,
                        ),
                      if (metadata != null)
                        _StandoutInfoPill(
                          icon: Icons.schedule_rounded,
                          label: metadata,
                          color: _standoutRose,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _humanizeStandoutReason(standout),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onOpenProfile,
          style: TextButton.styleFrom(
            foregroundColor: _standoutRose,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          label: const Text('Profile'),
        ),
      ],
    );
  }
}

class _StandoutGridContent extends StatelessWidget {
  const _StandoutGridContent({
    required this.standout,
    required this.onOpenProfile,
  });

  final Standout standout;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = _standoutFreshness(standout);
    final location = standout.approximateLocation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_rankLabel(standout) != null)
          Align(
            alignment: Alignment.centerLeft,
            child: _StandoutRankBadge(standout: standout, compact: true),
          ),
        const SizedBox(height: 8),
        PersonMediaThumbnail(
          key: ValueKey('standout-media-${standout.id}'),
          name: standout.standoutUserName,
          photoUrl: _primaryPhotoUrl(
            standout.primaryPhotoUrl,
            standout.photoUrls,
          ),
          width: double.infinity,
          height: 116,
          borderRadius: AppTheme.cardRadius,
        ),
        const SizedBox(height: 8),
        Text(
          _standoutDisplayName(standout),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (location != null && location.isNotEmpty)
              _StandoutInfoPill(
                icon: Icons.location_on_outlined,
                label: location,
                color: _standoutViolet,
              ),
            if (metadata != null)
              _StandoutInfoPill(
                icon: Icons.schedule_rounded,
                label: metadata,
                color: _standoutRose,
              ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Text(
            _humanizeStandoutReason(standout),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onOpenProfile,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              foregroundColor: _standoutRose,
            ),
            child: const Text('Profile'),
          ),
        ),
      ],
    );
  }
}

class _StandoutRankBadge extends StatelessWidget {
  const _StandoutRankBadge({required this.standout, this.compact = false});

  final Standout standout;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = compact ? _compactRankLabel(standout) : _rankLabel(standout);
    if (label == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isTopRank = standout.rank == 1;

    return DecoratedBox(
      key: ValueKey('standout-rank-${standout.id}'),
      decoration: BoxDecoration(
        gradient: isTopRank
            ? const LinearGradient(
                colors: [_standoutRose, _standoutAmber],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isTopRank
            ? null
            : _standoutAmber.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.22
                    : 0.12,
              ),
        borderRadius: AppTheme.chipRadius,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 6 : 7,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: compact ? 14 : 16,
              color: isTopRank ? Colors.white : _standoutAmber,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isTopRank ? Colors.white : _standoutAmber,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StandoutInfoPill extends StatelessWidget {
  const _StandoutInfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: AppTheme.chipRadius,
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _standoutDisplayName(Standout standout) {
  if (standout.standoutUserAge > 0) {
    return '${standout.standoutUserName}, ${standout.standoutUserAge}';
  }

  return standout.standoutUserName;
}

String? _rankLabel(Standout standout) {
  if (standout.rank > 0 && standout.score > 0) {
    return '#${standout.rank} · ${standout.score} pts';
  }
  if (standout.rank > 0) {
    return '#${standout.rank}';
  }
  if (standout.score > 0) {
    return '${standout.score} pts';
  }

  return null;
}

String? _compactRankLabel(Standout standout) {
  if (standout.rank > 0) {
    return '#${standout.rank}';
  }
  if (standout.score > 0) {
    return '${standout.score}';
  }

  return null;
}

String? _standoutFreshness(Standout standout) {
  if (standout.interactedAt case final openedAt?) {
    return 'Opened ${formatShortDate(openedAt)}';
  }
  if (standout.createdAt case final createdAt?) {
    return 'Suggested ${formatShortDate(createdAt)}';
  }

  return null;
}

String _humanizeStandoutsIntro(String message) {
  final trimmed = message.trim();
  if (trimmed.isEmpty) {
    return 'These picks feel especially promising right now, so you can start with the profiles most worth a closer look.';
  }

  return trimmed;
}

String _humanizeStandoutReason(Standout standout) {
  final reason = standout.reason.trim();
  if (reason.isEmpty) {
    return standout.summaryLine ?? 'Standout profile';
  }

  return reason;
}

String? _primaryPhotoUrl(String? primaryPhotoUrl, List<String> photoUrls) {
  if (primaryPhotoUrl != null && primaryPhotoUrl.trim().isNotEmpty) {
    return primaryPhotoUrl;
  }

  return photoUrls.isEmpty ? null : photoUrls.first;
}

Color _standoutSurfaceColor(
  BuildContext context,
  Color accent, {
  bool prominent = false,
}) {
  final theme = Theme.of(context);
  final alpha = prominent
      ? (theme.brightness == Brightness.dark ? 0.18 : 0.06)
      : (theme.brightness == Brightness.dark ? 0.12 : 0.04);

  return Color.alphaBlend(
    accent.withValues(alpha: alpha),
    theme.colorScheme.surface,
  );
}
