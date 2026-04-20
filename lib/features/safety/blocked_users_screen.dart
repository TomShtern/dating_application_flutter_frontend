import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/blocked_user_summary.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/user_avatar.dart';
import 'blocked_users_provider.dart';

class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
  String? _busyUserId;

  @override
  Widget build(BuildContext context) {
    final blockedUsersState = ref.watch(blockedUsersProvider);
    final controller = ref.read(blockedUsersControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked users'),
        actions: [
          IconButton(
            tooltip: 'Refresh blocked users',
            onPressed: controller.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: blockedUsersState.when(
            data: (users) => RefreshIndicator(
              onRefresh: controller.refresh,
              child: users.isEmpty
                  ? ListView(
                      children: const [
                        // The empty state stays simple here because the
                        // surrounding RefreshIndicator already exposes a reload.
                        AppAsyncState.empty(
                          message: 'You have not blocked anyone right now.',
                        ),
                      ],
                    )
                  : ListView.separated(
                      itemCount: users.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return _BlockedUserTile(
                          user: user,
                          isBusy: _busyUserId == user.userId,
                          onUnblock: () => _handleUnblock(user),
                        );
                      },
                    ),
            ),
            loading: () =>
                const AppAsyncState.loading(message: 'Loading blocked users…'),
            error: (error, _) => AppAsyncState.error(
              message: error is ApiError
                  ? error.message
                  : 'Unable to load blocked users right now.',
              onRetry: controller.refresh,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleUnblock(BlockedUserSummary user) async {
    setState(() {
      _busyUserId = user.userId;
    });

    try {
      final message = await ref
          .read(blockedUsersControllerProvider)
          .unblockUser(user.userId);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } on ApiError catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to unblock this user right now.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyUserId = null;
        });
      }
    }
  }
}

class _BlockedUserTile extends StatelessWidget {
  const _BlockedUserTile({
    required this.user,
    required this.isBusy,
    required this.onUnblock,
  });

  final BlockedUserSummary user;
  final bool isBusy;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: UserAvatar(name: user.name, radius: 22),
        title: Text(user.name),
        subtitle: Text(user.statusLabel),
        trailing: FilledButton.tonal(
          onPressed: isBusy ? null : onUnblock,
          child: Text(isBusy ? 'Working…' : 'Unblock'),
        ),
      ),
    );
  }
}
