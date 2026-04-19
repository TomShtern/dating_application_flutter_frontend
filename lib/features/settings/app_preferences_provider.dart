import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_preferences.dart';
import '../../shared/persistence/shared_preferences_provider.dart';
import 'app_preferences_store.dart';

final appPreferencesStoreProvider = Provider<AppPreferencesStore>((ref) {
  final preferences = ref.watch(sharedPreferencesProvider);
  return AppPreferencesStore(preferences);
});

final appPreferencesProvider =
    NotifierProvider<AppPreferencesController, AppPreferences>(
      AppPreferencesController.new,
    );

final currentThemeModePreferenceProvider = Provider<AppThemeModePreference>((
  ref,
) {
  return ref.watch(appPreferencesProvider).themeMode;
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(currentThemeModePreferenceProvider).themeMode;
});

final appPreferencesControllerProvider = Provider<AppPreferencesController>((
  ref,
) {
  return ref.read(appPreferencesProvider.notifier);
});

class AppPreferencesController extends Notifier<AppPreferences> {
  late final AppPreferencesStore _store;

  @override
  AppPreferences build() {
    _store = ref.watch(appPreferencesStoreProvider);
    return _store.readCurrentPreferences();
  }

  Future<void> setThemeMode(AppThemeModePreference themeMode) async {
    final updatedPreferences = state.copyWith(themeMode: themeMode);

    state = updatedPreferences;
    await _store.savePreferences(updatedPreferences);
  }
}
