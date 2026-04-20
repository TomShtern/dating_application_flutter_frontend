import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_dating_application_1/app/app.dart';
import 'package:flutter_dating_application_1/features/browse/browse_provider.dart';
import 'package:flutter_dating_application_1/features/chat/conversation_thread_screen.dart';
import 'package:flutter_dating_application_1/features/chat/conversation_thread_provider.dart';
import 'package:flutter_dating_application_1/features/chat/conversations_screen.dart';
import 'package:flutter_dating_application_1/features/chat/conversations_provider.dart';
import 'package:flutter_dating_application_1/features/home/backend_health_provider.dart';
import 'package:flutter_dating_application_1/features/matches/matches_provider.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_store.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Finder conversationsScrollable() => find.descendant(
    of: find.byType(ConversationsScreen),
    matching: find.byType(Scrollable),
  );

  testWidgets('shows the dev user picker when no dev user is persisted', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          backendHealthProvider.overrideWith(
            (ref) async => HealthStatus(
              status: 'ok',
              timestamp: DateTime(2026, 4, 18, 12),
            ),
          ),
          availableUsersProvider.overrideWith(
            (ref) async => [
              const UserSummary(
                id: '11111111-1111-1111-1111-111111111111',
                name: 'Dana',
                age: 27,
                state: 'ACTIVE',
              ),
              const UserSummary(
                id: '22222222-2222-2222-2222-222222222222',
                name: 'Noa',
                age: 29,
                state: 'ACTIVE',
              ),
            ],
          ),
        ],
        child: const DatingApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Choose a dev user'), findsOneWidget);
    expect(find.textContaining('Current user: none selected'), findsOneWidget);
    expect(find.text('Continue as Dana'), findsOneWidget);
    expect(find.text('Continue as Noa'), findsOneWidget);
  });

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
        child: const DatingApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Discover'), findsOneWidget);
    expect(find.textContaining('Browsing as Dana'), findsOneWidget);
    expect(find.text('Today\'s daily pick'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Noa'), 200);
    await tester.pumpAndSettle();
    expect(find.text('Noa'), findsOneWidget);
    expect(find.text('Like'), findsOneWidget);
    expect(find.text('Pass'), findsOneWidget);
    expect(find.text('Matches'), findsOneWidget);
    expect(find.text('Chats'), findsOneWidget);

    await tester.tap(find.text('Matches'));
    await tester.pumpAndSettle();
    expect(find.text('Your matches'), findsOneWidget);

    await tester.tap(find.text('Chats'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Conversations'), findsOneWidget);

    final openChatButton = find.widgetWithText(FilledButton, 'Open chat');
    await tester.dragUntilVisible(
      openChatButton,
      conversationsScrollable(),
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(openChatButton).onPressed,
      isNotNull,
      reason: 'Open chat button should be enabled',
    );
    await tester.ensureVisible(openChatButton);
    await tester.pump();
    await tester.tap(openChatButton);
    await tester.pumpAndSettle();
    expect(find.byType(ConversationThreadScreen), findsOneWidget);
    expect(find.text('Hey Dana'), findsOneWidget);
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
        child: const DatingApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today\'s daily pick'), findsOneWidget);
    expect(find.text('Maya, 30'), findsOneWidget);
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
