import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/src/internals.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_dating_application_1/features/browse/pending_likers_screen.dart';
import 'package:flutter_dating_application_1/features/browse/standouts_screen.dart';
import 'package:flutter_dating_application_1/features/chat/conversation_thread_screen.dart';
import 'package:flutter_dating_application_1/features/home/app_home_screen.dart';
import 'package:flutter_dating_application_1/features/home/signed_in_shell.dart';
import 'package:flutter_dating_application_1/features/location/location_completion_screen.dart';
import 'package:flutter_dating_application_1/features/notifications/notifications_screen.dart';
import 'package:flutter_dating_application_1/features/profile/profile_edit_screen.dart';
import 'package:flutter_dating_application_1/features/profile/profile_screen.dart';
import 'package:flutter_dating_application_1/features/safety/blocked_users_screen.dart';
import 'package:flutter_dating_application_1/features/settings/app_preferences_store.dart';
import 'package:flutter_dating_application_1/features/stats/stats_screen.dart';
import 'package:flutter_dating_application_1/features/stats/achievements_screen.dart';
import 'package:flutter_dating_application_1/features/verification/verification_screen.dart';
import 'package:flutter_dating_application_1/models/app_preferences.dart';
import 'package:flutter_dating_application_1/theme/app_theme.dart';

import 'fixtures/visual_scenarios.dart';
import 'support/screenshot_capture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final GoldenFileComparator previousComparator = goldenFileComparator;
  final ScreenshotWriter screenshotWriter = ScreenshotWriter(
    Uri.file(
      [
        Directory.current.path,
        'test',
        'visual_inspection',
        'screenshot_test.dart',
      ].join(Platform.pathSeparator),
    ),
  );
  goldenFileComparator = screenshotWriter;
  tearDownAll(() {
    goldenFileComparator = previousComparator;
  });

  testWidgets('captures the app startup dev-user picker state', (
    WidgetTester tester,
  ) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpVisualHarness(
      tester,
      child: ProviderScope(
        overrides: [...devUserPickerOverrides(preferences)],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.light,
          home: AppHomeScreen(),
        ),
      ),
    );

    await _captureAndSave(
      tester,
      scenarioName: 'app startup dev-user picker',
      fileName: 'app_home_startup.png',
    );
  });

  testWidgets('captures the signed-in shell discover tab', (
    WidgetTester tester,
  ) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpSignedInShell(tester, preferences: preferences);

    await _captureAndSave(
      tester,
      scenarioName: 'signed-in shell discover tab',
      fileName: 'shell_discover.png',
    );
  });

  testWidgets('captures the signed-in shell matches tab', (
    WidgetTester tester,
  ) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpSignedInShell(tester, preferences: preferences);

    await tester.tap(find.text('Matches'));
    await tester.pumpAndSettle();

    await _captureAndSave(
      tester,
      scenarioName: 'signed-in shell matches tab',
      fileName: 'shell_matches.png',
    );
  });

  testWidgets('captures the signed-in shell chats tab', (
    WidgetTester tester,
  ) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpSignedInShell(tester, preferences: preferences);

    await tester.tap(find.text('Chats'));
    await tester.pumpAndSettle();

    await _captureAndSave(
      tester,
      scenarioName: 'signed-in shell chats tab',
      fileName: 'shell_chats.png',
    );
  });

  testWidgets('captures the signed-in shell profile tab', (
    WidgetTester tester,
  ) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpSignedInShell(tester, preferences: preferences);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await _captureAndSave(
      tester,
      scenarioName: 'signed-in shell profile tab',
      fileName: 'shell_profile.png',
    );
  });

  testWidgets('captures the signed-in shell settings tab', (
    WidgetTester tester,
  ) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpSignedInShell(tester, preferences: preferences);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await _captureAndSave(
      tester,
      scenarioName: 'signed-in shell settings tab',
      fileName: 'shell_settings.png',
    );
  });

  testWidgets('captures a populated conversation thread', (
    WidgetTester tester,
  ) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpVisualHarness(
      tester,
      child: ProviderScope(
        overrides: [
          ...baseSignedInOverrides(preferences),
          ...conversationThreadOverrides,
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.light,
          home: ConversationThreadScreen(
            currentUser: currentUser,
            conversation: firstConversation,
            refreshInterval: Duration.zero,
          ),
        ),
      ),
    );

    await _captureAndSave(
      tester,
      scenarioName: 'populated conversation thread',
      fileName: 'conversation_thread.png',
    );
  });

  testWidgets('captures the standouts screen', (WidgetTester tester) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpSignedInVisualScreen(
      tester,
      preferences: preferences,
      overrides: standoutsOverrides,
      child: const StandoutsScreen(),
    );

    await _captureAndSave(
      tester,
      scenarioName: 'standouts screen',
      fileName: 'standouts.png',
    );
  });

  testWidgets('captures the pending likers screen', (
    WidgetTester tester,
  ) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpSignedInVisualScreen(
      tester,
      preferences: preferences,
      overrides: pendingLikersOverrides,
      child: const PendingLikersScreen(),
    );

    await _captureAndSave(
      tester,
      scenarioName: 'pending likers screen',
      fileName: 'pending_likers.png',
    );
  });

  testWidgets('captures the other-user profile screen', (
    WidgetTester tester,
  ) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpSignedInVisualScreen(
      tester,
      preferences: preferences,
      overrides: otherUserProfileOverrides,
      child: ProfileScreen.otherUser(
        userId: otherUserProfileDetail.id,
        userName: otherUserProfileDetail.name,
      ),
    );

    await _captureAndSave(
      tester,
      scenarioName: 'other-user profile screen',
      fileName: 'profile_other_user.png',
    );
  });

  testWidgets('captures the profile edit screen', (WidgetTester tester) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpSignedInVisualScreen(
      tester,
      preferences: preferences,
      child: ProfileEditScreen(initialDetail: profileDetail),
    );

    await _captureAndSave(
      tester,
      scenarioName: 'profile edit screen',
      fileName: 'profile_edit.png',
    );
  });

  testWidgets('captures the location completion screen', (
    WidgetTester tester,
  ) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpSignedInVisualScreen(
      tester,
      preferences: preferences,
      overrides: locationCompletionOverrides,
      child: const LocationCompletionScreen(),
    );

    await tester.enterText(find.byType(TextField).first, 'Tel');
    await tester.pumpAndSettle();

    await _captureAndSave(
      tester,
      scenarioName: 'location completion screen',
      fileName: 'location_completion.png',
    );
  });

  testWidgets('captures the stats screen', (WidgetTester tester) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpSignedInVisualScreen(
      tester,
      preferences: preferences,
      overrides: statsOverrides,
      child: const StatsScreen(currentUser: currentUser),
    );

    await _captureAndSave(
      tester,
      scenarioName: 'stats screen',
      fileName: 'stats.png',
    );
  });

  testWidgets('captures the achievements screen', (WidgetTester tester) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpSignedInVisualScreen(
      tester,
      preferences: preferences,
      overrides: achievementsOverrides,
      child: const AchievementsScreen(currentUser: currentUser),
    );

    await _captureAndSave(
      tester,
      scenarioName: 'achievements screen',
      fileName: 'achievements.png',
    );
  });

  testWidgets('captures the verification screen', (WidgetTester tester) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpSignedInVisualScreen(
      tester,
      preferences: preferences,
      child: const VerificationScreen(),
    );

    await tester.enterText(find.byType(TextField).first, 'dana@example.com');
    await tester.pumpAndSettle();

    await _captureAndSave(
      tester,
      scenarioName: 'verification screen',
      fileName: 'verification.png',
    );
  });

  testWidgets('captures the blocked users screen', (WidgetTester tester) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpSignedInVisualScreen(
      tester,
      preferences: preferences,
      overrides: blockedUsersOverrides,
      child: const BlockedUsersScreen(),
    );

    await _captureAndSave(
      tester,
      scenarioName: 'blocked users screen',
      fileName: 'blocked_users.png',
    );
  });

  testWidgets('captures the notifications screen', (WidgetTester tester) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpSignedInVisualScreen(
      tester,
      preferences: preferences,
      overrides: notificationsOverrides,
      child: const NotificationsScreen(),
    );

    await _captureAndSave(
      tester,
      scenarioName: 'notifications screen',
      fileName: 'notifications.png',
    );
  });
}

