import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/standout.dart';
import '../../shared/formatting/date_formatting.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/section_intro_card.dart';
import '../../shared/widgets/user_avatar.dart';
import '../profile/profile_screen.dart';
import 'standouts_provider.dart';

class StandoutsScreen extends ConsumerWidget {
  const StandoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standoutsState = ref.watch(standoutsProvider);
    final controller = ref.read(standoutsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Standouts'),
        actions: [
          IconButton(
            tooltip: 'Refresh standouts',
            onPressed: controller.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: standoutsState.when(
            data: (snapshot) => RefreshIndicator(
              onRefresh: controller.refresh,
              child: ListView(
                children: [
                  SectionIntroCard(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Profiles worth a closer look',
                    description: _humanizeStandoutsIntro(snapshot.message),
                    badges: [
                      Chip(
                        label: Text(
                          snapshot.totalCandidates == 1
                              ? '1 standout ready'
                              : '${snapshot.totalCandidates} standouts ready',
                        ),
                      ),
                      if (snapshot.fromCache)
                        const Chip(label: Text('Cached results')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (snapshot.standouts.isEmpty)
                    AppAsyncState.empty(
                      message:
                          'No standouts are ready right now. Check back soon for a fresh set of highlights.',
                      onRefresh: controller.refresh,
                    )
                  else
                    ...snapshot.standouts.map(
                      (standout) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _StandoutCard(standout: standout),
                      ),
                    ),
                ],
              ),
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
      ),
    );
  }
}

class _StandoutCard extends StatelessWidget {
  const _StandoutCard({required this.standout});

  final Standout standout;

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
    final metadata = _standoutMetadata(standout);
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                  name: standout.standoutUserName,
                  photoUrl: _primaryPhotoUrl(
                    standout.primaryPhotoUrl,
                    standout.photoUrls,
                  ),
                  radius: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        standout.standoutUserAge > 0
                            ? '${standout.standoutUserName}, ${standout.standoutUserAge}'
                            : standout.standoutUserName,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        standout.approximateLocation ?? 'Standout profile',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (standout.summaryLine != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          standout.summaryLine!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _humanizeStandoutReason(standout),
              style: theme.textTheme.bodyLarge,
            ),
            if (metadata != null) ...[
              const SizedBox(height: 10),
              Text(
                metadata,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _openProfile(context),
                child: const Text('Open profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String? _standoutMetadata(Standout standout) {
  final parts = <String>[];

  if (standout.rank > 0 && standout.score > 0) {
    parts.add('#${standout.rank} · ${standout.score} points');
  } else if (standout.rank > 0) {
    parts.add('#${standout.rank}');
  } else if (standout.score > 0) {
    parts.add('${standout.score} points');
  }

  if (standout.createdAt != null) {
    parts.add('Suggested ${formatShortDate(standout.createdAt!)}');
  }

  if (standout.interactedAt != null) {
    parts.add('Opened ${formatShortDate(standout.interactedAt!)}');
  }

  if (parts.isEmpty) {
    return null;
  }

  return parts.join(' · ');
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
