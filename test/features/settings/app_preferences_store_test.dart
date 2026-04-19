import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_dating_application_1/features/settings/app_preferences_store.dart';
import 'package:flutter_dating_application_1/models/app_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'returns default app preferences when nothing has been persisted',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final store = AppPreferencesStore(preferences);

      final restored = await store.readPreferences();

      expect(restored, const AppPreferences());
    },
  );

  test('saves and restores the selected theme mode preference', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store = AppPreferencesStore(preferences);

    const expected = AppPreferences(themeMode: AppThemeModePreference.dark);

    await store.savePreferences(expected);
    final restored = await store.readPreferences();

    expect(restored, expected);
  });
}
