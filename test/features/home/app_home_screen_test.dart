import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_dating_application_1/features/auth/auth_token_store.dart';
import 'package:flutter_dating_application_1/features/auth/login_screen.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_store.dart';
import 'package:flutter_dating_application_1/features/browse/browse_provider.dart';
import 'package:flutter_dating_application_1/features/chat/conversations_provider.dart';
import 'package:flutter_dating_application_1/features/home/app_home_screen.dart';
import 'package:flutter_dating_application_1/features/home/backend_health_provider.dart';
import 'package:flutter_dating_application_1/features/home/signed_in_shell.dart';
import 'package:flutter_dating_application_1/features/matches/matches_provider.dart';
import 'package:flutter_dating_application_1/features/profile/profile_provider.dart';
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

  testWidgets('shows the login screen when no session is persisted', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
        ],
        child: const MaterialApp(home: AppHomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
  });

  testWidgets(
    'shows the signed-in shell when a valid session is persisted',
    (WidgetTester tester) async {
      // Seed both an auth session (so AuthController.restoreSession
      // moves to Authenticated) and a SelectedUserStore entry (so the
      // bridged user is available even when the live /me call fails
      // because no real backend is reachable in tests).
      final sessionJson = jsonEncode({
        'accessToken': 'access-1',
        'refreshToken': 'refresh-1',
        'expiresAt': DateTime.now()
            .toUtc()
            .add(const Duration(hours: 1))
            .toIso8601String(),
        'user': {
          'id': currentUser.id,
          'email': 'dana@example.com',
          'displayName': 'Dana',
          'profileCompletionState': 'complete',
        },
      });
      SharedPreferences.setMockInitialValues({
        AuthTokenStore.storageKey: sessionJson,
        SelectedUserStore.storageKey: jsonEncode(currentUser.toJson()),
      });
      final preferences = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            backendHealthProvider.overrideWith(
              (ref) async => HealthStatus(
                status: 'ok',
                timestamp: DateTime(2026, 4, 19, 9),
              ),
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
          child: const MaterialApp(home: AppHomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SignedInShell), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    },
  );
}
