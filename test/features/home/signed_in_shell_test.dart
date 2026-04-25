import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_dating_application_1/features/browse/browse_provider.dart';
import 'package:flutter_dating_application_1/features/chat/conversations_provider.dart';
import 'package:flutter_dating_application_1/features/home/backend_health_provider.dart';
import 'package:flutter_dating_application_1/features/home/signed_in_shell.dart';
import 'package:flutter_dating_application_1/features/matches/matches_provider.dart';
import 'package:flutter_dating_application_1/features/profile/profile_provider.dart';
import 'package:flutter_dating_application_1/features/settings/settings_screen.dart';
import 'package:flutter_dating_application_1/models/browse_response.dart';
import 'package:flutter_dating_application_1/models/health_status.dart';
import 'package:flutter_dating_application_1/models/matches_response.dart';
import 'package:flutter_dating_application_1/models/user_detail.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';
import 'package:flutter_dating_application_1/shared/persistence/shared_preferences_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const currentUser = UserSummary(
    id: '11111111-1111-1111-1111-111111111111',
    name: 'Dana',
    age: 27,
    state: 'ACTIVE',
  );

  const currentUserDetail = UserDetail(
    id: '11111111-1111-1111-1111-111111111111',
    name: 'Dana',
    age: 27,
    bio: 'Loves coffee and beach walks.',
    gender: 'FEMALE',
    interestedIn: ['MALE'],
    approximateLocation: 'Tel Aviv',
    maxDistanceKm: 50,
    photoUrls: ['/photos/dana-1.jpg'],
    state: 'ACTIVE',
  );

  Finder settingsScrollable() {
    return find.descendant(
      of: find.byType(SettingsScreen),
      matching: find.byType(Scrollable),
    );
  }

  testWidgets('opens the current user profile from the shell navigation', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          backendHealthProvider.overrideWith(
            (ref) async =>
                HealthStatus(status: 'ok', timestamp: DateTime(2026, 4, 19, 9)),
          ),
          browseProvider.overrideWith(
            (ref) async => const BrowseResponse(
              candidates: [],
              dailyPick: null,
              dailyPickViewed: false,
              locationMissing: false,
            ),
          ),
          matchesProvider.overrideWith(
            (ref) async => const MatchesResponse(
              matches: [],
              totalCount: 0,
              offset: 0,
              limit: 20,
              hasMore: false,
            ),
          ),
          conversationsProvider.overrideWith((ref) async => const []),
          profileProvider.overrideWith((ref) async => currentUserDetail),
        ],
        child: const MaterialApp(home: SignedInShell(currentUser: currentUser)),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('shell-active-destination-label')),
      findsNothing,
    );
    expect(find.byKey(const Key('shell-active-user-summary')), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Signed in as Dana'), findsNothing);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('shell-active-destination-label')),
      findsNothing,
    );

    expect(find.text('Dana, 27'), findsOneWidget);
    expect(find.text('Loves coffee and beach walks.'), findsOneWidget);
  });

  testWidgets('opens settings from the shell navigation', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          backendHealthProvider.overrideWith(
            (ref) async =>
                HealthStatus(status: 'ok', timestamp: DateTime(2026, 4, 19, 9)),
          ),
          browseProvider.overrideWith(
            (ref) async => const BrowseResponse(
              candidates: [],
              dailyPick: null,
              dailyPickViewed: false,
              locationMissing: false,
            ),
          ),
          matchesProvider.overrideWith(
            (ref) async => const MatchesResponse(
              matches: [],
              totalCount: 0,
              offset: 0,
              limit: 20,
              hasMore: false,
            ),
          ),
          conversationsProvider.overrideWith((ref) async => const []),
          profileProvider.overrideWith((ref) async => currentUserDetail),
        ],
        child: const MaterialApp(home: SignedInShell(currentUser: currentUser)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('shell-active-destination-label')),
      findsNothing,
    );
    expect(find.byType(NavigationBar), findsOneWidget);

    expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Switch profile'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('View stats'),
      200,
      scrollable: settingsScrollable(),
    );
    await tester.pumpAndSettle();
    expect(find.text('View stats'), findsOneWidget);
  });

  testWidgets('keeps only the navigation bar as persistent bottom chrome', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          backendHealthProvider.overrideWith(
            (ref) async =>
                HealthStatus(status: 'ok', timestamp: DateTime(2026, 4, 19, 9)),
          ),
          browseProvider.overrideWith(
            (ref) async => const BrowseResponse(
              candidates: [],
              dailyPick: null,
              dailyPickViewed: false,
              locationMissing: false,
            ),
          ),
          matchesProvider.overrideWith(
            (ref) async => const MatchesResponse(
              matches: [],
              totalCount: 0,
              offset: 0,
              limit: 20,
              hasMore: false,
            ),
          ),
          conversationsProvider.overrideWith((ref) async => const []),
          profileProvider.overrideWith((ref) async => currentUserDetail),
        ],
        child: const MaterialApp(home: SignedInShell(currentUser: currentUser)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byKey(const Key('shell-active-user-summary')), findsNothing);
    expect(
      find.byKey(const Key('shell-active-destination-label')),
      findsNothing,
    );
  });
}
