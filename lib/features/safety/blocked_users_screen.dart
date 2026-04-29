import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/blocked_user_summary.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/app_overflow_menu_button.dart';
import '../../theme/app_theme.dart';
import 'blocked_users_provider.dart';

enum _BlockedUserMenuAction { unblock }

const _blockedRose = Color(0xFFB86A78);
const _blockedCoral = Color(0xFFCB816A);
const _blockedSlate = Color(0xFF596579);

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
        toolbarHeight: 44,
        title: Text(
          'Blocked users',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: blockedUsersState.when(
          data: (users) => RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppTheme.pagePadding,
                0,
                AppTheme.pagePadding,
                AppTheme.pagePadding,
              ),
              children: [
                _BlockedUsersOverviewCard(blockedCount: users.length),
                SizedBox(height: AppTheme.sectionSpacing()),
                const _BlockedUsersSectionLabel(
                  title: 'Blocked profiles',
                  accentColor: _blockedRose,
                ),
                SizedBox(height: AppTheme.listSpacing()),
                if (users.isEmpty)
                  _BlockedUsersEmptyState(onRefresh: controller.refresh)
                else
                  for (var index = 0; index < users.length; index++) ...[
                    _BlockedUserTile(
                      user: users[index],
                      isBusy: _busyUserId == users[index].userId,
                      actionsLocked: _busyUserId != null,
                      onUnblock: () => _confirmAndUnblock(users[index]),
                    ),
                    if (index != users.length - 1)
                      SizedBox(height: AppTheme.listSpacing()),
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

class _BlockedUsersOverviewCard extends StatelessWidget {
  const _BlockedUsersOverviewCard({required this.blockedCount});

  final int blockedCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark
        ? const Color(0xFFF7EEF0)
        : const Color(0xFF50323A);
    final countColor = isDark
        ? const Color(0xFFF0C6BE)
        : const Color(0xFF945846);
    final subtitleColor = isDark
        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.86)
        : const Color(0xFF726975);
    final countLabel = blockedCount == 1
        ? 'blocked profile'
        : 'blocked profiles';
    final summaryText = blockedCount == 0
        ? 'Blocked profiles will appear here if you hide someone from discovery, matches, or chat.'
        : 'Blocked profiles stay hidden from discovery, matches, and chat until you deliberately unblock them.';

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF2B2026), Color(0xFF28232B), Color(0xFF232A33)]
              : const [Color(0xFFF7E8E8), Color(0xFFF3ECEE), Color(0xFFECF1F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        prominent: true,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 15, 15, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Safety controls',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    summaryText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: subtitleColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: blockedCount),
                        duration: const Duration(milliseconds: 520),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => Text(
                          '$value',
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: countColor,
                            fontWeight: FontWeight.w800,
                            height: 0.95,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          countLabel,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: titleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            DecoratedBox(
              decoration: AppTheme.glassDecoration(
                context,
              ).copyWith(borderRadius: AppTheme.cardRadius),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.shield_outlined,
                  color: isDark ? const Color(0xFFF0C6BE) : _blockedCoral,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockedUsersEmptyState extends StatelessWidget {
  const _BlockedUsersEmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: Color.alphaBlend(
          _blockedSlate.withValues(alpha: isDark ? 0.12 : 0.04),
          Color.alphaBlend(
            _blockedRose.withValues(alpha: isDark ? 0.10 : 0.035),
            colorScheme.surfaceContainerLow,
          ),
        ),
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(compact: true),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BlockedLeadingIconChip(
              icon: Icons.shield_outlined,
              iconColor: isDark ? const Color(0xFFF0C6BE) : _blockedCoral,
              backgroundColor: _blockedCoral.withValues(
                alpha: isDark ? 0.18 : 0.12,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No blocked profiles',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Blocked profiles will appear here when you hide someone from discovery, matches, or chat.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockedUsersSectionLabel extends StatelessWidget {
  const _BlockedUsersSectionLabel({
    required this.title,
    required this.accentColor,
  });

  final String title;
  final Color accentColor;

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
              color: accentColor.withValues(alpha: 0.85),
              borderRadius: const BorderRadius.all(Radius.circular(999)),
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

class _BlockedLeadingIconChip extends StatelessWidget {
  const _BlockedLeadingIconChip({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
      ),
      child: SizedBox.square(
        dimension: 44,
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }
}

class _BlockedStatusPill extends StatelessWidget {
  const _BlockedStatusPill({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppTheme.chipRadius,
        border: Border.all(color: foregroundColor.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: foregroundColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
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
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = Color.alphaBlend(
      _blockedSlate.withValues(alpha: isDark ? 0.08 : 0.02),
      Color.alphaBlend(
        _blockedRose.withValues(alpha: isDark ? 0.16 : 0.06),
        colorScheme.surfaceContainerLow,
      ),
    );
    final accentColor = isDark
        ? const Color(0xFFE2AAB2)
        : const Color(0xFFB86A78);
    final iconColor = isDark ? const Color(0xFFF0C6BE) : _blockedCoral;
    final statusBackgroundColor = _blockedRose.withValues(
      alpha: isDark ? 0.20 : 0.10,
    );
    final statusForegroundColor = isDark
        ? const Color(0xFFF2C4CC)
        : _blockedRose;

    return Material(
      color: Colors.transparent,
      borderRadius: AppTheme.panelRadius,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: AppTheme.surfaceDecoration(context, color: surfaceColor),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.84),
                    borderRadius: const BorderRadius.all(Radius.circular(999)),
                  ),
                ),
                const SizedBox(width: 12),
                _BlockedLeadingIconChip(
                  icon: Icons.block_rounded,
                  iconColor: iconColor,
                  backgroundColor: _blockedCoral.withValues(
                    alpha: isDark ? 0.16 : 0.11,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.08,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Hidden from discovery, matches, and chat while blocked.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _BlockedStatusPill(
                        icon: Icons.shield_outlined,
                        label: user.statusLabel,
                        backgroundColor: statusBackgroundColor,
                        foregroundColor: statusForegroundColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                isBusy
                    ? SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            statusForegroundColor,
                          ),
                        ),
                      )
                    : actionsLocked
                    ? IconButton(
                        onPressed: null,
                        tooltip: 'Blocked user options unavailable',
                        icon: const Icon(Icons.more_vert),
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
        ),
      ),
    );
  }
}
