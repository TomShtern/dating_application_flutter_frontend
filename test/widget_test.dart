import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_dating_application_1/features/browse/browse_provider.dart';
import 'package:flutter_dating_application_1/features/browse/browse_screen.dart';
import 'package:flutter_dating_application_1/features/chat/conversation_thread_provider.dart';
import 'package:flutter_dating_application_1/features/chat/conversations_screen.dart';
import 'package:flutter_dating_application_1/features/chat/conversations_provider.dart';
import 'package:flutter_dating_application_1/features/home/backend_health_provider.dart';
import 'package:flutter_dating_application_1/features/matches/matches_provider.dart';
import 'package:flutter_dating_application_1/features/auth/auth_controller.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_store.dart';
import 'package:flutter_dating_application_1/features/home/app_home_screen.dart';
import 'package:flutter_dating_application_1/features/profile/profile_provider.dart';
import 'package:flutter_dating_application_1/models/auth_user.dart';
import 'package:flutter_dating_application_1/models/browse_candidate.dart';
import 'package:flutter_dating_application_1/models/browse_response.dart';
import 'package:flutter_dating_application_1/models/conversation_summary.dart';
import 'package:flutter_dating_application_1/models/daily_pick.dart';
import 'package:flutter_dating_application_1/models/health_status.dart';
import 'package:flutter_dating_application_1/models/match_summary.dart';
import 'package:flutter_dating_application_1/models/message_dto.dart';
import 'package:flutter_dating_application_1/models/matches_response.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';
import 'package:flutter_dating_application_1/shared/persistence/shared_preferences_provider.dart';
import 'package:flutter_dating_application_1/theme/app_theme.dart';

import 'features/onboarding/complete_profile_snapshot.dart';

