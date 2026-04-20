import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/standout.dart';
import '../../shared/formatting/date_formatting.dart';
import '../../shared/widgets/app_async_state.dart';
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
                  Card(
                    child: ListTile(
                      title: const Text('Why these profiles stand out'),
                      subtitle: Text(
                        snapshot.message.isEmpty
                            ? '${snapshot.totalCandidates} standout candidates are ready to review.'
                            : snapshot.message,
                      ),
                      trailing: snapshot.fromCache
                          ? const Chip(label: Text('Cached'))
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (snapshot.standouts.isEmpty)
                    AppAsyncState.empty(
                      message: 'No standouts are available right now.',
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

  @override
  Widget build(BuildContext context) {
    return Card(
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
                      Text('Rank #${standout.rank} • Score ${standout.score}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              standout.reason.isEmpty
                  ? 'The backend highlighted this profile for you.'
                  : standout.reason,
            ),
            if (standout.createdAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Created ${formatDateTimeStamp(standout.createdAt!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => ProfileScreen.otherUser(
                        userId: standout.standoutUserId,
                        userName: standout.standoutUserName,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.person_outline_rounded),
                label: const Text('View profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
