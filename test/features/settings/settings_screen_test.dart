import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_dating_application_1/features/auth/selected_user_store.dart';
import 'package:flutter_dating_application_1/features/settings/app_preferences_store.dart';
import 'package:flutter_dating_application_1/features/settings/settings_screen.dart';
import 'package:flutter_dating_application_1/features/stats/stats_provider.dart';
import 'package:flutter_dating_application_1/models/app_preferences.dart';
import 'package:flutter_dating_application_1/models/achievement_summary.dart';
import 'package:flutter_dating_application_1/models/user_stats.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';
import 'package:flutter_dating_application_1/shared/persistence/shared_preferences_provider.dart';
import 'package:flutter_dating_application_1/shared/widgets/shell_hero.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const currentUser = UserSummary(
    id: '11111111-1111-1111-1111-111111111111',
    name: 'Dana',
    age: 27,
    state: 'ACTIVE',
  );

  Future<SharedPreferences> createPreferences({
    AppPreferences preferences = const AppPreferences(),
  }) async {
    SharedPreferences.setMockInitialValues({
      SelectedUserStore.storageKey: jsonEncode(currentUser.toJson()),
      AppPreferencesStore.storageKey: jsonEncode(preferences.toJson()),
    });

    return SharedPreferences.getInstance();
  }

  Finder settingsScrollable() {
    return find.descendant(
      of: find.byType(SettingsScreen),
      matching: find.byType(Scrollable),
    );
  }

  testWidgets(
    'renders the current user, theme controls, and switch user action',
    (WidgetTester tester) async {
      final preferences = await createPreferences();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
          child: const MaterialApp(
            home: SettingsScreen(currentUser: currentUser),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
      expect(find.byType(ShellHero), findsOneWidget);
      expect(find.text('Current session'), findsOneWidget);
      expect(find.text('Current dev session'), findsNothing);
      expect(find.text('Dana'), findsOneWidget);
      expect(find.text('Active profile'), findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, 'Switch profile'),
        findsOneWidget,
      );
      expect(find.text('View stats'), findsOneWidget);
      expect(find.text('View achievements'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Use system theme'),
        200,
        scrollable: settingsScrollable(),
      );
      await tester.pumpAndSettle();
      expect(find.text('Use system theme'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    },
  );

  testWidgets(
    'updates the stored theme preference from the settings controls',
    (WidgetTester tester) async {
      final preferences = await createPreferences();
      final store = AppPreferencesStore(preferences);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
          child: const MaterialApp(
            home: SettingsScreen(currentUser: currentUser),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Dark'),
        200,
        scrollable: settingsScrollable(),
      );
      await tester.pumpAndSettle();
      final darkOption = find.text('Dark');
      await tester.pumpAndSettle();
      await tester.tap(darkOption);
      await tester.pumpAndSettle();

      expect(
        await store.readPreferences(),
        const AppPreferences(themeMode: AppThemeModePreference.dark),
      );
    },
  );

  testWidgets('clears the persisted user when switch user is pressed', (
    WidgetTester tester,
  ) async {
    final preferences = await createPreferences();
    final selectedUserStore = SelectedUserStore(preferences);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const MaterialApp(
          home: SettingsScreen(currentUser: currentUser),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Switch profile'));
    await tester.pumpAndSettle();

    expect(await selectedUserStore.readSelectedUser(), isNull);
  });

  testWidgets('opens the stats screen from settings', (
    WidgetTester tester,
  ) async {
    final preferences = await createPreferences();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          statsProvider.overrideWith(
            (ref) async => const UserStats(
              items: [UserStatItem(label: 'Matches', value: '4')],
            ),
          ),
          achievementsProvider.overrideWith(
            (ref) async => const [
              AchievementSummary(title: 'Early Bird', isUnlocked: true),
            ],
          ),
        ],
        child: const MaterialApp(
          home: SettingsScreen(currentUser: currentUser),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('View stats'),
      200,
      scrollable: settingsScrollable(),
    );
    await tester.pumpAndSettle();
    final statsButton = find.text('View stats');
    await tester.pumpAndSettle();
    await tester.tap(statsButton);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Stats'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Matches'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Matches'), findsOneWidget);
  });

  testWidgets('opens the achievements screen from settings', (
    WidgetTester tester,
  ) async {
    final preferences = await createPreferences();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          statsProvider.overrideWith((ref) async => const UserStats(items: [])),
          achievementsProvider.overrideWith(
            (ref) async => const [
              AchievementSummary(
                title: 'Conversation Starter',
                subtitle: 'Sent the first message',
                isUnlocked: true,
              ),
            ],
          ),
        ],
        child: const MaterialApp(
          home: SettingsScreen(currentUser: currentUser),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('View achievements'),
      200,
      scrollable: settingsScrollable(),
    );
    await tester.pumpAndSettle();
    final achievementsButton = find.text('View achievements');
    await tester.pumpAndSettle();
    await tester.tap(achievementsButton);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Achievements'), findsOneWidget);
    expect(find.text('Conversation Starter'), findsOneWidget);
  });
}
