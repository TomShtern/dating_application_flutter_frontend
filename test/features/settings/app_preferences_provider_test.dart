import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_dating_application_1/features/settings/app_preferences_provider.dart';
import 'package:flutter_dating_application_1/features/settings/app_preferences_store.dart';
import 'package:flutter_dating_application_1/models/app_preferences.dart';
import 'package:flutter_dating_application_1/shared/persistence/shared_preferences_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reads the stored app preferences into provider state', () async {
    SharedPreferences.setMockInitialValues({
      AppPreferencesStore.storageKey: '{"themeMode":"dark"}',
    });
    final preferences = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);

    expect(
      container.read(appPreferencesProvider),
      const AppPreferences(themeMode: AppThemeModePreference.dark),
    );
    expect(
      container.read(currentThemeModePreferenceProvider),
      AppThemeModePreference.dark,
    );
    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  test('setThemeMode updates state and persists the new preference', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store = AppPreferencesStore(preferences);

    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);

    await container
        .read(appPreferencesControllerProvider)
        .setThemeMode(AppThemeModePreference.light);

    expect(
      container.read(appPreferencesProvider),
      const AppPreferences(themeMode: AppThemeModePreference.light),
    );
    expect(
      await store.readPreferences(),
      const AppPreferences(themeMode: AppThemeModePreference.light),
    );
  });
}
