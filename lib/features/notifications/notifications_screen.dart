import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/conversation_summary.dart';
import '../../models/notification_item.dart';
import '../../models/user_summary.dart';
import '../../shared/formatting/date_formatting.dart';
import '../../shared/formatting/display_text.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/section_intro_card.dart';
import '../../theme/app_theme.dart';
import '../auth/selected_user_provider.dart';
import '../chat/conversation_thread_screen.dart';
import '../profile/profile_screen.dart';
import 'notifications_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key, this.now});

  final DateTime? now;

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
    final referenceTime = widget.now ?? DateTime.now();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
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
                  _NotificationsIntroCard(
                    totalCount: notifications.length,
                    unreadCount: unreadCount,
                    unreadOnly: unreadOnly,
                    markingAllRead: _markingAllRead,
                    onRefresh: controller.refresh,
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
                  else
                    ..._buildNotificationSections(
                      notifications: notifications,
                      referenceTime: referenceTime,
                      busyNotificationId: _busyNotificationId,
                      onMarkRead: _handleMarkRead,
                      onOpenRoute: _handleOpenRoute,
                    ),
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

  Future<void> _handleOpenRoute(NotificationItem item) async {
    final route = item.safeRoute;
    if (route == null) {
      return;
    }

    final currentUser = await ref.read(selectedUserProvider.future);
    if (!mounted) {
      return;
    }
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a dev user first.')),
      );
      return;
    }

    switch (route.destination) {
      case NotificationDestination.chatThread:
        _openChatThread(context, currentUser, item, route);
        return;
      case NotificationDestination.profile:
        _openProfile(context, item, route);
        return;
    }
  }

  void _openChatThread(
    BuildContext context,
    UserSummary currentUser,
    NotificationItem item,
    NotificationRoute route,
  ) {
    final conversationId = route.data['conversationId']!;
    final otherUserId =
        route.data['otherUserId'] ??
        route.data['senderId'] ??
        route.data['accepterUserId'] ??
        '';

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ConversationThreadScreen(
          currentUser: currentUser,
          conversation: ConversationSummary(
            id: conversationId,
            otherUserId: otherUserId,
            otherUserName: _routePersonName(item),
            messageCount: 0,
            lastMessageAt:
                item.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          ),
        ),
      ),
    );
  }

  void _openProfile(
    BuildContext context,
    NotificationItem item,
    NotificationRoute route,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProfileScreen.otherUser(
          userId: route.data['fromUserId']!,
          userName: _routePersonName(item),
        ),
      ),
    );
  }
}

List<Widget> _buildNotificationSections({
  required List<NotificationItem> notifications,
  required DateTime referenceTime,
  required String? busyNotificationId,
  required ValueChanged<NotificationItem> onMarkRead,
  required ValueChanged<NotificationItem> onOpenRoute,
}) {
  final groups = <String, List<NotificationItem>>{
    'Today': <NotificationItem>[],
    'Yesterday': <NotificationItem>[],
    'Earlier': <NotificationItem>[],
  };

  for (final item in notifications) {
    groups[_notificationGroupLabel(item.createdAt, now: referenceTime)]!.add(
      item,
    );
  }

  final widgets = <Widget>[];
  for (final entry in groups.entries) {
    if (entry.value.isEmpty) {
      continue;
    }

    if (widgets.isNotEmpty) {
      widgets.add(SizedBox(height: AppTheme.sectionSpacing(compact: true)));
    }
    widgets.add(_NotificationSectionHeader(label: entry.key));
    widgets.add(SizedBox(height: AppTheme.listSpacing(compact: true)));

    for (var index = 0; index < entry.value.length; index++) {
      final item = entry.value[index];
      widgets.add(
        _NotificationTile(
          item: item,
          referenceTime: referenceTime,
          isBusy: busyNotificationId == item.id,
          onMarkRead: item.isRead ? null : () => onMarkRead(item),
          onOpenRoute: item.safeRoute == null ? null : () => onOpenRoute(item),
        ),
      );
      if (index != entry.value.length - 1) {
        widgets.add(SizedBox(height: AppTheme.listSpacing(compact: true)));
      }
    }
  }

  return widgets;
}

