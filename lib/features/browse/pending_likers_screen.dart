import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/pending_liker.dart';
import '../../shared/formatting/date_formatting.dart';
import '../../shared/widgets/app_async_state.dart';
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
              child: likers.isEmpty
                  ? ListView(
                      children: [
                        AppAsyncState.empty(
                          message: 'No pending likes are waiting right now.',
                          onRefresh: controller.refresh,
                        ),
                      ],
                    )
                  : ListView.separated(
                      itemCount: likers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final liker = likers[index];
                        return _PendingLikerCard(liker: liker);
                      },
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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: UserAvatar(name: liker.name, radius: 22),
        title: Text(liker.age > 0 ? '${liker.name}, ${liker.age}' : liker.name),
        subtitle: Text(
          liker.likedAt == null
              ? 'They liked your profile recently.'
              : 'Liked you on ${formatDateTimeStamp(liker.likedAt!)}',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => ProfileScreen.otherUser(
                userId: liker.userId,
                userName: liker.name,
              ),
            ),
          );
        },
      ),
    );
  }
}
