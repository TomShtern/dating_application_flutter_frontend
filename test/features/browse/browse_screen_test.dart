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
import 'package:flutter_dating_application_1/models/health_status.dart';
import 'package:flutter_dating_application_1/models/like_result.dart';
import 'package:flutter_dating_application_1/models/message_dto.dart';
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

    expect(find.widgetWithText(AppBar, 'Noa'), findsOneWidget);
    expect(
      find.text('No messages yet. Say hello to start the conversation.'),
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

    final viewProfileButton = find.widgetWithText(
      OutlinedButton,
      'View profile',
    );
    await tester.ensureVisible(viewProfileButton);
    await tester.pumpAndSettle();
    await tester.tap(viewProfileButton);
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
    await tester.tap(safetyActionsButton, warnIfMissed: false);
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

  testWidgets('removes developer-facing copy from the candidate card', (
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
      find.textContaining('browse payload is intentionally lean'),
      findsNothing,
    );
    expect(find.text('View profile'), findsOneWidget);
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
}
