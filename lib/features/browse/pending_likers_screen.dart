import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/pending_liker.dart';
import '../../shared/formatting/date_formatting.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/section_intro_card.dart';
import '../../shared/widgets/user_avatar.dart';
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
          padding: const EdgeInsets.all(24),
          child: likersState.when(
            data: (likers) => RefreshIndicator(
              onRefresh: controller.refresh,
              child: ListView(
                children: [
                  SectionIntroCard(
                    icon: Icons.favorite_rounded,
                    title: "People who've already liked you",
                    description:
                        'Open a profile when you want a closer look before deciding what to do next.',
                    badges: [
                      Chip(
                        label: Text(
                          likers.length == 1
                              ? '1 person waiting'
                              : '${likers.length} people waiting',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (likers.isEmpty)
                    AppAsyncState.empty(
                      message:
                          'No likes are waiting right now. New interest will show up here.',
                      onRefresh: controller.refresh,
                    )
                  else
                    ...likers.map(
                      (liker) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
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
    final statusLabel = liker.likedAt == null
        ? 'Liked you recently'
        : 'Liked you on ${formatShortDate(liker.likedAt!)}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openProfile(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  UserAvatar(name: liker.name, radius: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          liker.age > 0
                              ? '${liker.name}, ${liker.age}'
                              : liker.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Open their profile to learn more.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [Chip(label: Text(statusLabel))],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: () => _openProfile(context),
                  icon: const Icon(Icons.person_outline_rounded),
                  label: const Text('View profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
