import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_dating_application_1/features/auth/auth_controller.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_store.dart';
import 'package:flutter_dating_application_1/features/browse/browse_provider.dart';
import 'package:flutter_dating_application_1/features/chat/conversations_provider.dart';
import 'package:flutter_dating_application_1/features/home/app_home_screen.dart';
import 'package:flutter_dating_application_1/features/home/backend_health_provider.dart';
import 'package:flutter_dating_application_1/features/home/signed_in_shell.dart';
import 'package:flutter_dating_application_1/features/matches/matches_provider.dart';
import 'package:flutter_dating_application_1/features/profile/profile_provider.dart';
import 'package:flutter_dating_application_1/models/browse_response.dart';
import 'package:flutter_dating_application_1/models/auth_user.dart';
import 'package:flutter_dating_application_1/models/health_status.dart';
import 'package:flutter_dating_application_1/models/matches_response.dart';
import 'package:flutter_dating_application_1/models/user_detail.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';
import 'package:flutter_dating_application_1/shared/persistence/shared_preferences_provider.dart';

import '../auth/fake_auth_controller.dart';
import '../onboarding/complete_profile_snapshot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ClerkAuthState cannot be faked (private constructor), so the auth
  // controller is replaced with one that starts in a fixed state.
  const authenticated = Authenticated(
    AuthUser(
      id: '11111111-1111-1111-1111-111111111111',
      email: 'dana@example.com',
      displayName: 'Dana',
      profileCompletionState: 'complete',
    ),
  );

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

  testWidgets('shows the signed-in shell when the user is authenticated', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      SelectedUserStore.storageKey: jsonEncode(currentUser.toJson()),
    });
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          authControllerProvider.overrideWith(
            () => FakeAuthController(authenticated),
          ),
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
          profileEditSnapshotProvider.overrideWith(
            (ref) async => completeProfileSnapshot,
          ),
        ],
        child: const MaterialApp(home: AppHomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SignedInShell), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
