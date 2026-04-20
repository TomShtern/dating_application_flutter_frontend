import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/browse/browse_provider.dart';
import 'package:flutter_dating_application_1/features/chat/conversation_thread_provider.dart';
import 'package:flutter_dating_application_1/features/chat/conversation_thread_screen.dart';
import 'package:flutter_dating_application_1/features/chat/conversations_provider.dart';
import 'package:flutter_dating_application_1/features/home/app_home_screen.dart';
import 'package:flutter_dating_application_1/features/home/backend_health_provider.dart';
import 'package:flutter_dating_application_1/features/home/signed_in_shell.dart';
import 'package:flutter_dating_application_1/features/matches/matches_provider.dart';
import 'package:flutter_dating_application_1/features/profile/profile_provider.dart';
import 'package:flutter_dating_application_1/features/settings/app_preferences_store.dart';
import 'package:flutter_dating_application_1/models/app_preferences.dart';
import 'package:flutter_dating_application_1/models/browse_candidate.dart';
import 'package:flutter_dating_application_1/models/browse_response.dart';
import 'package:flutter_dating_application_1/models/conversation_summary.dart';
import 'package:flutter_dating_application_1/models/daily_pick.dart';
import 'package:flutter_dating_application_1/models/health_status.dart';
import 'package:flutter_dating_application_1/models/match_summary.dart';
import 'package:flutter_dating_application_1/models/matches_response.dart';
import 'package:flutter_dating_application_1/models/message_dto.dart';
import 'package:flutter_dating_application_1/models/user_detail.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';
import 'package:flutter_dating_application_1/shared/persistence/shared_preferences_provider.dart';
import 'package:flutter_dating_application_1/theme/app_theme.dart';

