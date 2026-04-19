import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/models/app_preferences.dart';

void main() {
  test('serializes the selected theme mode for local persistence', () {
    const preferences = AppPreferences(themeMode: AppThemeModePreference.dark);

    expect(preferences.toJson(), {'themeMode': 'dark'});
  });

  test('restores the persisted theme mode and falls back safely', () {
    expect(
      AppPreferences.fromJson({'themeMode': 'light'}),
      const AppPreferences(themeMode: AppThemeModePreference.light),
    );
    expect(
      AppPreferences.fromJson({'themeMode': 'mystery-mode'}),
      const AppPreferences(),
    );
    expect(AppPreferences.fromJson({'themeMode': 42}), const AppPreferences());
    expect(AppPreferences.fromJson(const {}), const AppPreferences());
  });
}