String _notificationGroupLabel(DateTime? createdAt, {required DateTime now}) {
  if (createdAt == null) {
    return 'Earlier';
  }

  final local = createdAt.toLocal();
  final current = now.toLocal();
  final today = DateTime(current.year, current.month, current.day);
  final eventDate = DateTime(local.year, local.month, local.day);
  final calendarDays = today.difference(eventDate).inDays;

  if (calendarDays <= 0) {
    return 'Today';
  }
  if (calendarDays == 1) {
    return 'Yesterday';
  }
  return 'Earlier';
}

class _NotificationSectionHeader extends StatelessWidget {
  const _NotificationSectionHeader({required this.label});

  final String label;

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
              borderRadius: const BorderRadius.all(Radius.circular(999)),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
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

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.referenceTime,
    required this.isBusy,
    required this.onMarkRead,
    required this.onOpenRoute,
  });

  final NotificationItem item;
  final DateTime referenceTime;
  final bool isBusy;
  final VoidCallback? onMarkRead;
  final VoidCallback? onOpenRoute;

  @override
  Widget build(BuildContext context) {
    final createdAt = item.createdAt;
    final theme = Theme.of(context);
    final unread = !item.isRead;
    final colorScheme = theme.colorScheme;
    final spec = _NotificationSpec.forType(item.type);
    final message = item.message.isEmpty
        ? 'No details provided.'
        : item.message;
    final route = item.safeRoute;
    final timestamp = createdAt == null
        ? 'Unknown time'
        : _formatFriendlyNotificationTimestamp(createdAt, now: referenceTime);
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: unread ? FontWeight.w800 : FontWeight.w700,
    );
    final subtitleStyle = theme.textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurfaceVariant,
      height: 1.36,
    );
    final surfaceColor = unread
        ? Color.alphaBlend(
            spec.color.withValues(alpha: 0.04),
            colorScheme.surfaceContainerLow,
          )
        : colorScheme.surfaceContainerLow;

    return Material(
      color: Colors.transparent,
      borderRadius: AppTheme.panelRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenRoute == null ? null : () => onOpenRoute!(),
        child: Ink(
          decoration: AppTheme.surfaceDecoration(context, color: surfaceColor),
          child: Padding(
            padding: AppTheme.sectionPadding(compact: true),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (unread) ...[
                    Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: spec.color.withValues(alpha: 0.70),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _NotificationIconChip(spec: spec, unread: unread),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: subtitleStyle,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: spec.color.withValues(alpha: 0.10),
                                border: Border.all(
                                  color: spec.color.withValues(alpha: 0.12),
                                ),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(999),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(7, 3, 7, 3),
                                child: Text(
                                  formatDisplayLabel(item.type),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: spec.color,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                timestamp,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (route != null) ...[
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (unread) ...[
                    const SizedBox(width: 2),
                    IconButton(
                      tooltip: isBusy ? 'Marking read…' : 'Mark read',
                      onPressed: isBusy ? null : onMarkRead,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(
                        width: 32,
                        height: 32,
                      ),
                      style: ButtonStyle(
                        backgroundColor: const WidgetStatePropertyAll(
                          Colors.transparent,
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith((
                          states,
                        ) {
                          if (states.contains(WidgetState.disabled)) {
                            return spec.color.withValues(alpha: 0.38);
                          }

                          return spec.color;
                        }),
                        overlayColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.pressed) ||
                              states.contains(WidgetState.hovered) ||
                              states.contains(WidgetState.focused)) {
                            return spec.color.withValues(alpha: 0.10);
                          }

                          return Colors.transparent;
                        }),
                        shape: const WidgetStatePropertyAll(CircleBorder()),
                      ),
                      icon: isBusy
                          ? SizedBox.square(
                              dimension: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  spec.color,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.done_rounded,
                              size: 18,
                              color: spec.color,
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationsIntroCard extends StatelessWidget {
  const _NotificationsIntroCard({
    required this.totalCount,
    required this.unreadCount,
    required this.unreadOnly,
    required this.markingAllRead,
    required this.onRefresh,
    required this.onUnreadOnlyChanged,
    required this.onMarkAllRead,
  });

  final int totalCount;
  final int unreadCount;
  final bool unreadOnly;
  final bool markingAllRead;
  final Future<void> Function() onRefresh;
  final ValueChanged<bool> onUnreadOnlyChanged;
  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final description = unreadCount == 0
        ? 'All caught up'
        : '$unreadCount unread • $totalCount total';
    final buttonDisabled = unreadCount == 0 || markingAllRead;

    return SectionIntroCard(
      icon: Icons.mark_chat_unread_rounded,
      title: 'Notifications',
      description: description,
      iconBackgroundColor: Color.alphaBlend(
        colorScheme.primary.withValues(alpha: 0.12),
        colorScheme.surfaceContainerHighest,
      ),
      iconColor: colorScheme.primary,
      trailing: IconButton(
        tooltip: 'Refresh',
        onPressed: onRefresh,
        iconSize: 22,
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
        ),
        icon: Icon(
          Icons.sync_rounded,
          color: colorScheme.onSurfaceVariant,
          size: 22,
        ),
      ),
      badges: [
        FilterChip(
          selected: unreadOnly,
          showCheckmark: false,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.18)),
          selectedColor: colorScheme.primaryContainer,
          backgroundColor: colorScheme.surface,
          shape: const StadiumBorder(),
          labelStyle: theme.textTheme.labelLarge?.copyWith(
            color: unreadOnly
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface,
          ),
          onSelected: onUnreadOnlyChanged,
          avatar: Icon(
            unreadOnly ? Icons.mark_email_unread_rounded : Icons.drafts_rounded,
            size: 18,
            color: unreadOnly
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
          label: const Text('Unread only'),
        ),
        FilledButton.tonalIcon(
          onPressed: buttonDisabled ? null : onMarkAllRead,
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: const RoundedRectangleBorder(
              borderRadius: AppTheme.chipRadius,
            ),
          ),
          icon: markingAllRead
              ? SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.onSecondaryContainer,
                    ),
                  ),
                )
              : const Icon(Icons.done_all_rounded, size: 18),
          label: const Text('Mark all read'),
        ),
      ],
    );
  }
}

