import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_dating_application_1/features/auth/auth_token_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'readSession returns null for corrupt or schema-mismatched data',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final store = AuthTokenStore(preferences);

      await preferences.setString(AuthTokenStore.storageKey, '{not-json');
      expect(store.readSession(), isNull);

      await preferences.setString(AuthTokenStore.storageKey, '{"user": 1}');
      expect(store.readSession(), isNull);
    },
  );
}
