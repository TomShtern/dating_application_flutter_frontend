import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/browse/pending_likers_provider.dart';
import 'package:flutter_dating_application_1/features/browse/pending_likers_screen.dart';
import 'package:flutter_dating_application_1/features/browse/browse_provider.dart';
import 'package:flutter_dating_application_1/features/browse/standouts_provider.dart';
import 'package:flutter_dating_application_1/features/browse/standouts_screen.dart';
import 'package:flutter_dating_application_1/features/chat/conversation_thread_provider.dart';
import 'package:flutter_dating_application_1/features/chat/conversation_thread_screen.dart';
import 'package:flutter_dating_application_1/features/chat/conversations_provider.dart';
import 'package:flutter_dating_application_1/features/home/app_home_screen.dart';
import 'package:flutter_dating_application_1/features/home/backend_health_provider.dart';
import 'package:flutter_dating_application_1/features/home/signed_in_shell.dart';
import 'package:flutter_dating_application_1/features/location/location_completion_screen.dart';
import 'package:flutter_dating_application_1/features/location/location_provider.dart';
import 'package:flutter_dating_application_1/features/matches/matches_provider.dart';
import 'package:flutter_dating_application_1/features/notifications/notifications_provider.dart';
import 'package:flutter_dating_application_1/features/notifications/notifications_screen.dart';
import 'package:flutter_dating_application_1/features/profile/profile_edit_screen.dart';
import 'package:flutter_dating_application_1/features/profile/profile_provider.dart';
import 'package:flutter_dating_application_1/features/profile/profile_screen.dart';
import 'package:flutter_dating_application_1/features/safety/blocked_users_provider.dart';
import 'package:flutter_dating_application_1/features/safety/blocked_users_screen.dart';
import 'package:flutter_dating_application_1/features/settings/app_preferences_store.dart';
import 'package:flutter_dating_application_1/features/stats/stats_provider.dart';
import 'package:flutter_dating_application_1/features/stats/stats_screen.dart';
import 'package:flutter_dating_application_1/features/stats/achievements_screen.dart';
import 'package:flutter_dating_application_1/features/verification/verification_screen.dart';
import 'package:flutter_dating_application_1/models/app_preferences.dart';
import 'package:flutter_dating_application_1/models/achievement_summary.dart';
import 'package:flutter_dating_application_1/models/blocked_user_summary.dart';
import 'package:flutter_dating_application_1/models/browse_candidate.dart';
import 'package:flutter_dating_application_1/models/browse_response.dart';
import 'package:flutter_dating_application_1/models/conversation_summary.dart';
import 'package:flutter_dating_application_1/models/daily_pick.dart';
import 'package:flutter_dating_application_1/models/health_status.dart';
import 'package:flutter_dating_application_1/models/location_metadata.dart';
import 'package:flutter_dating_application_1/models/match_summary.dart';
import 'package:flutter_dating_application_1/models/matches_response.dart';
import 'package:flutter_dating_application_1/models/message_dto.dart';
import 'package:flutter_dating_application_1/models/notification_item.dart';
import 'package:flutter_dating_application_1/models/pending_liker.dart';
import 'package:flutter_dating_application_1/models/standout.dart';
import 'package:flutter_dating_application_1/models/user_detail.dart';
import 'package:flutter_dating_application_1/models/user_stats.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';
import 'package:flutter_dating_application_1/shared/persistence/shared_preferences_provider.dart';
import 'package:flutter_dating_application_1/theme/app_theme.dart';

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
      overrides: [
        standoutsProvider.overrideWith((ref) async => _standoutsSnapshot),
      ],
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
      overrides: [
        pendingLikersProvider.overrideWith((ref) async => _pendingLikers),
      ],
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
      overrides: [
        otherUserProfileProvider(
          _otherUserProfileDetail.id,
        ).overrideWith((ref) async => _otherUserProfileDetail),
      ],
      child: ProfileScreen.otherUser(
        userId: _otherUserProfileDetail.id,
        userName: _otherUserProfileDetail.name,
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
      child: ProfileEditScreen(initialDetail: _profileDetail),
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
      overrides: [
        locationCountriesProvider.overrideWith(
          (ref) async => _locationCountries,
        ),
        locationCitySuggestionsProvider(
          const LocationCitySearchQuery(countryCode: 'IL', query: 'Tel'),
        ).overrideWith((ref) async => _locationSuggestions),
      ],
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
      overrides: [statsProvider.overrideWith((ref) async => _userStats)],
      child: const StatsScreen(currentUser: _currentUser),
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
      overrides: [
        achievementsProvider.overrideWith((ref) async => _achievements),
      ],
      child: const AchievementsScreen(currentUser: _currentUser),
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
      overrides: [
        blockedUsersProvider.overrideWith((ref) async => _blockedUsers),
      ],
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
      overrides: [
        notificationsProvider.overrideWith((ref) async => _notifications),
      ],
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

final _otherUserProfileDetail = UserDetail(
  id: '44444444-4444-4444-4444-444444444444',
  name: 'Rin',
  age: 28,
  bio: 'Weekend climber, playlists curator, and unapologetic brunch optimist.',
  gender: 'FEMALE',
  interestedIn: ['FEMALE', 'MALE'],
  approximateLocation: 'Haifa',
  maxDistanceKm: 30,
  photoUrls: const [],
  state: 'ACTIVE',
);

const _standoutsSnapshot = StandoutsSnapshot(
  standouts: [
    Standout(
      id: 'standout-1',
      standoutUserId: '55555555-5555-5555-5555-555555555555',
      standoutUserName: 'Leah',
      standoutUserAge: 31,
      rank: 1,
      score: 98,
      reason:
          'Shared pace, music taste, and a strong match on conversation style.',
      createdAt: null,
      interactedAt: null,
    ),
    Standout(
      id: 'standout-2',
      standoutUserId: '66666666-6666-6666-6666-666666666666',
      standoutUserName: 'Ari',
      standoutUserAge: 29,
      rank: 2,
      score: 94,
      reason: 'Backend rank suggests high reply odds this week.',
      createdAt: null,
      interactedAt: null,
    ),
  ],
  totalCandidates: 2,
  fromCache: false,
  message: 'Fresh standout picks based on current activity.',
);

const _pendingLikers = [
  PendingLiker(
    userId: '77777777-7777-7777-7777-777777777777',
    name: 'Nina',
    age: 26,
    likedAt: null,
  ),
  PendingLiker(
    userId: '88888888-8888-8888-8888-888888888888',
    name: 'Omer',
    age: 30,
    likedAt: null,
  ),
];

const _locationCountries = [
  LocationCountry(
    code: 'IL',
    name: 'Israel',
    flagEmoji: '🇮🇱',
    available: true,
    defaultSelection: true,
  ),
  LocationCountry(
    code: 'US',
    name: 'United States',
    flagEmoji: '🇺🇸',
    available: true,
    defaultSelection: false,
  ),
];

const _locationSuggestions = [
  LocationCity(
    name: 'Tel Aviv',
    district: 'Tel Aviv District',
    countryCode: 'IL',
    priority: 1,
  ),
  LocationCity(
    name: 'Tel Mond',
    district: 'Central District',
    countryCode: 'IL',
    priority: 2,
  ),
];

const _userStats = UserStats(
  items: [
    UserStatItem(label: 'Likes sent', value: '18'),
    UserStatItem(label: 'Matches this week', value: '4'),
    UserStatItem(label: 'Conversation reply rate', value: '87%'),
  ],
);

const _achievements = [
  AchievementSummary(
    title: 'First match streak',
    subtitle: 'Matched with someone three days in a row',
    progress: '3 / 3',
    isUnlocked: true,
  ),
  AchievementSummary(
    title: 'Conversation closer',
    subtitle: 'Keep reply rates above 80%',
    progress: '87%',
    isUnlocked: false,
  ),
];

const _blockedUsers = [
  BlockedUserSummary(
    userId: '99999999-9999-9999-9999-999999999999',
    name: 'Kai',
    statusLabel: 'Blocked after repeated spam',
  ),
];

final _notifications = [
  NotificationItem(
    id: 'notification-1',
    type: 'MATCH',
    title: 'New match',
    message: 'You and Maya matched a few minutes ago.',
    createdAt: DateTime.parse('2026-04-20T15:55:00Z'),
    isRead: false,
    data: const {'matchId': 'match-2'},
  ),
  NotificationItem(
    id: 'notification-2',
    type: 'MESSAGE',
    title: 'New message from Noa',
    message: 'Noa replied and wants to plan the coffee date.',
    createdAt: DateTime.parse('2026-04-20T15:59:00Z'),
    isRead: true,
    data: const {'conversationId': 'conversation-1'},
  ),
];

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
}

Future<void> _pumpSignedInVisualScreen(
  WidgetTester tester, {
  required SharedPreferences preferences,
  required Widget child,
  List overrides = const <dynamic>[],
}) async {
  await _pumpVisualHarness(
    tester,
    child: ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        selectedUserProvider.overrideWith((ref) async => _currentUser),
        ...overrides,
      ],
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
