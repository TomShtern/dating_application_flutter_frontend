import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/blocked_user_summary.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/app_overflow_menu_button.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../theme/app_theme.dart';
import 'blocked_users_provider.dart';

enum _BlockedUserMenuAction { unblock }

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
        child: blockedUsersState.when(
          data: (users) => RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppTheme.screenPadding(),
              children: [
                _BlockedUsersSummaryCard(blockedCount: users.length),
                SizedBox(height: AppTheme.sectionSpacing(compact: true)),
                if (users.isEmpty)
                  const AppAsyncState.empty(
                    message: 'You have not blocked anyone right now.',
                  )
                else ...[
                  for (var index = 0; index < users.length; index++) ...[
                    _BlockedUserTile(
                      user: users[index],
                      isBusy: _busyUserId == users[index].userId,
                      onUnblock: () => _confirmAndUnblock(users[index]),
                    ),
                    if (index != users.length - 1)
                      SizedBox(height: AppTheme.listSpacing(compact: true)),
                  ],
                ],
              ],
            ),
          ),
          loading: () => Padding(
            padding: AppTheme.screenPadding(),
            child: const AppAsyncState.loading(
              message: 'Loading blocked users…',
            ),
          ),
          error: (error, _) => Padding(
            padding: AppTheme.screenPadding(),
            child: AppAsyncState.error(
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

  Future<void> _confirmAndUnblock(BlockedUserSummary user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unblock ${user.name}?'),
        content: const Text(
          'This lets this profile appear again in app surfaces that the backend returns.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _handleUnblock(user);
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

class _BlockedUsersSummaryCard extends StatelessWidget {
  const _BlockedUsersSummaryCard({required this.blockedCount});

  final int blockedCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final countLabel = blockedCount == 1
        ? '1 blocked profile'
        : '$blockedCount blocked profiles';

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
                child: Icon(Icons.block_outlined, color: colorScheme.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Safety stays on', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Hidden from discovery, matches, and chat until you unblock them.',
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: colorScheme.surface.withValues(alpha: 0.9),
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(compact: true),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            UserAvatar(name: user.name, radius: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: theme.textTheme.titleMedium),
                  Text(
                    user.statusLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            isBusy
                ? const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : AppOverflowMenuButton<_BlockedUserMenuAction>(
                    tooltip: 'Blocked user options',
                    items: const [
                      PopupMenuItem<_BlockedUserMenuAction>(
                        value: _BlockedUserMenuAction.unblock,
                        child: Text('Unblock'),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == _BlockedUserMenuAction.unblock) {
                        onUnblock();
                      }
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
