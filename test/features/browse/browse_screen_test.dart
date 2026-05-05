import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/browse/browse_screen.dart';
import 'package:flutter_dating_application_1/features/browse/browse_provider.dart';
import 'package:flutter_dating_application_1/features/chat/conversation_thread_provider.dart';
import 'package:flutter_dating_application_1/features/home/backend_health_provider.dart';
import 'package:flutter_dating_application_1/features/profile/profile_provider.dart';
import 'package:flutter_dating_application_1/shared/persistence/shared_preferences_provider.dart';
import 'package:flutter_dating_application_1/models/browse_candidate.dart';
import 'package:flutter_dating_application_1/models/browse_response.dart';
import 'package:flutter_dating_application_1/models/daily_pick.dart';
import 'package:flutter_dating_application_1/models/health_status.dart';
import 'package:flutter_dating_application_1/models/like_result.dart';
import 'package:flutter_dating_application_1/models/message_dto.dart';
import 'package:flutter_dating_application_1/models/profile_presentation_context.dart';
import 'package:flutter_dating_application_1/models/undo_swipe_result.dart';
import 'package:flutter_dating_application_1/models/user_detail.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';

void main() {
  const currentUser = UserSummary(
    id: '11111111-1111-1111-1111-111111111111',
    name: 'Dana',
    age: 27,
    state: 'ACTIVE',
  );

  const candidate = BrowseCandidate(
    id: '22222222-2222-2222-2222-222222222222',
    name: 'Noa',
    age: 29,
    state: 'ACTIVE',
    primaryPhotoUrl: '/photos/noa-1.jpg',
    photoUrls: ['/photos/noa-1.jpg'],
    approximateLocation: 'Haifa',
    summaryLine: 'Museum dates and quiet coffee.',
  );

  const matchId =
      '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222';

  const browseResponse = BrowseResponse(
    candidates: [candidate],
    dailyPick: null,
    dailyPickViewed: false,
    locationMissing: false,
  );

  testWidgets('offers a message handoff when a like becomes a match', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    final apiClient = _FakeBrowseApiClient(
      browseResponse: browseResponse,
      likeResult: const LikeResult(
        isMatch: true,
        message: 'It\'s a match!',
        matchedUserName: 'Noa',
        matchId: matchId,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          sharedPreferencesProvider.overrideWithValue(preferences),
          selectedUserProvider.overrideWith((ref) async => currentUser),
          browseProvider.overrideWith((ref) async => browseResponse),
          backendHealthProvider.overrideWith(
            (ref) async =>
                HealthStatus(status: 'ok', timestamp: DateTime(2026, 4, 19, 9)),
          ),
          conversationThreadProvider(
            matchId,
          ).overrideWith((ref) async => <MessageDto>[]),
        ],
        child: const MaterialApp(home: BrowseScreen(currentUser: currentUser)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Noa'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Like'));
    await tester.pumpAndSettle();

    expect(find.text('Message now'), findsOneWidget);

    await tester.tap(find.text('Message now'));
    await tester.pumpAndSettle();

    expect(find.text('Conversation'), findsOneWidget);
    expect(find.text('No messages yet'), findsOneWidget);
    expect(
      find.text('Start the conversation with Noa when you\'re ready.'),
      findsOneWidget,
    );
  });

  testWidgets('opens the viewed candidate profile from browse', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    final apiClient = _FakeBrowseApiClient(
      browseResponse: browseResponse,
      likeResult: const LikeResult(isMatch: false, message: 'Like recorded'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          sharedPreferencesProvider.overrideWithValue(preferences),
          selectedUserProvider.overrideWith((ref) async => currentUser),
          browseProvider.overrideWith((ref) async => browseResponse),
          backendHealthProvider.overrideWith(
            (ref) async =>
                HealthStatus(status: 'ok', timestamp: DateTime(2026, 4, 19, 9)),
          ),
          otherUserProfileProvider(candidate.id).overrideWith(
            (ref) async => const UserDetail(
              id: '22222222-2222-2222-2222-222222222222',
              name: 'Noa',
              age: 29,
              bio: 'Always up for a museum date.',
              gender: 'FEMALE',
              interestedIn: ['MALE'],
              approximateLocation: 'Haifa',
              maxDistanceKm: 25,
              photoUrls: ['/photos/noa-1.jpg'],
              state: 'ACTIVE',
            ),
          ),
        ],
        child: const MaterialApp(home: BrowseScreen(currentUser: currentUser)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Noa'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Noa'));
    await tester.pumpAndSettle();

    expect(find.text('Always up for a museum date.'), findsOneWidget);
  });

  testWidgets('opens safety actions for the current browse candidate', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    final apiClient = _FakeBrowseApiClient(
      browseResponse: browseResponse,
      likeResult: const LikeResult(isMatch: false, message: 'Like recorded'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          sharedPreferencesProvider.overrideWithValue(preferences),
          selectedUserProvider.overrideWith((ref) async => currentUser),
          browseProvider.overrideWith((ref) async => browseResponse),
          backendHealthProvider.overrideWith(
            (ref) async =>
                HealthStatus(status: 'ok', timestamp: DateTime(2026, 4, 19, 9)),
          ),
        ],
        child: const MaterialApp(home: BrowseScreen(currentUser: currentUser)),
      ),
    );
    await tester.pumpAndSettle();

    final safetyActionsButton = find.byTooltip('Safety actions');
    await tester.ensureVisible(safetyActionsButton);
    await tester.pumpAndSettle();
    expect(safetyActionsButton, findsOneWidget);
    await tester.tap(safetyActionsButton);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Safety actions').last);
    await tester.pumpAndSettle();

    expect(find.text('Block user'), findsOneWidget);
    expect(find.text('Report user'), findsOneWidget);
    expect(find.text('Unmatch'), findsNothing);
  });

  testWidgets('offers an undo action and shows the backend message', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    final apiClient = _FakeBrowseApiClient(
      browseResponse: browseResponse,
      likeResult: const LikeResult(isMatch: false, message: 'Like recorded'),
      undoResult: const UndoSwipeResult(
        success: true,
        message: 'Last swipe undone',
        matchDeleted: false,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          sharedPreferencesProvider.overrideWithValue(preferences),
          selectedUserProvider.overrideWith((ref) async => currentUser),
          browseProvider.overrideWith((ref) async => browseResponse),
          backendHealthProvider.overrideWith(
            (ref) async =>
                HealthStatus(status: 'ok', timestamp: DateTime(2026, 4, 19, 9)),
          ),
        ],
        child: const MaterialApp(home: BrowseScreen(currentUser: currentUser)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Undo last swipe'));
    await tester.pumpAndSettle();

    expect(find.text('Last swipe undone'), findsOneWidget);
  });

  testWidgets('keeps discover chrome concise around the candidate card', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    final apiClient = _FakeBrowseApiClient(
      browseResponse: browseResponse,
      likeResult: const LikeResult(isMatch: false, message: 'Like recorded'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          sharedPreferencesProvider.overrideWithValue(preferences),
          selectedUserProvider.overrideWith((ref) async => currentUser),
          browseProvider.overrideWith((ref) async => browseResponse),
          backendHealthProvider.overrideWith(
            (ref) async =>
                HealthStatus(status: 'ok', timestamp: DateTime(2026, 4, 19, 9)),
          ),
        ],
        child: const MaterialApp(home: BrowseScreen(currentUser: currentUser)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Meet people worth your next hello'), findsNothing);
    expect(
      find.text(
        'Fresh picks, standout profiles, and a quicker path to like or pass.',
      ),
      findsNothing,
    );
    expect(find.text('1 ready'), findsOneWidget);
    expect(find.text('Session details'), findsNothing);
    expect(find.text('Active profile'), findsNothing);
    expect(find.textContaining('backend-driven'), findsNothing);
    expect(
      find.textContaining('browse payload is intentionally lean'),
      findsNothing,
    );
    expect(
      find.textContaining(
        'Take a quick look, then like, pass, or open the full profile before you decide.',
      ),
      findsNothing,
    );
    expect(find.text('Discover'), findsOneWidget);
    expect(find.byType(InkWell), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Why this profile is shown'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Why this profile is shown'), findsOneWidget);
    expect(find.text('Shown because this profile is nearby.'), findsOneWidget);
  });

  testWidgets('renders a dedicated media panel for the current candidate', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    final apiClient = _FakeBrowseApiClient(
      browseResponse: browseResponse,
      likeResult: const LikeResult(isMatch: false, message: 'Like recorded'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          sharedPreferencesProvider.overrideWithValue(preferences),
          selectedUserProvider.overrideWith((ref) async => currentUser),
          browseProvider.overrideWith((ref) async => browseResponse),
          backendHealthProvider.overrideWith(
            (ref) async =>
                HealthStatus(status: 'ok', timestamp: DateTime(2026, 4, 19, 9)),
          ),
        ],
        child: const MaterialApp(home: BrowseScreen(currentUser: currentUser)),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(ValueKey('browse-candidate-media-${candidate.id}')),
      findsOneWidget,
    );
  });

  testWidgets('shows daily pick presentation context from the backend', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    const dailyPickResponse = BrowseResponse(
      candidates: [],
      dailyPick: DailyPick(
        userId: '22222222-2222-2222-2222-222222222222',
        userName: 'Noa',
        userAge: 29,
        date: '2026-05-08',
        reason: 'legacy reason should not render',
        alreadySeen: false,
      ),
      dailyPickViewed: false,
      locationMissing: false,
    );
    final apiClient = _FakeBrowseApiClient(
      browseResponse: dailyPickResponse,
      likeResult: const LikeResult(isMatch: false, message: 'Like recorded'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          sharedPreferencesProvider.overrideWithValue(preferences),
          selectedUserProvider.overrideWith((ref) async => currentUser),
          browseProvider.overrideWith((ref) async => dailyPickResponse),
          backendHealthProvider.overrideWith(
            (ref) async =>
                HealthStatus(status: 'ok', timestamp: DateTime(2026, 4, 19, 9)),
          ),
        ],
        child: const MaterialApp(home: BrowseScreen(currentUser: currentUser)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today\'s daily pick'), findsWidgets);
    expect(find.text('Featured for today'), findsOneWidget);
    expect(find.text('legacy reason should not render'), findsNothing);
  });

  testWidgets('keeps browse diagnostics inside developer-only framing', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    final apiClient = _FakeBrowseApiClient(
      browseResponse: browseResponse,
      likeResult: const LikeResult(isMatch: false, message: 'Like recorded'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          sharedPreferencesProvider.overrideWithValue(preferences),
          selectedUserProvider.overrideWith((ref) async => currentUser),
          browseProvider.overrideWith((ref) async => browseResponse),
          backendHealthProvider.overrideWith(
            (ref) async =>
                HealthStatus(status: 'ok', timestamp: DateTime(2026, 4, 19, 9)),
          ),
        ],
        child: const MaterialApp(home: BrowseScreen(currentUser: currentUser)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Browse diagnostics'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    for (var index = 0; index < 4; index++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -420));
      await tester.pumpAndSettle();
      if (find.text('Browse diagnostics').evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.text('Browse diagnostics'), findsOneWidget);
    expect(find.text('Connection status'), findsOneWidget);

    await tester.tap(find.text('Connection status'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Check connection health without pulling attention away from the next profile.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('supports swiping the candidate card to pass', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    final apiClient = _FakeBrowseApiClient(
      browseResponse: browseResponse,
      likeResult: const LikeResult(isMatch: false, message: 'Like recorded'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          sharedPreferencesProvider.overrideWithValue(preferences),
          selectedUserProvider.overrideWith((ref) async => currentUser),
          browseProvider.overrideWith((ref) async => browseResponse),
          backendHealthProvider.overrideWith(
            (ref) async =>
                HealthStatus(status: 'ok', timestamp: DateTime(2026, 4, 19, 9)),
          ),
        ],
        child: const MaterialApp(home: BrowseScreen(currentUser: currentUser)),
      ),
    );
    await tester.pumpAndSettle();

    final candidateName = find.text(candidate.name).first;
    await tester.ensureVisible(candidateName);
    await tester.pumpAndSettle();
    await tester.drag(
      candidateName,
      const Offset(-500, 0),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(find.text('Passed'), findsOneWidget);
    expect(apiClient.passCalls, 1);
  });
}

class _FakeBrowseApiClient extends ApiClient {
  _FakeBrowseApiClient({
    required this.browseResponse,
    required this.likeResult,
    this.undoResult = const UndoSwipeResult(
      success: true,
      message: 'Last swipe undone',
      matchDeleted: false,
    ),
  }) : super(dio: Dio());

  final BrowseResponse browseResponse;
  final LikeResult likeResult;
  final UndoSwipeResult undoResult;
  int passCalls = 0;

  @override
  Future<BrowseResponse> getBrowse({required String userId}) async {
    return browseResponse;
  }

  @override
  Future<LikeResult> likeUser({
    required String userId,
    required String targetId,
  }) async {
    return likeResult;
  }

  @override
  Future<String> passUser({
    required String userId,
    required String targetId,
  }) async {
    passCalls++;
    return 'Passed';
  }

  @override
  Future<UndoSwipeResult> undoLastSwipe({required String userId}) async {
    return undoResult;
  }

  @override
  Future<ProfilePresentationContext> getProfilePresentationContext({
    required String viewerUserId,
    required String targetUserId,
  }) async {
    return const ProfilePresentationContext(
      viewerUserId: '11111111-1111-1111-1111-111111111111',
      targetUserId: '22222222-2222-2222-2222-222222222222',
      summary: 'Shown because this profile is nearby.',
      reasonTags: ['nearby', 'eligible_match_pool'],
      details: ['This profile is within your preferred distance.'],
      generatedAt: '2026-05-08T10:15:00Z',
    );
  }
}
