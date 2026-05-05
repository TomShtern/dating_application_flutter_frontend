import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../api/api_error.dart';
import '../../models/conversation_summary.dart';
import '../../models/notification_item.dart';
import '../../models/user_summary.dart';
import '../../shared/formatting/date_formatting.dart';
import '../../shared/formatting/display_text.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/app_group_label.dart';
import '../../shared/widgets/app_route_header.dart';
import '../../theme/app_theme.dart';
import '../auth/selected_user_provider.dart';
import '../chat/conversation_thread_screen.dart';
import '../profile/profile_screen.dart';
import 'notification_platform_service.dart';
import 'notification_preferences.dart';
import 'notification_preferences_provider.dart';
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
  bool _requestingPermission = false;
  String? _busyNotificationId;

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(notificationsControllerProvider);
    final unreadOnly = ref.watch(notificationsUnreadOnlyProvider);
    final notificationPreferences = ref.watch(notificationPreferencesProvider);
    final permissionState = ref.watch(notificationPermissionStatusProvider);
    final notificationsState = ref.watch(notificationsProvider);
    final unreadCountState = ref.watch(notificationsUnreadCountProvider);
    final referenceTime = widget.now ?? DateTime.now();
    return Scaffold(
      body: SafeArea(
        child: notificationsState.when(
          data: (notifications) {
            final localUnreadCount = notifications
                .where((notification) => !notification.isRead)
                .length;
            final backendUnreadCount = unreadCountState.asData?.value;
            final unreadCount = backendUnreadCount ?? localUnreadCount;

            return RefreshIndicator(
              onRefresh: controller.refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppTheme.screenPadding(),
                children: [
                  const AppRouteHeader(title: 'Notifications'),
                  const SizedBox(height: 4),
                  _NotificationsIntroCard(
                    totalCount: notifications.length,
                    unreadCount: unreadCount,
                    backendUnreadCount: backendUnreadCount,
                    unreadOnly: unreadOnly,
                    markingAllRead: _markingAllRead,
                    onRefresh: controller.refresh,
                    onUnreadOnlyChanged: controller.setUnreadOnly,
                    onMarkAllRead: _handleMarkAllRead,
                  ),
                  SizedBox(height: AppTheme.sectionSpacing(compact: true)),
                  _NotificationDeliveryCard(
                    permissionState: permissionState,
                    unreadCountState: unreadCountState,
                    requestingPermission: _requestingPermission,
                    onRequestPermission: _handleRequestPermission,
                  ),
                  SizedBox(height: AppTheme.sectionSpacing(compact: true)),
                  _NotificationPreferencesCard(
                    preferences: notificationPreferences,
                    onCategoryChanged: _handleCategoryChanged,
                  ),
                  SizedBox(height: AppTheme.sectionSpacing(compact: true)),
                  if (notifications.isEmpty)
                    AppAsyncState.empty(
                      message: unreadOnly
                          ? 'You\'re all caught up — nothing unread.'
                          : 'You\'ll see matches, replies, and friend activity here.',
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppRouteHeader(title: 'Notifications'),
                SizedBox(height: 16),
                Expanded(
                  child: AppAsyncState.loading(
                    message: 'Loading notifications…',
                  ),
                ),
              ],
            ),
          ),
          error: (error, _) => Padding(
            padding: AppTheme.screenPadding(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppRouteHeader(title: 'Notifications'),
                const SizedBox(height: 16),
                Expanded(
                  child: AppAsyncState.error(
                    message: error is ApiError
                        ? error.message
                        : 'Unable to load notifications right now.',
                    onRetry: controller.refresh,
                  ),
                ),
              ],
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

  Future<void> _handleRequestPermission() async {
    setState(() {
      _requestingPermission = true;
    });

    try {
      await ref
          .read(notificationPlatformControllerProvider)
          .requestPermission();
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ?? 'Unable to request notifications right now.',
          ),
        ),
      );
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to request notifications: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _requestingPermission = false;
        });
      }
    }
  }

  Future<void> _handleCategoryChanged(
    NotificationPreferenceCategory category,
    bool enabled,
  ) {
    return ref
        .read(notificationPreferencesControllerProvider)
        .setCategoryEnabled(category, enabled);
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

    if (!item.isRead) {
      try {
        await ref.read(notificationsControllerProvider).markRead(item.id);
      } on ApiError {
        // Keep navigation responsive even if the read receipt fails.
      }
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
    widgets.add(
      AppGroupLabel(title: entry.key, countText: '${entry.value.length}'),
    );
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
    final surfaceColor = _notificationSurfaceColor(context, spec, unread);
    final trailing = route != null
        ? _NotificationTrailingAction(
            tooltip: 'Open notification',
            icon: Icons.arrow_forward_rounded,
            color: spec.color,
            onPressed: onOpenRoute,
          )
        : (unread && onMarkRead != null)
        ? _NotificationTrailingAction(
            tooltip: isBusy ? 'Marking read…' : 'Mark read',
            icon: Icons.done_rounded,
            color: spec.color,
            isBusy: isBusy,
            onPressed: onMarkRead,
          )
        : null;

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
                          crossAxisAlignment: CrossAxisAlignment.center,
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                child: Text(
                                  formatDisplayLabel(item.type),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: spec.color,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
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
                  if (trailing != null) ...[const SizedBox(width: 8), trailing],
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
    required this.backendUnreadCount,
    required this.unreadOnly,
    required this.markingAllRead,
    required this.onRefresh,
    required this.onUnreadOnlyChanged,
    required this.onMarkAllRead,
  });

  final int totalCount;
  final int unreadCount;
  final int? backendUnreadCount;
  final bool unreadOnly;
  final bool markingAllRead;
  final Future<void> Function() onRefresh;
  final ValueChanged<bool> onUnreadOnlyChanged;
  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final description = switch (unreadCount) {
      0 when totalCount == 0 => 'No notifications yet',
      0 => 'All caught up — $totalCount in total',
      1 => '1 unread of $totalCount',
      _ => '$unreadCount unread of $totalCount',
    };
    final buttonDisabled = unreadCount == 0 || markingAllRead;

    final introAccent = const Color(0xFF188DC8);
    final messageAccent = const Color(0xFF009688);
    final introSurface = Color.alphaBlend(
      introAccent.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.10 : 0.045,
      ),
      colorScheme.surfaceContainerLow,
    );

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(context, color: introSurface),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: introAccent.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.24 : 0.15,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.mark_chat_unread_rounded,
                      color: Color(0xFF188DC8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Notifications',
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                          if ((backendUnreadCount ?? 0) > 0)
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: introAccent.withValues(
                                  alpha: theme.brightness == Brightness.dark
                                      ? 0.24
                                      : 0.14,
                                ),
                                borderRadius: AppTheme.chipRadius,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Text(
                                  '$backendUnreadCount',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: introAccent,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(description, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: () async {
                    await onRefresh();
                  },
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
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilterChip(
                  selected: unreadOnly,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: BorderSide(
                    color: unreadOnly
                        ? introAccent.withValues(alpha: 0.24)
                        : colorScheme.outline.withValues(alpha: 0.18),
                  ),
                  selectedColor: introAccent.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.28 : 0.14,
                  ),
                  backgroundColor: colorScheme.surface.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.44 : 0.72,
                  ),
                  shape: const StadiumBorder(),
                  labelStyle: theme.textTheme.labelLarge?.copyWith(
                    color: unreadOnly ? introAccent : colorScheme.onSurface,
                  ),
                  onSelected: onUnreadOnlyChanged,
                  avatar: Icon(
                    unreadOnly
                        ? Icons.mark_email_unread_rounded
                        : Icons.drafts_rounded,
                    size: 18,
                    color: unreadOnly
                        ? introAccent
                        : colorScheme.onSurfaceVariant,
                  ),
                  label: const Text('Unread only'),
                ),
                FilledButton.tonalIcon(
                  onPressed: buttonDisabled ? null : onMarkAllRead,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: messageAccent.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.22 : 0.12,
                    ),
                    foregroundColor: messageAccent,
                    disabledBackgroundColor: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.70),
                    disabledForegroundColor: colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.58),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
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
                              messageAccent,
                            ),
                          ),
                        )
                      : const Icon(Icons.done_all_rounded, size: 18),
                  label: const Text('Mark all read'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationDeliveryCard extends StatelessWidget {
  const _NotificationDeliveryCard({
    required this.permissionState,
    required this.unreadCountState,
    required this.requestingPermission,
    required this.onRequestPermission,
  });

  final AsyncValue<NotificationPermissionStatus> permissionState;
  final AsyncValue<int> unreadCountState;
  final bool requestingPermission;
  final Future<void> Function() onRequestPermission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = const Color(0xFF188DC8);
    final surface = Color.alphaBlend(
      accent.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.12 : 0.05,
      ),
      colorScheme.surfaceContainerLow,
    );
    final NotificationPermissionStatus? permissionStatus =
        permissionState.asData?.value;
    final permissionMessage = switch (permissionStatus) {
      NotificationPermissionStatus.granted =>
        'Notifications are allowed on this device.',
      NotificationPermissionStatus.denied =>
        'Allow notifications so new matches and replies can reach you.',
      NotificationPermissionStatus.unsupported =>
        'Push permission controls are available on Android once the plugin is active.',
      null => 'Checking whether this device can receive notifications…',
    };
    final showPermissionButton =
        permissionStatus == NotificationPermissionStatus.denied;
    final badgeCountLabel = unreadCountState.when(
      data: (count) => '$count unread from backend',
      loading: () => 'Checking backend unread count…',
      error: (_, _) => 'Unread sync unavailable right now',
    );

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(context, color: surface),
      child: Padding(
        padding: AppTheme.sectionPadding(compact: true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.22 : 0.12,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.notifications_active_outlined,
                      color: Color(0xFF188DC8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Push delivery', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        permissionMessage,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showPermissionButton) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: requestingPermission ? null : onRequestPermission,
                icon: requestingPermission
                    ? SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                        ),
                      )
                    : const Icon(Icons.notifications_outlined, size: 18),
                label: const Text('Allow notifications'),
              ),
            ],
            const SizedBox(height: 14),
            _NotificationMetaRow(title: 'Badge count', value: badgeCountLabel),
            const SizedBox(height: 8),
            const _NotificationMetaRow(
              title: 'Device token',
              value:
                  'Waiting on a backend endpoint before device-token registration can start.',
            ),
            const SizedBox(height: 12),
            Text(
              'Android channels',
              style: theme.textTheme.labelLarge?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: notificationChannelDefinitions
                  .map(
                    (definition) => DecoratedBox(
                      decoration: BoxDecoration(
                        color: accent.withValues(
                          alpha: theme.brightness == Brightness.dark
                              ? 0.18
                              : 0.08,
                        ),
                        borderRadius: AppTheme.chipRadius,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text(
                          definition.name,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 12),
            Text(
              'Only known notifications with complete payloads open routes. Unknown or incomplete payloads stay display-only.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationPreferencesCard extends StatelessWidget {
  const _NotificationPreferencesCard({
    required this.preferences,
    required this.onCategoryChanged,
  });

  final NotificationPreferences preferences;
  final Future<void> Function(
    NotificationPreferenceCategory category,
    bool enabled,
  )
  onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = const Color(0xFF7C4DFF);
    final surface = Color.alphaBlend(
      accent.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.12 : 0.05,
      ),
      theme.colorScheme.surfaceContainerLow,
    );

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(context, color: surface),
      child: Padding(
        padding: AppTheme.sectionPadding(compact: true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delivery categories', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'These preferences are stored on this device until backend preference sync lands.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8),
            for (final category in NotificationPreferenceCategory.values) ...[
              _NotificationPreferenceTile(
                title: _notificationCategoryTitle(category),
                subtitle: _notificationCategorySubtitle(category),
                value: preferences.isEnabled(category),
                onChanged: (value) => onCategoryChanged(category, value),
              ),
              if (category != NotificationPreferenceCategory.values.last)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationPreferenceTile extends StatelessWidget {
  const _NotificationPreferenceTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(subtitle),
    );
  }
}

class _NotificationMetaRow extends StatelessWidget {
  const _NotificationMetaRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 94,
          child: Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
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
            borderRadius: const BorderRadius.all(Radius.circular(14)),
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

class _NotificationTrailingAction extends StatelessWidget {
  const _NotificationTrailingAction({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isBusy = false,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final bool isBusy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: isBusy ? null : onPressed,
        iconSize: 18,
        style: IconButton.styleFrom(
          backgroundColor: color.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark
                ? 0.18
                : 0.08,
          ),
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.18)),
        ),
        icon: isBusy
            ? SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            : Icon(icon, size: 18, color: color),
      ),
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

Color _notificationSurfaceColor(
  BuildContext context,
  _NotificationSpec spec,
  bool unread,
) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;
  final alpha = unread ? (isDark ? 0.16 : 0.085) : (isDark ? 0.055 : 0.035);

  return Color.alphaBlend(
    spec.color.withValues(alpha: alpha),
    colorScheme.surfaceContainerLow,
  );
}

String _routePersonName(NotificationItem item) {
  final title = item.title.trim();
  if (title.isNotEmpty) {
    return title;
  }

  return 'Profile';
}

String _notificationCategoryTitle(NotificationPreferenceCategory category) {
  return switch (category) {
    NotificationPreferenceCategory.messages => 'Messages',
    NotificationPreferenceCategory.matchesActivity => 'Matches & activity',
    NotificationPreferenceCategory.safetyAccount => 'Safety & account',
    NotificationPreferenceCategory.marketingProduct => 'Marketing & product',
  };
}

String _notificationCategorySubtitle(NotificationPreferenceCategory category) {
  return switch (category) {
    NotificationPreferenceCategory.messages =>
      'Replies, conversation nudges, and message alerts.',
    NotificationPreferenceCategory.matchesActivity =>
      'Matches, likes, standouts, and broader activity updates.',
    NotificationPreferenceCategory.safetyAccount =>
      'Verification, moderation, account health, and safety notices.',
    NotificationPreferenceCategory.marketingProduct =>
      'Product launches, promos, and non-essential announcements.',
  };
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

  return formatShortDate(local, reference: current);
}