import 'features/auth/fake_auth_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // DatingApp wraps everything in ClerkAuth, and ClerkAuthState cannot be
  // faked (private constructor). These tests mount AppHomeScreen directly with
  // an auth controller pinned to Authenticated.
  Widget app() =>
      MaterialApp(theme: AppTheme.light(), home: const AppHomeScreen());

  AuthController authenticatedAs(UserSummary user) => FakeAuthController(
    Authenticated(
      AuthUser(
        id: user.id,
        email: '${user.name.toLowerCase()}@example.com',
        displayName: user.name,
        profileCompletionState: 'complete',
      ),
    ),
  );

  testWidgets('routes to browse when a persisted acting user exists', (
    WidgetTester tester,
  ) async {
    const savedUser = UserSummary(
      id: '11111111-1111-1111-1111-111111111111',
      name: 'Dana',
      age: 27,
      state: 'ACTIVE',
    );

    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({
      SelectedUserStore.storageKey: jsonEncode(savedUser.toJson()),
    });
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          authControllerProvider.overrideWith(() => authenticatedAs(savedUser)),
          profileEditSnapshotProvider.overrideWith(
            (ref) async => completeProfileSnapshot,
          ),
          backendHealthProvider.overrideWith(
            (ref) async => HealthStatus(
              status: 'ok',
              timestamp: DateTime(2026, 4, 18, 12),
            ),
          ),
          browseProvider.overrideWith(
            (ref) async => const BrowseResponse(
              candidates: [
                BrowseCandidate(
                  id: '22222222-2222-2222-2222-222222222222',
                  name: 'Noa',
                  age: 29,
                  state: 'ACTIVE',
                ),
              ],
              dailyPick: DailyPick(
                userId: '33333333-3333-3333-3333-333333333333',
                userName: 'Maya',
                userAge: 30,
                date: '2026-04-18',
                reason: 'High compatibility',
                alreadySeen: false,
              ),
              dailyPickViewed: false,
              locationMissing: false,
            ),
          ),
          matchesProvider.overrideWith(
            (ref) async => MatchesResponse(
              matches: [
                MatchSummary(
                  matchId:
                      '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
                  otherUserId: '22222222-2222-2222-2222-222222222222',
                  otherUserName: 'Noa',
                  state: 'ACTIVE',
                  createdAt: DateTime.parse('2026-04-18T12:34:56Z'),
                ),
              ],
              totalCount: 1,
              offset: 0,
              limit: 20,
              hasMore: false,
            ),
          ),
          conversationsProvider.overrideWith(
            (ref) async => [
              ConversationSummary(
                id: '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
                otherUserId: '22222222-2222-2222-2222-222222222222',
                otherUserName: 'Noa',
                messageCount: 5,
                lastMessageAt: DateTime.parse('2026-04-18T14:20:00Z'),
              ),
            ],
          ),
          conversationThreadProvider(
            '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
          ).overrideWith(
            (ref) async => [
              MessageDto(
                id: 'message-1',
                conversationId:
                    '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
                senderId: '22222222-2222-2222-2222-222222222222',
                content: 'Hey Dana',
                sentAt: DateTime.parse('2026-04-18T14:20:00Z'),
              ),
            ],
          ),
        ],
        child: app(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BrowseScreen), findsOneWidget);
    expect(find.text('Today\'s daily pick'), findsAtLeastNWidgets(1));
    await tester.scrollUntilVisible(find.text('Noa'), 200);
    await tester.pumpAndSettle();
    expect(find.text('Noa'), findsOneWidget);
    // "Like" appears twice as FilledButton labels: the candidate action bar
    // and the daily-pick card.
    expect(find.text('Like'), findsNWidgets(2));
    expect(find.text('Pass'), findsAtLeastNWidgets(1));
    expect(find.text('Matches'), findsOneWidget);
    expect(find.text('Chats'), findsOneWidget);

    await tester.tap(find.text('Matches'));
    await tester.pumpAndSettle();
    expect(find.text('Your matches'), findsOneWidget);

    await tester.tap(find.text('Chats'));
    await tester.pumpAndSettle();
    expect(find.byType(ConversationsScreen), findsOneWidget);

    // The chat-thread drill-down here used to test an "Open chat"
    // FilledButton that no longer exists after the conversations
    // redesign. The auth/routing portion of this test is what we
    // care about; the per-row interaction belongs in a focused chat
    // widget test, not the top-level routing test.
  });

  testWidgets('shows daily pick even when no browse candidates are available', (
    WidgetTester tester,
  ) async {
    const savedUser = UserSummary(
      id: '11111111-1111-1111-1111-111111111111',
      name: 'Dana',
      age: 27,
      state: 'ACTIVE',
    );

    SharedPreferences.setMockInitialValues({
      SelectedUserStore.storageKey: jsonEncode(savedUser.toJson()),
    });
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          authControllerProvider.overrideWith(() => authenticatedAs(savedUser)),
          profileEditSnapshotProvider.overrideWith(
            (ref) async => completeProfileSnapshot,
          ),
          backendHealthProvider.overrideWith(
            (ref) async => HealthStatus(
              status: 'ok',
              timestamp: DateTime(2026, 4, 18, 12),
            ),
          ),
          browseProvider.overrideWith(
            (ref) async => const BrowseResponse(
              candidates: [],
              dailyPick: DailyPick(
                userId: '33333333-3333-3333-3333-333333333333',
                userName: 'Maya',
                userAge: 30,
                date: '2026-04-18',
                reason: 'High compatibility',
                alreadySeen: false,
              ),
              dailyPickViewed: false,
              locationMissing: false,
            ),
          ),
          matchesProvider.overrideWith(
            (ref) async => MatchesResponse(
              matches: const [],
              totalCount: 0,
              offset: 0,
              limit: 20,
              hasMore: false,
            ),
          ),
          conversationsProvider.overrideWith((ref) async => const []),
        ],
        child: app(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today\'s daily pick'), findsAtLeastNWidgets(1));
    expect(find.text('Maya, 30'), findsAtLeastNWidgets(1));
    await tester.scrollUntilVisible(
      find.text(
        'No candidates are available right now. Try refreshing in a bit.',
      ),
      200,
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'No candidates are available right now. Try refreshing in a bit.',
      ),
      findsOneWidget,
    );
  });
}
