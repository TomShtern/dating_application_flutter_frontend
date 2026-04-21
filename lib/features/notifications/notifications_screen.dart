import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../shared/formatting/display_text.dart';
import '../../models/notification_item.dart';
import '../../shared/formatting/date_formatting.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/section_intro_card.dart';
import '../../shared/widgets/shell_hero.dart';
import '../../theme/app_theme.dart';
import 'notifications_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _markingAllRead = false;
  String? _busyNotificationId;

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(notificationsControllerProvider);
    final unreadOnly = ref.watch(notificationsUnreadOnlyProvider);
    final notificationsState = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Refresh notifications',
            onPressed: controller.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: notificationsState.when(
          data: (notifications) {
            final unreadCount = notifications
                .where((notification) => !notification.isRead)
                .length;

            return RefreshIndicator(
              onRefresh: controller.refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppTheme.screenPadding(),
                children: [
                  ShellHero(
                    eyebrowLabel: 'Activity',
                    eyebrowIcon: Icons.notifications_active_outlined,
                    title: 'Notification center',
                    description:
                        'Unread items stay highlighted so it is obvious what still needs attention, and friendly timestamps help you triage quickly.',
                    badges: [
                      ShellHeroPill(
                        icon: Icons.notifications_none_rounded,
                        label: '${notifications.length} total',
                      ),
                      ShellHeroPill(
                        icon: Icons.mark_email_unread_outlined,
                        label: '$unreadCount unread',
                      ),
                      ShellHeroPill(
                        icon: unreadOnly
                            ? Icons.filter_alt_rounded
                            : Icons.inbox_outlined,
                        label: unreadOnly
                            ? 'Showing unread only'
                            : 'Showing all activity',
                      ),
                    ],
                  ),
                  SizedBox(height: AppTheme.sectionSpacing()),
                  const SectionIntroCard(
                    icon: Icons.schedule_rounded,
                    title: 'Read state and timing',
                    description:
                        'Unread notifications stay visually elevated, while each item shows a friendlier relative timestamp alongside its exact date.',
                  ),
                  SizedBox(height: AppTheme.sectionSpacing()),
                  _NotificationsControlsCard(
                    unreadOnly: unreadOnly,
                    markingAllRead: _markingAllRead,
                    canMarkAllRead: unreadCount > 0,
                    onUnreadOnlyChanged: controller.setUnreadOnly,
                    onMarkAllRead: _handleMarkAllRead,
                  ),
                  SizedBox(height: AppTheme.sectionSpacing()),
                  if (notifications.isEmpty)
                    AppAsyncState.empty(
                      message: unreadOnly
                          ? 'No unread notifications right now.'
                          : 'No notifications yet.',
                      onRefresh: controller.refresh,
                    )
                  else ...[
                    for (
                      var index = 0;
                      index < notifications.length;
                      index++
                    ) ...[
                      _NotificationTile(
                        item: notifications[index],
                        isBusy: _busyNotificationId == notifications[index].id,
                        onMarkRead: notifications[index].isRead
                            ? null
                            : () => _handleMarkRead(notifications[index]),
                      ),
                      if (index != notifications.length - 1)
                        SizedBox(height: AppTheme.listSpacing()),
                    ],
                  ],
                ],
              ),
            );
          },
          loading: () => Padding(
            padding: AppTheme.screenPadding(),
            child: const AppAsyncState.loading(
              message: 'Loading notifications…',
            ),
          ),
          error: (error, _) => Padding(
            padding: AppTheme.screenPadding(),
            child: AppAsyncState.error(
              message: error is ApiError
                  ? error.message
                  : 'Unable to load notifications right now.',
              onRetry: controller.refresh,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleMarkAllRead() async {
    setState(() {
      _markingAllRead = true;
    });

    try {
      final updatedCount = await ref
          .read(notificationsControllerProvider)
          .markAllRead();
      if (!mounted) {
        return;
      }
      final message = updatedCount == 1
          ? '1 notification marked as read.'
          : '$updatedCount notifications marked as read.';
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
    } finally {
      if (mounted) {
        setState(() {
          _markingAllRead = false;
        });
      }
    }
  }

  Future<void> _handleMarkRead(NotificationItem item) async {
    setState(() {
      _busyNotificationId = item.id;
    });

    try {
      await ref.read(notificationsControllerProvider).markRead(item.id);
    } on ApiError catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _busyNotificationId = null;
        });
      }
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.isBusy,
    required this.onMarkRead,
  });

  final NotificationItem item;
  final bool isBusy;
  final VoidCallback? onMarkRead;

  @override
  Widget build(BuildContext context) {
    final createdAt = item.createdAt;
    final theme = Theme.of(context);
    final unread = !item.isRead;
    final colorScheme = theme.colorScheme;
    final message = item.message.isEmpty
        ? 'No details provided.'
        : item.message;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: (unread ? colorScheme.primaryContainer : colorScheme.surface)
            .withValues(alpha: unread ? 0.36 : 0.9),
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: unread
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.all(Radius.circular(20)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  _iconForType(item.type),
                  color: unread ? colorScheme.onPrimary : colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: unread ? FontWeight.w800 : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _NotificationStatusBadge(unread: unread),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(message, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _NotificationMetaChip(
                        icon: Icons.sell_outlined,
                        label: formatDisplayLabel(item.type),
                      ),
                      if (createdAt != null)
                        _NotificationMetaChip(
                          icon: Icons.schedule_rounded,
                          label: _formatFriendlyNotificationTimestamp(
                            createdAt,
                          ),
                        ),
                      if (createdAt != null)
                        _NotificationMetaChip(
                          icon: Icons.event_outlined,
                          label: formatDateTimeStamp(createdAt),
                        ),
                    ],
                  ),
                  if (unread) ...[
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.tonalIcon(
                        onPressed: isBusy ? null : onMarkRead,
                        icon: const Icon(Icons.done_rounded),
                        label: Text(isBusy ? 'Working…' : 'Mark read'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsControlsCard extends StatelessWidget {
  const _NotificationsControlsCard({
    required this.unreadOnly,
    required this.markingAllRead,
    required this.canMarkAllRead,
    required this.onUnreadOnlyChanged,
    required this.onMarkAllRead,
  });

  final bool unreadOnly;
  final bool markingAllRead;
  final bool canMarkAllRead;
  final ValueChanged<bool> onUnreadOnlyChanged;
  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: colorScheme.surface.withValues(alpha: 0.9),
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(),
        child: Column(
          children: [
            SwitchListTile.adaptive(
              value: unreadOnly,
              contentPadding: EdgeInsets.zero,
              title: const Text('Unread only'),
              subtitle: const Text(
                'Focus on activity you have not cleared yet.',
              ),
              onChanged: onUnreadOnlyChanged,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: !canMarkAllRead || markingAllRead
                    ? null
                    : onMarkAllRead,
                icon: const Icon(Icons.done_all_rounded),
                label: Text(markingAllRead ? 'Working…' : 'Mark all read'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationMetaChip extends StatelessWidget {
  const _NotificationMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.75),
        borderRadius: AppTheme.chipRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(label, style: theme.textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _NotificationStatusBadge extends StatelessWidget {
  const _NotificationStatusBadge({required this.unread});

  final bool unread;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: unread
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest,
        borderRadius: AppTheme.chipRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          unread ? 'Unread' : 'Read',
          style: theme.textTheme.labelLarge?.copyWith(
            color: unread ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

IconData _iconForType(String type) {
  switch (type.toUpperCase()) {
    case 'MATCH':
      return Icons.favorite_rounded;
    case 'MESSAGE':
      return Icons.chat_bubble_rounded;
    case 'LIKE':
      return Icons.thumb_up_alt_rounded;
    case 'FRIEND_REQUEST':
      return Icons.people_alt_rounded;
    case 'MODERATION':
      return Icons.shield_outlined;
    default:
      return Icons.notifications_none_rounded;
  }
}

String _formatFriendlyNotificationTimestamp(DateTime value, {DateTime? now}) {
  final local = value.toLocal();
  final current = (now ?? DateTime.now()).toLocal();
  final difference = current.difference(local);

  if (difference.isNegative || difference.inMinutes < 1) {
    return 'Just now';
  }
  if (difference.inHours < 1) {
    return '${difference.inMinutes}m ago';
  }
  if (difference.inDays < 1) {
    return '${difference.inHours}h ago';
  }
  if (difference.inDays == 1) {
    return 'Yesterday';
  }
  if (difference.inDays < 7) {
    return '${difference.inDays}d ago';
  }

  return formatShortDate(local);
}