const _goldenRootKey = ValueKey<String>('visual-review-root');

Future<SharedPreferences> _preferencesWithTheme(
  AppThemeModePreference themeMode,
) async {
  SharedPreferences.setMockInitialValues({
    AppPreferencesStore.storageKey: jsonEncode(
      AppPreferences(themeMode: themeMode).toJson(),
    ),
  });

  return SharedPreferences.getInstance();
}

Future<void> _captureAndSave(
  WidgetTester tester, {
  required String scenarioName,
  required String fileName,
}) async {
  final GoldenFileComparator comparator = goldenFileComparator;
  if (comparator is ScreenshotWriter) {
    comparator.registerScenario(fileName: fileName, scenarioName: scenarioName);
  }

  await expectLater(
    find.byKey(_goldenRootKey),
    matchesGoldenFile('screenshots/$fileName'),
  );
}

Future<void> _pumpVisualHarness(
  WidgetTester tester, {
  required Widget child,
}) async {
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });

  await tester.binding.setSurfaceSize(const Size(412, 915));

  await tester.pumpWidget(RepaintBoundary(key: _goldenRootKey, child: child));

  await tester.pumpAndSettle();
}

Future<void> _pumpSignedInShell(
  WidgetTester tester, {
  required SharedPreferences preferences,
}) async {
  await _pumpVisualHarness(
    tester,
    child: ProviderScope(
      overrides: [...signedInShellOverrides(preferences)],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.light,
        home: SignedInShell(currentUser: currentUser),
      ),
    ),
  );
}

Future<void> _pumpSignedInVisualScreen(
  WidgetTester tester, {
  required SharedPreferences preferences,
  required Widget child,
  List<Override> overrides = const <Override>[],
}) async {
  await _pumpVisualHarness(
    tester,
    child: ProviderScope(
      overrides: [...baseSignedInOverrides(preferences), ...overrides],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.light,
        home: child,
      ),
    ),
  );
}
