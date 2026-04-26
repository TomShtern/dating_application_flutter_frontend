import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/pending_liker.dart';
import '../../shared/formatting/date_formatting.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../theme/app_theme.dart';
import '../profile/profile_screen.dart';
import 'pending_likers_provider.dart';

class PendingLikersScreen extends ConsumerWidget {
  const PendingLikersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likersState = ref.watch(pendingLikersProvider);
    final controller = ref.read(pendingLikersControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('People who liked you'),
        actions: [
          IconButton(
            tooltip: 'Refresh people who liked you',
            onPressed: controller.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: AppTheme.screenPadding(),
          child: likersState.when(
            data: (likers) => RefreshIndicator(
              onRefresh: controller.refresh,
              child: ListView(
                children: [
                  _PendingLikersSummaryCard(waitingCount: likers.length),
                  SizedBox(height: AppTheme.sectionSpacing(compact: true)),
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

class _PendingLikersSummaryCard extends StatelessWidget {
  const _PendingLikersSummaryCard({required this.waitingCount});

  final int waitingCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final countLabel = waitingCount == 1
        ? '1 person waiting'
        : '$waitingCount people waiting';

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: colorScheme.surface.withValues(alpha: 0.92),
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(compact: true),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: const BorderRadius.all(Radius.circular(16)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(Icons.favorite_rounded, color: colorScheme.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Already interested',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Open a profile when you want a closer read on the people who already liked you.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            DecoratedBox(
              decoration: AppTheme.glassDecoration(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Text(countLabel, style: theme.textTheme.labelLarge),
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
    final statusLabel = _pendingLikerStatusLabel(liker);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: colorScheme.surface.withValues(alpha: 0.94),
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(compact: true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserAvatar(
                  name: liker.name,
                  photoUrl: _primaryPhotoUrl(
                    liker.primaryPhotoUrl,
                    liker.photoUrls,
                  ),
                  radius: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        liker.age > 0
                            ? '${liker.name}, ${liker.age}'
                            : liker.name,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _pendingLikerContextLine(liker),
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (liker.summaryLine != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          liker.summaryLine!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.schedule_rounded, size: 18),
                  label: Text(statusLabel),
                ),
                if (liker.approximateLocation != null)
                  Chip(
                    avatar: const Icon(Icons.location_on_outlined, size: 18),
                    label: Text(liker.approximateLocation!),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: () => _openProfile(context),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _pendingLikerStatusLabel(PendingLiker liker) {
  if (liker.likedAt == null) {
    return 'Recent like';
  }

  return 'Liked ${formatShortDate(liker.likedAt!)}';
}

String _pendingLikerContextLine(PendingLiker liker) {
  if (liker.approximateLocation != null) {
    return liker.approximateLocation!;
  }

  if (liker.likedAt case final likedAt?) {
    return '${liker.name} made the first move on ${formatShortDate(likedAt)}.';
  }

  return '${liker.name} is one of your newest likes.';
}

String? _primaryPhotoUrl(String? primaryPhotoUrl, List<String> photoUrls) {
  if (primaryPhotoUrl != null && primaryPhotoUrl.trim().isNotEmpty) {
    return primaryPhotoUrl;
  }

  return photoUrls.isEmpty ? null : photoUrls.first;
}