import 'support/visual_review_artifact_comparator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final GoldenFileComparator previousComparator = goldenFileComparator;
  final VisualReviewArtifactComparator artifactComparator =
      VisualReviewArtifactComparator(
        Uri.file(
          [
            Directory.current.path,
            'test',
            'visual',
            'visual_review_golden_test.dart',
          ].join(Platform.pathSeparator),
        ),
      );
  goldenFileComparator = artifactComparator;
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
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          backendHealthProvider.overrideWith(
            (ref) async => HealthStatus(
              status: 'ok',
              timestamp: DateTime.parse('2026-04-18T12:00:00Z'),
            ),
          ),
          selectedUserProvider.overrideWith((ref) async => null),
          availableUsersProvider.overrideWith(
            (ref) async => const [
              UserSummary(
                id: '11111111-1111-1111-1111-111111111111',
                name: 'Dana',
                age: 27,
                state: 'ACTIVE',
              ),
              UserSummary(
                id: '22222222-2222-2222-2222-222222222222',
                name: 'Noa',
                age: 29,
                state: 'ACTIVE',
              ),
            ],
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.light,
          home: AppHomeScreen(),
        ),
      ),
    );

    await _captureAndCompare(
      tester,
      scenarioName: 'app startup dev-user picker',
      goldenFileName: 'app_home_startup.png',
    );
  });

  testWidgets('captures the signed-in shell discover tab', (
    WidgetTester tester,
  ) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpVisualHarness(
      tester,
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          backendHealthProvider.overrideWith(
            (ref) async => HealthStatus(
              status: 'ok',
              timestamp: DateTime.parse('2026-04-18T12:00:00Z'),
            ),
          ),
          browseProvider.overrideWith(
            (ref) async => const BrowseResponse(
              candidates: [_candidateUser],
              dailyPick: _dailyPick,
              dailyPickViewed: false,
              locationMissing: false,
            ),
          ),
          matchesProvider.overrideWith(
            (ref) async => MatchesResponse(
              matches: [_match],
              totalCount: 1,
              offset: 0,
              limit: 20,
              hasMore: false,
            ),
          ),
          conversationsProvider.overrideWith((ref) async => [_conversation]),
          profileProvider.overrideWith((ref) async => _profileDetail),
          selectedUserProvider.overrideWith((ref) async => _currentUser),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.light,
          home: SignedInShell(currentUser: _currentUser),
        ),
      ),
    );

    await _captureAndCompare(
      tester,
      scenarioName: 'signed-in shell discover tab',
      goldenFileName: 'shell_discover.png',
    );
  });

  testWidgets('captures the signed-in shell matches tab', (
    WidgetTester tester,
  ) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpVisualHarness(
      tester,
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          backendHealthProvider.overrideWith(
            (ref) async => HealthStatus(
              status: 'ok',
              timestamp: DateTime.parse('2026-04-18T12:00:00Z'),
            ),
          ),
          browseProvider.overrideWith(
            (ref) async => const BrowseResponse(
              candidates: [_candidateUser],
              dailyPick: _dailyPick,
              dailyPickViewed: false,
              locationMissing: false,
            ),
          ),
          matchesProvider.overrideWith(
            (ref) async => MatchesResponse(
              matches: [_match],
              totalCount: 1,
              offset: 0,
              limit: 20,
              hasMore: false,
            ),
          ),
          conversationsProvider.overrideWith((ref) async => [_conversation]),
          profileProvider.overrideWith((ref) async => _profileDetail),
          selectedUserProvider.overrideWith((ref) async => _currentUser),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.light,
          home: SignedInShell(currentUser: _currentUser),
        ),
      ),
    );

    await tester.tap(find.text('Matches'));
    await tester.pumpAndSettle();

    await _captureAndCompare(
      tester,
      scenarioName: 'signed-in shell matches tab',
      goldenFileName: 'shell_matches.png',
    );
  });

  testWidgets('captures the signed-in shell chats tab', (
    WidgetTester tester,
  ) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpVisualHarness(
      tester,
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          backendHealthProvider.overrideWith(
            (ref) async => HealthStatus(
              status: 'ok',
              timestamp: DateTime.parse('2026-04-18T12:00:00Z'),
            ),
          ),
          browseProvider.overrideWith(
            (ref) async => const BrowseResponse(
              candidates: [_candidateUser],
              dailyPick: _dailyPick,
              dailyPickViewed: false,
              locationMissing: false,
            ),
          ),
          matchesProvider.overrideWith(
            (ref) async => MatchesResponse(
              matches: [_match],
              totalCount: 1,
              offset: 0,
              limit: 20,
              hasMore: false,
            ),
          ),
          conversationsProvider.overrideWith((ref) async => [_conversation]),
          profileProvider.overrideWith((ref) async => _profileDetail),
          selectedUserProvider.overrideWith((ref) async => _currentUser),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.light,
          home: SignedInShell(currentUser: _currentUser),
        ),
      ),
    );

    await tester.tap(find.text('Chats'));
    await tester.pumpAndSettle();

    await _captureAndCompare(
      tester,
      scenarioName: 'signed-in shell chats tab',
      goldenFileName: 'shell_chats.png',
    );
  });

  testWidgets('captures the signed-in shell profile tab', (
    WidgetTester tester,
  ) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpVisualHarness(
      tester,
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          backendHealthProvider.overrideWith(
            (ref) async => HealthStatus(
              status: 'ok',
              timestamp: DateTime.parse('2026-04-18T12:00:00Z'),
            ),
          ),
          browseProvider.overrideWith(
            (ref) async => const BrowseResponse(
              candidates: [_candidateUser],
              dailyPick: _dailyPick,
              dailyPickViewed: false,
              locationMissing: false,
            ),
          ),
          matchesProvider.overrideWith(
            (ref) async => MatchesResponse(
              matches: [_match],
              totalCount: 1,
              offset: 0,
              limit: 20,
              hasMore: false,
            ),
          ),
          conversationsProvider.overrideWith((ref) async => [_conversation]),
          profileProvider.overrideWith((ref) async => _profileDetail),
          selectedUserProvider.overrideWith((ref) async => _currentUser),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.light,
          home: SignedInShell(currentUser: _currentUser),
        ),
      ),
    );

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await _captureAndCompare(
      tester,
      scenarioName: 'signed-in shell profile tab',
      goldenFileName: 'shell_profile.png',
    );
  });

  testWidgets('captures the signed-in shell settings tab', (
    WidgetTester tester,
  ) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpVisualHarness(
      tester,
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          backendHealthProvider.overrideWith(
            (ref) async => HealthStatus(
              status: 'ok',
              timestamp: DateTime.parse('2026-04-18T12:00:00Z'),
            ),
          ),
          browseProvider.overrideWith(
            (ref) async => const BrowseResponse(
              candidates: [_candidateUser],
              dailyPick: _dailyPick,
              dailyPickViewed: false,
              locationMissing: false,
            ),
          ),
          matchesProvider.overrideWith(
            (ref) async => MatchesResponse(
              matches: [_match],
              totalCount: 1,
              offset: 0,
              limit: 20,
              hasMore: false,
            ),
          ),
          conversationsProvider.overrideWith((ref) async => [_conversation]),
          profileProvider.overrideWith((ref) async => _profileDetail),
          selectedUserProvider.overrideWith((ref) async => _currentUser),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.light,
          home: SignedInShell(currentUser: _currentUser),
        ),
      ),
    );

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await _captureAndCompare(
      tester,
      scenarioName: 'signed-in shell settings tab',
      goldenFileName: 'shell_settings.png',
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
          sharedPreferencesProvider.overrideWithValue(preferences),
          selectedUserProvider.overrideWith((ref) async => _currentUser),
          conversationThreadProvider(
            _conversation.id,
          ).overrideWith((ref) async => _conversationMessages),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.light,
          home: ConversationThreadScreen(
            currentUser: _currentUser,
            conversation: _conversation,
            refreshInterval: Duration.zero,
          ),
        ),
      ),
    );

    await _captureAndCompare(
      tester,
      scenarioName: 'populated conversation thread',
      goldenFileName: 'conversation_thread.png',
    );
  });
}

