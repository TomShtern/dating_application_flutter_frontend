import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/blocked_user_summary.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/section_intro_card.dart';
import '../../shared/widgets/shell_hero.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../theme/app_theme.dart';
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
        child: blockedUsersState.when(
          data: (users) => RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppTheme.screenPadding(),
              children: [
                ShellHero(
                  eyebrowLabel: 'Safety controls',
                  eyebrowIcon: Icons.block_outlined,
                  title: 'Blocked users',
                  description:
                      'Review the profiles you have removed from discovery, matches, and chat. Unblock anyone here when you are ready to reopen that door.',
                  badges: [
                    ShellHeroPill(
                      icon: Icons.block_rounded,
                      label: users.isEmpty
                          ? 'No blocked profiles'
                          : '${users.length} blocked',
                    ),
                    const ShellHeroPill(
                      icon: Icons.refresh_rounded,
                      label: 'Pull to refresh',
                    ),
                  ],
                ),
                SizedBox(height: AppTheme.sectionSpacing()),
                const SectionIntroCard(
                  icon: Icons.shield_outlined,
                  title: 'What happens here',
                  description:
                      'Blocked profiles stay out of your activity surfaces until you unblock them. This list is the quickest place to reverse that choice.',
                ),
                SizedBox(height: AppTheme.sectionSpacing()),
                if (users.isEmpty)
                  const AppAsyncState.empty(
                    message: 'You have not blocked anyone right now.',
                  )
                else ...[
                  for (var index = 0; index < users.length; index++) ...[
                    _BlockedUserTile(
                      user: users[index],
                      isBusy: _busyUserId == users[index].userId,
                      onUnblock: () => _handleUnblock(users[index]),
                    ),
                    if (index != users.length - 1)
                      SizedBox(height: AppTheme.listSpacing()),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: colorScheme.surface.withValues(alpha: 0.9),
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAvatar(name: user.name, radius: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(user.statusLabel, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text(
                    'You will stop seeing each other in browse, matches, and chat until this block is removed.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonal(
              onPressed: isBusy ? null : onUnblock,
              child: Text(isBusy ? 'Working…' : 'Unblock'),
            ),
          ],
        ),
      ),
    );
  }
}
