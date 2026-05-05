import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/persistence/shared_preferences_provider.dart';
import 'notification_preferences.dart';
import 'notification_preferences_store.dart';

final notificationPreferencesStoreProvider =
    Provider<NotificationPreferencesStore>((ref) {
      final preferences = ref.watch(sharedPreferencesProvider);
      return NotificationPreferencesStore(preferences);
    });

final notificationPreferencesProvider =
    NotifierProvider<
      NotificationPreferencesController,
      NotificationPreferences
    >(NotificationPreferencesController.new);

final notificationPreferencesControllerProvider =
    Provider<NotificationPreferencesController>((ref) {
      return ref.read(notificationPreferencesProvider.notifier);
    });

class NotificationPreferencesController
    extends Notifier<NotificationPreferences> {
  late NotificationPreferencesStore _store;

  @override
  NotificationPreferences build() {
    _store = ref.watch(notificationPreferencesStoreProvider);
    return _store.readCurrentPreferences();
  }

  Future<void> setCategoryEnabled(
    NotificationPreferenceCategory category,
    bool enabled,
  ) async {
    final previousPreferences = state;
    final updatedPreferences = state.setCategoryEnabled(category, enabled);
    state = updatedPreferences;
    try {
      await _store.savePreferences(updatedPreferences);
    } catch (_) {
      state = previousPreferences;
      rethrow;
    }
  }
}
