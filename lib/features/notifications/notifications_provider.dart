import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../models/notification_item.dart';
import '../../shared/providers/selected_user_guard.dart' as user_guard;

final notificationsUnreadOnlyProvider =
    NotifierProvider<NotificationsUnreadOnlyNotifier, bool>(
      NotificationsUnreadOnlyNotifier.new,
    );

final notificationsProvider = FutureProvider<List<NotificationItem>>((
  ref,
) async {
  final apiClient = ref.watch(apiClientProvider);
  final unreadOnly = ref.watch(notificationsUnreadOnlyProvider);
  final currentUser = await user_guard.watchSelectedUser(ref);
  return apiClient.getNotifications(
    userId: currentUser.id,
    unreadOnly: unreadOnly,
  );
});

final notificationsUnreadCountProvider = FutureProvider<int>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final currentUser = await user_guard.watchSelectedUser(ref);
  final unreadNotifications = await apiClient.getNotifications(
    userId: currentUser.id,
    unreadOnly: true,
  );
  return unreadNotifications.length;
});

final notificationsControllerProvider = Provider<NotificationsController>((
  ref,
) {
  return NotificationsController(ref);
});

class NotificationsController {
  NotificationsController(this._ref);

  final Ref _ref;

  Future<void> markRead(String notificationId) async {
    final currentUser = await user_guard.requireSelectedUser(_ref);
    final apiClient = _ref.read(apiClientProvider);
    await apiClient.markNotificationRead(
      userId: currentUser.id,
      notificationId: notificationId,
    );
    _ref.invalidate(notificationsProvider);
    _ref.invalidate(notificationsUnreadCountProvider);
  }

  Future<int> markAllRead() async {
    final currentUser = await user_guard.requireSelectedUser(_ref);
    final apiClient = _ref.read(apiClientProvider);
    final updatedCount = await apiClient.markAllNotificationsRead(
      userId: currentUser.id,
    );
    _ref.invalidate(notificationsProvider);
    _ref.invalidate(notificationsUnreadCountProvider);
    return updatedCount;
  }

  Future<void> refresh() {
    _ref.invalidate(notificationsUnreadCountProvider);
    return _ref.refresh(notificationsProvider.future);
  }

  void setUnreadOnly(bool value) {
    _ref.read(notificationsUnreadOnlyProvider.notifier).setValue(value);
  }
}

class NotificationsUnreadOnlyNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setValue(bool value) {
    state = value;
  }
}
