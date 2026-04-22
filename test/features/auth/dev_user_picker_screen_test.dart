import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_dating_application_1/features/auth/dev_user_picker_screen.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/home/backend_health_provider.dart';
import 'package:flutter_dating_application_1/models/health_status.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';
import 'package:flutter_dating_application_1/shared/persistence/shared_preferences_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const dana = UserSummary(
    id: '11111111-1111-1111-1111-111111111111',
    name: 'Dana',
    age: 27,
    state: 'ACTIVE',
  );

  const noa = UserSummary(
    id: '22222222-2222-2222-2222-222222222222',
    name: 'Noa',
    age: 29,
    state: 'ACTIVE',
  );

  testWidgets('keeps picker rows clear without stacked action hints', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedUserProvider.overrideWithValue(
            const AsyncData<UserSummary?>(dana),
          ),
          availableUsersProvider.overrideWith((ref) async => const [dana, noa]),
          backendHealthProvider.overrideWith(
            (ref) async =>
                HealthStatus(status: 'ok', timestamp: DateTime(2026, 4, 21, 9)),
          ),
        ],
        child: const MaterialApp(home: DevUserPickerScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Current'), findsOneWidget);
    expect(find.text('Continue as Noa'), findsNothing);
    expect(find.text('Saved on this device right now.'), findsOneWidget);
    expect(find.textContaining('Tap anywhere to continue'), findsNothing);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
  });

  testWidgets('still lets tapping a row switch the selected user', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          availableUsersProvider.overrideWith((ref) async => const [dana, noa]),
          backendHealthProvider.overrideWith(
            (ref) async =>
                HealthStatus(status: 'ok', timestamp: DateTime(2026, 4, 21, 9)),
          ),
        ],
        child: const MaterialApp(home: DevUserPickerScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final noaRow = find.ancestor(
      of: find.text('Noa'),
      matching: find.byType(InkWell),
    );
    await tester.ensureVisible(noaRow);
    await tester.pumpAndSettle();
    await tester.tap(noaRow, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Current user updated to Noa.'), findsOneWidget);
    expect(find.text('Current profile'), findsOneWidget);
    expect(find.text('Noa • Age 29 • Active profile'), findsOneWidget);
  });
}
