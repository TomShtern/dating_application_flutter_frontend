import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/notification_item.dart';
import '../../shared/formatting/date_formatting.dart';
import '../../shared/widgets/app_async_state.dart';
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        value: unreadOnly,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Unread only'),
                        subtitle: const Text(
                          'Focus on activity you have not cleared yet.',
                        ),
                        onChanged: controller.setUnreadOnly,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.tonalIcon(
                          onPressed: _markingAllRead
                              ? null
                              : _handleMarkAllRead,
                          icon: const Icon(Icons.done_all_rounded),
                          label: Text(
                            _markingAllRead ? 'Working…' : 'Mark all read',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: notificationsState.when(
                  data: (notifications) => RefreshIndicator(
                    onRefresh: controller.refresh,
                    child: notifications.isEmpty
                        ? ListView(
                            children: [
                              AppAsyncState.empty(
                                message: unreadOnly
                                    ? 'No unread notifications right now.'
                                    : 'No notifications yet.',
                                onRefresh: controller.refresh,
                              ),
                            ],
                          )
                        : ListView.separated(
                            itemCount: notifications.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = notifications[index];
                              return _NotificationTile(
                                item: item,
                                isBusy: _busyNotificationId == item.id,
                                onTap: item.isRead
                                    ? null
                                    : () => _handleMarkRead(item),
                              );
                            },
                          ),
                  ),
                  loading: () => const AppAsyncState.loading(
                    message: 'Loading notifications…',
                  ),
                  error: (error, _) => AppAsyncState.error(
                    message: error is ApiError
                        ? error.message
                        : 'Unable to load notifications right now.',
                    onRetry: controller.refresh,
                  ),
                ),
              ),
            ],
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
    required this.onTap,
  });

  final NotificationItem item;
  final bool isBusy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final createdAt = item.createdAt;
    final theme = Theme.of(context);
    final unread = !item.isRead;

    return Card(
      color: unread
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      child: ListTile(
        leading: CircleAvatar(child: Icon(_iconForType(item.type))),
        title: Text(item.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.message.isEmpty ? 'No details provided.' : item.message),
            if (createdAt != null) ...[
              const SizedBox(height: 6),
              Text(
                formatDateTimeStamp(createdAt),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
        trailing: unread
            ? FilledButton.tonal(
                onPressed: isBusy ? null : onTap,
                child: Text(isBusy ? '…' : 'Read'),
              )
            : const Icon(Icons.done_rounded),
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
