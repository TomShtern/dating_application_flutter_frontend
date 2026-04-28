import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/blocked_user_summary.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/app_overflow_menu_button.dart';
import '../../shared/widgets/compact_context_strip.dart';
import '../../shared/widgets/compact_summary_header.dart';
import '../../shared/widgets/section_intro_card.dart';
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Blocked users',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: blockedUsersState.when(
          data: (users) => RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppTheme.screenPadding(),
              children: [
                _BlockedUsersIntroCard(blockedCount: users.length),
                SizedBox(height: AppTheme.sectionSpacing(compact: true)),
                if (users.isEmpty)
                  AppAsyncState.empty(
                    message:
                        'No blocked profiles right now. If someone crosses a line, you can block them from their profile.',
                    onRefresh: controller.refresh,
                  )
                else ...[
                  const _BlockedUsersSectionLabel(title: 'Blocked profiles'),
                  SizedBox(height: AppTheme.listSpacing(compact: true)),
                  for (var index = 0; index < users.length; index++) ...[
                    _BlockedUserTile(
                      user: users[index],
                      isBusy: _busyUserId == users[index].userId,
                      actionsLocked: _busyUserId != null,
                      onUnblock: () => _confirmAndUnblock(users[index]),
                    ),
                    if (index != users.length - 1)
                      SizedBox(height: AppTheme.listSpacing(compact: true)),
                  ],
                  if (users.length <= 2) ...[
                    SizedBox(height: AppTheme.sectionSpacing(compact: true)),
                    const _BlockedUsersShortListCard(),
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
    if (_busyUserId != null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unblock ${user.name}?'),
        content: const Text(
          'They will be able to see your profile and appear in your searches again.',
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

class _BlockedUsersIntroCard extends StatelessWidget {
  const _BlockedUsersIntroCard({required this.blockedCount});

  final int blockedCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final countLabel = blockedCount == 1
        ? '1 blocked profile'
        : '$blockedCount blocked profiles';

    return SectionIntroCard(
      icon: Icons.shield_outlined,
      title: 'Safety controls',
      description:
          'Hidden from discovery, matches, and chat until you unblock them.',
      iconBackgroundColor: colorScheme.errorContainer,
      iconColor: colorScheme.onErrorContainer,
      trailing: DecoratedBox(
        decoration: AppTheme.glassDecoration(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            countLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _BlockedUsersShortListCard extends StatelessWidget {
  const _BlockedUsersShortListCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: colorScheme.surfaceContainerLow,
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(compact: true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BlockedUsersSectionLabel(title: 'What unblocking changes'),
            SizedBox(height: AppTheme.listSpacing(compact: true)),
            const _BlockedUsersBullet(
              icon: Icons.visibility_outlined,
              text: 'They can appear in discovery, matches, and chat again.',
            ),
            SizedBox(height: AppTheme.listSpacing(compact: true)),
            const _BlockedUsersBullet(
              icon: Icons.more_horiz_rounded,
              text:
                  'Use the menu on each row when you are ready to let them back in.',
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockedUsersSectionLabel extends StatelessWidget {
  const _BlockedUsersSectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 3,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.85),
              borderRadius: AppTheme.chipRadius,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                height: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockedUsersBullet extends StatelessWidget {
  const _BlockedUsersBullet({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            size: 16,
            color: colorScheme.primary.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _BlockedUserTile extends StatelessWidget {
  const _BlockedUserTile({
    required this.user,
    required this.isBusy,
    required this.actionsLocked,
    required this.onUnblock,
  });

  final BlockedUserSummary user;
  final bool isBusy;
  final bool actionsLocked;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      borderRadius: AppTheme.panelRadius,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: AppTheme.surfaceDecoration(
          context,
          color: colorScheme.errorContainer.withValues(alpha: 0.12),
        ),
        child: Padding(
          padding: AppTheme.sectionPadding(compact: true),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              UserAvatar(name: user.name, radius: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CompactSummaryHeader(title: user.name, dense: true),
                    const SizedBox(height: 4),
                    CompactContextStrip(
                      leadingIcon: Icons.block_outlined,
                      label: 'Blocked profile',
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
                  : actionsLocked
                  ? IconButton(
                      onPressed: null,
                      tooltip: 'Finishing unblock…',
                      icon: const Icon(Icons.more_vert),
                    )
                  : AppOverflowMenuButton<_BlockedUserMenuAction>(
                      tooltip: 'Manage block',
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
      ),
    );
  }
}