class _NotificationIconChip extends StatelessWidget {
  const _NotificationIconChip({required this.spec, required this.unread});

  final _NotificationSpec spec;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: spec.color.withValues(alpha: 0.16),
            borderRadius: const BorderRadius.all(Radius.circular(16.8)),
          ),
          child: const SizedBox.square(dimension: 40),
        ),
        Positioned.fill(
          child: Center(child: Icon(spec.icon, color: spec.color, size: 22.4)),
        ),
        if (unread)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: spec.color,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.surface, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationSpec {
  const _NotificationSpec({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  static _NotificationSpec forType(String type) {
    switch (type.toUpperCase()) {
      case 'MATCH_FOUND':
        return const _NotificationSpec(
          color: Color(0xFF7C4DFF),
          icon: Icons.favorite_rounded,
        );
      case 'NEW_MESSAGE':
        return const _NotificationSpec(
          color: Color(0xFF009688),
          icon: Icons.chat_bubble_rounded,
        );
      case 'FRIEND_REQUEST':
        return const _NotificationSpec(
          color: Color(0xFF2E9D57),
          icon: Icons.person_add_rounded,
        );
      case 'FRIEND_REQUEST_ACCEPTED':
        return const _NotificationSpec(
          color: Color(0xFF5B6EE1),
          icon: Icons.people_rounded,
        );
      case 'GRACEFUL_EXIT':
        return const _NotificationSpec(
          color: Color(0xFF596579),
          icon: Icons.shield_rounded,
        );
      default:
        return const _NotificationSpec(
          color: Color(0xFF188DC8),
          icon: Icons.notifications_rounded,
        );
    }
  }
}

String _routePersonName(NotificationItem item) {
  final title = item.title.trim();
  if (title.isNotEmpty) {
    return title;
  }

  return 'Profile';
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
    return '$calendarDays days ago';
  }

  return formatShortDate(local);
}
