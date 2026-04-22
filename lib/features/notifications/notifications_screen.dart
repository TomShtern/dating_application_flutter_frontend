import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../shared/formatting/display_text.dart';
import '../../models/notification_item.dart';
import '../../shared/formatting/date_formatting.dart';
import '../../shared/widgets/app_async_state.dart';
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
                  _NotificationsControlsCard(
                    totalCount: notifications.length,
                    unreadCount: unreadCount,
                    unreadOnly: unreadOnly,
                    markingAllRead: _markingAllRead,
                    canMarkAllRead: unreadCount > 0,
                    onUnreadOnlyChanged: controller.setUnreadOnly,
                    onMarkAllRead: _handleMarkAllRead,
                  ),
                  SizedBox(height: AppTheme.sectionSpacing(compact: true)),
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
        color:
            (unread
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerLow)
                .withValues(alpha: unread ? 0.32 : 0.92),
        prominent: unread,
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
                            fontWeight: unread
                                ? FontWeight.w800
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _NotificationStatusBadge(unread: unread),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(message, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  Text(
                    createdAt == null
                        ? formatDisplayLabel(item.type)
                        : '${formatDisplayLabel(item.type)} • ${_formatFriendlyNotificationTimestamp(createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
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
    required this.totalCount,
    required this.unreadCount,
    required this.unreadOnly,
    required this.markingAllRead,
    required this.canMarkAllRead,
    required this.onUnreadOnlyChanged,
    required this.onMarkAllRead,
  });

  final int totalCount;
  final int unreadCount;
  final bool unreadOnly;
  final bool markingAllRead;
  final bool canMarkAllRead;
  final ValueChanged<bool> onUnreadOnlyChanged;
  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final totalLabel = totalCount == 1
        ? '1 notification'
        : '$totalCount notifications';
    final unreadLabel = unreadCount == 1 ? '1 unread' : '$unreadCount unread';

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: colorScheme.surface.withValues(alpha: 0.9),
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(compact: true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(totalLabel, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              unreadLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilterChip(
                  selected: unreadOnly,
                  onSelected: onUnreadOnlyChanged,
                  label: const Text('Unread only'),
                  avatar: Icon(
                    unreadOnly
                        ? Icons.mark_email_unread_outlined
                        : Icons.inbox_outlined,
                    size: 18,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: !canMarkAllRead || markingAllRead
                      ? null
                      : onMarkAllRead,
                  icon: const Icon(Icons.done_all_rounded),
                  label: Text(markingAllRead ? 'Working…' : 'Mark all read'),
                ),
              ],
            ),
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
    final icon = unread ? Icons.mark_email_unread_outlined : Icons.done_rounded;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: unread
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest,
        borderRadius: AppTheme.chipRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: unread ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
            const SizedBox(width: 6),
            Text(
              unread ? 'Unread' : 'Read',
              style: theme.textTheme.labelLarge?.copyWith(
                color: unread ? colorScheme.onPrimary : colorScheme.onSurface,
              ),
            ),
          ],
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
  // Calendar-based comparison to avoid cross-boundary mislabelling.
  final today = DateTime(current.year, current.month, current.day);
  final eventDate = DateTime(local.year, local.month, local.day);
  final calendarDays = today.difference(eventDate).inDays;

  if (calendarDays < 1) {
    return '${difference.inHours}h ago';
  }
  if (calendarDays == 1) {
    return 'Yesterday';
  }
  if (calendarDays < 7) {
    return '$calendarDays day${calendarDays == 1 ? '' : 's'} ago';
  }

  return formatShortDate(local);
}
