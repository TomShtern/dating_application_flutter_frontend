import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_dating_application_1/features/auth/selected_user_store.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('saves and restores the selected dev user', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store = SelectedUserStore(preferences);

    const user = UserSummary(
      id: '11111111-1111-1111-1111-111111111111',
      name: 'Dana',
      age: 27,
      state: 'ACTIVE',
    );

    await store.saveSelectedUser(user);
    final restored = await store.readSelectedUser();

    expect(restored, user);
  });
}
