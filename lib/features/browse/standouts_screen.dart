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
                    description: snapshot.message.isEmpty
                        ? 'These picks stood out in your recommendations, so you can start with the strongest signals first.'
                        : snapshot.message,
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
                  UserAvatar(name: standout.standoutUserName, radius: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          standout.standoutUserAge > 0
                              ? '${standout.standoutUserName}, ${standout.standoutUserAge}'
                              : standout.standoutUserName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Strong match signal',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                standout.reason.isEmpty
                    ? 'We picked this profile because it stood out in your recommendations.'
                    : standout.reason,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('Rank #${standout.rank}')),
                  Chip(label: Text('Score ${standout.score}')),
                  if (standout.createdAt != null)
                    Chip(
                      label: Text(
                        'Suggested ${formatShortDate(standout.createdAt!)}',
                      ),
                    ),
                  if (standout.interactedAt != null)
                    Chip(
                      label: Text(
                        'Opened ${formatShortDate(standout.interactedAt!)}',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: () => _openProfile(context),
                  icon: const Icon(Icons.person_outline_rounded),
                  label: const Text('Open profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
