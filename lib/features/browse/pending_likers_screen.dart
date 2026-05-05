import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/pending_liker.dart';
import '../../shared/formatting/date_formatting.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/app_group_label.dart';
import '../../shared/widgets/app_route_header.dart';
import '../../shared/widgets/person_media_thumbnail.dart';
import '../../theme/app_theme.dart';
import '../profile/profile_screen.dart';
import '../safety/safety_action_sheet.dart';
import 'pending_likers_provider.dart';

const _pendingRose = Color(0xFFD95F84);
const _pendingCoral = Color(0xFFE28B6C);
const _pendingViolet = Color(0xFF8E6DE8);
const _pendingSky = Color(0xFF188DC8);

class PendingLikersScreen extends ConsumerWidget {
  const PendingLikersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likersState = ref.watch(pendingLikersProvider);
    final controller = ref.read(pendingLikersControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: likersState.when(
          data: (likers) => Column(
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
                  title: 'Likes you',
                  trailing: IconButton(
                    tooltip: 'Refresh people who liked you',
                    onPressed: controller.refresh,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.pagePadding,
                      0,
                      AppTheme.pagePadding,
                      AppTheme.pagePadding,
                    ),
                    children: [
                      _PendingLikersIntroCard(waitingCount: likers.length),
                      SizedBox(height: AppTheme.sectionSpacing(compact: true)),
                      if (likers.isEmpty)
                        _PendingLikersEmptyState(onRefresh: controller.refresh)
                      else ...[
                        AppGroupLabel(
                          title: likers.length == 1
                              ? '1 person waiting'
                              : '${likers.length} people waiting',
                          accentColor: _pendingRose,
                        ),
                        SizedBox(height: AppTheme.listSpacing(compact: true)),
                        ...likers.map(
                          (liker) => Padding(
                            padding: EdgeInsets.only(
                              bottom: AppTheme.listSpacing(compact: true),
                            ),
                            child: _PendingLikerCard(liker: liker),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          loading: () => Padding(
            padding: AppTheme.screenPadding(),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppRouteHeader(title: 'Likes you'),
                SizedBox(height: 16),
                Expanded(
                  child: AppAsyncState.loading(
                    message: 'Loading people who liked you…',
                  ),
                ),
              ],
            ),
          ),
          error: (error, _) => Padding(
            padding: AppTheme.screenPadding(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppRouteHeader(title: 'Likes you'),
                const SizedBox(height: 16),
                Expanded(
                  child: AppAsyncState.error(
                    message: error is ApiError
                        ? error.message
                        : 'Unable to load pending likes right now.',
                    onRetry: controller.refresh,
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

class _PendingLikersIntroCard extends StatelessWidget {
  const _PendingLikersIntroCard({required this.waitingCount});

  final int waitingCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: Color.alphaBlend(
          _pendingSky.withValues(alpha: isDark ? 0.14 : 0.05),
          colorScheme.surfaceContainerLow,
        ),
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
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF4A2230)
                        : const Color(0xFFFFF0F3),
                    borderRadius: const BorderRadius.all(Radius.circular(14)),
                    border: Border.all(
                      color: _pendingRose.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.favorite_rounded,
                      size: 18,
                      color: _pendingRose,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        waitingCount == 1
                            ? '1 person liked you'
                            : '$waitingCount people liked you',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Review who is waiting and open the profile when a signal looks promising.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PendingInfoPill(
                  icon: Icons.favorite_border_rounded,
                  label: waitingCount == 1
                      ? '1 waiting'
                      : '$waitingCount waiting',
                  color: _pendingRose,
                ),
                const _PendingInfoPill(
                  icon: Icons.person_search_rounded,
                  label: 'Open profile first',
                  color: _pendingSky,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingLikersEmptyState extends StatelessWidget {
  const _PendingLikersEmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: Color.alphaBlend(
          _pendingViolet.withValues(alpha: isDark ? 0.16 : 0.05),
          theme.colorScheme.surfaceContainerLow,
        ),
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PendingInfoPill(
              icon: Icons.favorite_border_rounded,
              label: 'No pending likes right now',
              color: _pendingRose,
            ),
            const SizedBox(height: 14),
            Text(
              'New interest will show up here when someone likes your profile.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () async {
                await onRefresh();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingInfoPill extends StatelessWidget {
  const _PendingInfoPill({
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
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
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

class _PendingLikerCard extends StatelessWidget {
  const _PendingLikerCard({required this.liker});

  final PendingLiker liker;

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            ProfileScreen.otherUser(userId: liker.userId, userName: liker.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final likedAtLabel = _pendingLikerLikedAtLabel(liker);
    final photoUrl = _primaryPhotoUrl(liker.primaryPhotoUrl, liker.photoUrls);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = Color.alphaBlend(
      _pendingSky.withValues(alpha: isDark ? 0.08 : 0.025),
      Color.alphaBlend(
        _pendingRose.withValues(alpha: isDark ? 0.10 : 0.035),
        colorScheme.surface,
      ),
    );
    final summary =
        liker.summaryLine ?? 'Open ${liker.name}’s profile before deciding.';

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: surfaceColor,
        prominent: true,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppTheme.panelRadius,
          onTap: () => _openProfile(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_pendingRose, _pendingViolet],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(24),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: PersonMediaThumbnail(
                          key: ValueKey('pending-liker-media-${liker.userId}'),
                          name: liker.name,
                          photoUrl: photoUrl,
                          width: 92,
                          height: 118,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(21),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _pendingRose,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        child: const SizedBox(width: 14, height: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
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
                                  liker.age > 0
                                      ? '${liker.name}, ${liker.age}'
                                      : liker.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (likedAtLabel != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    likedAtLabel,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: _pendingCoral,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: colorScheme.surface.withValues(
                                alpha: isDark ? 0.76 : 0.92,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.outlineVariant.withValues(
                                  alpha: 0.18,
                                ),
                              ),
                            ),
                            child: SafetyActionsButton(
                              targetUserId: liker.userId,
                              targetUserName: liker.name,
                              tooltip: 'More actions for ${liker.name}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        summary,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          height: 1.34,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (liker.approximateLocation case final location?)
                            _PendingInfoPill(
                              icon: Icons.location_on_outlined,
                              label: location,
                              color: _pendingViolet,
                            ),
                          _PendingInfoPill(
                            icon: Icons.person_search_rounded,
                            label: 'View profile before deciding',
                            color: _pendingSky,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            'See more of ${liker.name}\'s profile',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: _pendingSky,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: _pendingSky.withValues(alpha: 0.82),
                            size: 22,
                          ),
                        ],
                      ),
                    ],
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

String? _pendingLikerLikedAtLabel(PendingLiker liker) {
  if (liker.likedAt case final likedAt?) {
    return 'Liked ${formatShortDate(likedAt)}';
  }

  return null;
}

String? _primaryPhotoUrl(String? primaryPhotoUrl, List<String> photoUrls) {
  if (primaryPhotoUrl != null && primaryPhotoUrl.trim().isNotEmpty) {
    return primaryPhotoUrl;
  }

  return photoUrls.isEmpty ? null : photoUrls.first;
}