const _goldenRootKey = ValueKey<String>('visual-review-root');

const _currentUser = UserSummary(
  id: '11111111-1111-1111-1111-111111111111',
  name: 'Dana',
  age: 27,
  state: 'ACTIVE',
);

const _candidateUser = BrowseCandidate(
  id: '22222222-2222-2222-2222-222222222222',
  name: 'Noa',
  age: 29,
  state: 'ACTIVE',
);

const _dailyPick = DailyPick(
  userId: '33333333-3333-3333-3333-333333333333',
  userName: 'Maya',
  userAge: 30,
  date: '2026-04-18',
  reason: 'High compatibility',
  alreadySeen: false,
);

final _match = MatchSummary(
  matchId:
      '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
  otherUserId: '22222222-2222-2222-2222-222222222222',
  otherUserName: 'Noa',
  state: 'ACTIVE',
  createdAt: DateTime.parse('2026-04-18T14:00:00Z'),
);

final _conversation = ConversationSummary(
  id: '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
  otherUserId: '22222222-2222-2222-2222-222222222222',
  otherUserName: 'Noa',
  messageCount: 2,
  lastMessageAt: DateTime.parse('2026-04-18T14:20:00Z'),
);

final _conversationMessages = [
  MessageDto(
    id: 'message-1',
    conversationId:
        '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
    senderId: '22222222-2222-2222-2222-222222222222',
    content: 'Hey Dana',
    sentAt: DateTime.parse('2026-04-18T14:18:00Z'),
  ),
  MessageDto(
    id: 'message-2',
    conversationId:
        '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
    senderId: _currentUser.id,
    content: 'Hey Noa, want to grab coffee this week?',
    sentAt: DateTime.parse('2026-04-18T14:20:00Z'),
  ),
];

final _profileDetail = UserDetail(
  id: '11111111-1111-1111-1111-111111111111',
  name: 'Dana',
  age: 27,
  bio: 'Loves coffee, beach walks, and polished UI states.',
  gender: 'FEMALE',
  interestedIn: ['MALE'],
  approximateLocation: 'Tel Aviv',
  maxDistanceKm: 50,
  photoUrls: ['/photos/dana-1.jpg'],
  state: 'ACTIVE',
);

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

Future<void> _captureAndCompare(
  WidgetTester tester, {
  required String scenarioName,
  required String goldenFileName,
}) async {
  final GoldenFileComparator comparator = goldenFileComparator;
  if (comparator is VisualReviewArtifactComparator) {
    comparator.registerScenario(
      goldenFileName: goldenFileName,
      scenarioName: scenarioName,
    );
  }

  await expectLater(
    find.byKey(_goldenRootKey),
    matchesGoldenFile('goldens/$goldenFileName'),
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
