import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_dating_application_1/features/notifications/notification_preferences.dart';
import 'package:flutter_dating_application_1/features/notifications/notification_preferences_provider.dart';
import 'package:flutter_dating_application_1/features/notifications/notification_preferences_store.dart';
import 'package:flutter_dating_application_1/shared/persistence/shared_preferences_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reads stored notification preferences into provider state', () async {
    SharedPreferences.setMockInitialValues({
      NotificationPreferencesStore.storageKey:
          '{"messages":true,"matchesActivity":false,"safetyAccount":true,"marketingProduct":false}',
    });
    final preferences = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);

    expect(
      container.read(notificationPreferencesProvider),
      const NotificationPreferences(
        messages: true,
        matchesActivity: false,
        safetyAccount: true,
        marketingProduct: false,
      ),
    );
  });

  test(
    'setCategoryEnabled updates state and persists the category toggle',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final store = NotificationPreferencesStore(preferences);

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);

      await container
          .read(notificationPreferencesControllerProvider)
          .setCategoryEnabled(
            NotificationPreferenceCategory.marketingProduct,
            false,
          );

      expect(
        container.read(notificationPreferencesProvider),
        const NotificationPreferences(marketingProduct: false),
      );
      expect(
        await store.readPreferences(),
        const NotificationPreferences(marketingProduct: false),
      );
    },
  );
}
