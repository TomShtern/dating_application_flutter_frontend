import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/pending_liker.dart';
import '../../shared/formatting/date_formatting.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/person_media_thumbnail.dart';
import '../../shared/widgets/shell_hero.dart';
import '../../theme/app_theme.dart';
import '../profile/profile_screen.dart';
import '../safety/safety_action_sheet.dart';
import 'pending_likers_provider.dart';

class PendingLikersScreen extends ConsumerWidget {
  const PendingLikersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likersState = ref.watch(pendingLikersProvider);
    final controller = ref.read(pendingLikersControllerProvider);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: AppTheme.screenPadding(),
          child: likersState.when(
            data: (likers) => RefreshIndicator(
              onRefresh: controller.refresh,
              child: ListView(
                children: [
                  ShellHero(
                    compact: true,
                    eyebrowLabel: 'Pending likes',
                    eyebrowIcon: Icons.favorite_rounded,
                    header: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: 'Refresh people who liked you',
                          onPressed: controller.refresh,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    title: 'People who liked you',
                    description:
                        'Open a profile for a closer look, or refresh to see new interest as it lands.',
                  ),
                  SizedBox(height: AppTheme.sectionSpacing(compact: true)),
                  if (likers.isNotEmpty) ...[
                    _PendingLikersSummaryStrip(waitingCount: likers.length),
                    SizedBox(height: AppTheme.sectionSpacing(compact: true)),
                  ],
                  if (likers.isEmpty)
                    AppAsyncState.empty(
                      message:
                          'No likes are waiting right now. New interest will show up here.',
                      onRefresh: controller.refresh,
                    )
                  else
                    ...likers.map(
                      (liker) => Padding(
                        padding: EdgeInsets.only(
                          bottom: AppTheme.listSpacing(compact: true),
                        ),
                        child: _PendingLikerCard(liker: liker),
                      ),
                    ),
                ],
              ),
            ),
            loading: () => const AppAsyncState.loading(
              message: 'Loading people who liked you…',
            ),
            error: (error, _) => AppAsyncState.error(
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

class _PendingLikersSummaryStrip extends StatelessWidget {
  const _PendingLikersSummaryStrip({required this.waitingCount});

  final int waitingCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final countLabel = waitingCount == 1
        ? '1 person waiting'
        : '$waitingCount people waiting';

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.86),
            colorScheme.tertiaryContainer.withValues(alpha: 0.46),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppTheme.panelRadius,
        boxShadow: AppTheme.softShadow(context),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  Icons.favorite_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Already interested',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        countLabel,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap a profile for a closer look.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
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

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: colorScheme.surface.withValues(alpha: 0.94),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppTheme.panelRadius,
          onTap: () => _openProfile(context),
          child: Padding(
            padding: AppTheme.sectionPadding(compact: true),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PersonMediaThumbnail(
                  key: ValueKey('pending-liker-media-${liker.userId}'),
                  name: liker.name,
                  photoUrl: photoUrl,
                  width: 72,
                  height: 72,
                  borderRadius: AppTheme.chipRadius,
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
                              liker.age > 0
                                  ? '${liker.name}, ${liker.age}'
                                  : liker.name,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          SafetyActionsButton(
                            targetUserId: liker.userId,
                            targetUserName: liker.name,
                            tooltip: 'More actions for ${liker.name}',
                          ),
                        ],
                      ),
                      if (liker.summaryLine case final summary?) ...[
                        const SizedBox(height: 4),
                        Text(
                          '“$summary”',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 6,
                              children: [
                                if (likedAtLabel != null)
                                  _PendingLikerMetaText(
                                    icon: Icons.schedule_rounded,
                                    label: likedAtLabel,
                                  ),
                                if (liker.approximateLocation
                                    case final location?)
                                  _PendingLikerMetaText(
                                    icon: Icons.location_on_outlined,
                                    label: location,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Open profile',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ],
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

class _PendingLikerMetaText extends StatelessWidget {
  const _PendingLikerMetaText({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
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
