import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/pending_liker.dart';
import '../../shared/formatting/date_formatting.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../theme/app_theme.dart';
import '../profile/profile_screen.dart';
import '../safety/safety_action_sheet.dart';
import 'pending_likers_provider.dart';

const _pendingRose = Color(0xFFD95F84);
const _pendingCoral = Color(0xFFE28B6C);
const _pendingViolet = Color(0xFF8E6DE8);

class PendingLikersScreen extends ConsumerWidget {
  const PendingLikersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likersState = ref.watch(pendingLikersProvider);
    final controller = ref.read(pendingLikersControllerProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 44,
        title: Text(
          'Likes you',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh people who liked you',
            onPressed: controller.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: likersState.when(
          data: (likers) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.pagePadding,
                  0,
                  AppTheme.pagePadding,
                  10,
                ),
                child: _PendingLikersIntroCard(waitingCount: likers.length),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AppTheme.screenPadding(),
                    children: [
                      if (likers.isEmpty)
                        _PendingLikersEmptyState(
                          waitingCount: likers.length,
                          onRefresh: controller.refresh,
                        )
                      else ...[
                        _PendingLikersSectionLabel(
                          title: likers.length == 1
                              ? '1 person waiting'
                              : '${likers.length} people waiting',
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
            child: const AppAsyncState.loading(
              message: 'Loading people who liked you…',
            ),
          ),
          error: (error, _) => Padding(
            padding: AppTheme.screenPadding(),
            child: AppAsyncState.error(
              message: error is ApiError
                  ? error.message
                  : 'Unable to load pending likes right now.',
              onRetry: controller.refresh,
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
          _pendingRose.withValues(alpha: isDark ? 0.16 : 0.06),
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
                    color: _pendingRose.withValues(alpha: isDark ? 0.22 : 0.12),
                    borderRadius: const BorderRadius.all(Radius.circular(14)),
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
                        'Open a profile for a closer look or refresh to catch new likes as they land.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _PendingInfoPill(
              icon: Icons.people_outline_rounded,
              label: waitingCount == 1
                  ? '1 waiting now'
                  : '$waitingCount waiting now',
              color: _pendingCoral,
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingLikersSectionLabel extends StatelessWidget {
  const _PendingLikersSectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: _pendingRose,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PendingLikersEmptyState extends StatelessWidget {
  const _PendingLikersEmptyState({
    required this.waitingCount,
    required this.onRefresh,
  });

  final int waitingCount;
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
              onPressed: onRefresh,
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
      _pendingRose.withValues(alpha: isDark ? 0.14 : 0.05),
      colorScheme.surface,
    );
    final summary =
        liker.summaryLine ?? 'Open ${liker.name}’s profile for a closer look.';

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(context, color: surfaceColor),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppTheme.panelRadius,
          onTap: () => _openProfile(context),
          child: Padding(
            padding: AppTheme.sectionPadding(compact: true),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [_pendingRose, _pendingViolet],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: UserAvatar(
                              key: ValueKey(
                                'pending-liker-media-${liker.userId}',
                              ),
                              radius: 30,
                              photoUrl: photoUrl,
                              name: liker.name,
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
                                child: Text(
                                  liker.age > 0
                                      ? '${liker.name}, ${liker.age}'
                                      : liker.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: colorScheme.surface.withValues(
                                    alpha: isDark ? 0.76 : 0.92,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.outlineVariant
                                        .withValues(alpha: 0.18),
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
                          const SizedBox(height: 6),
                          Text(
                            summary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (likedAtLabel != null)
                                _PendingInfoPill(
                                  icon: Icons.schedule_rounded,
                                  label: likedAtLabel,
                                  color: _pendingCoral,
                                ),
                              if (liker.approximateLocation
                                  case final location?)
                                _PendingInfoPill(
                                  icon: Icons.location_on_outlined,
                                  label: location,
                                  color: _pendingViolet,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => _openProfile(context),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('Open profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _pendingRose,
                      side: BorderSide(
                        color: _pendingRose.withValues(alpha: 0.28),
                      ),
                      backgroundColor: colorScheme.surface.withValues(
                        alpha: isDark ? 0.76 : 0.88,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
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
