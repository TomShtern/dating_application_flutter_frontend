import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/features/chat/conversation_thread_provider.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/matches/matches_provider.dart';
import 'package:flutter_dating_application_1/features/matches/matches_screen.dart';
import 'package:flutter_dating_application_1/models/match_quality.dart';
import 'package:flutter_dating_application_1/features/profile/profile_provider.dart';
import 'package:flutter_dating_application_1/models/match_summary.dart';
import 'package:flutter_dating_application_1/models/matches_response.dart';
import 'package:flutter_dating_application_1/models/message_dto.dart';
import 'package:flutter_dating_application_1/models/user_detail.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';

void main() {
  const currentUser = UserSummary(
    id: '11111111-1111-1111-1111-111111111111',
    name: 'Dana',
    age: 27,
    state: 'ACTIVE',
  );

  final match = MatchSummary(
    matchId:
        '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
    otherUserId: '22222222-2222-2222-2222-222222222222',
    otherUserName: 'Noa',
    state: 'ACTIVE',
    createdAt: DateTime.parse('2026-04-18T12:34:56Z'),
    primaryPhotoUrl: '/photos/noa-1.jpg',
    photoUrls: const ['/photos/noa-1.jpg'],
    approximateLocation: 'Haifa',
    summaryLine: 'Museum dates and quiet coffee.',
  );

  testWidgets('opens the conversation thread when a match card is tapped', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedUserProvider.overrideWith((ref) async => currentUser),
          matchesProvider.overrideWith(
            (ref) async => MatchesResponse(
              matches: [match],
              totalCount: 1,
              offset: 0,
              limit: 20,
              hasMore: false,
            ),
          ),
          conversationThreadProvider(
            match.matchId,
          ).overrideWith((ref) async => <MessageDto>[]),
        ],
        child: MaterialApp(home: MatchesScreen(currentUser: currentUser)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your matches'), findsOneWidget);
    expect(find.text('1 match ready · 0 new today'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
    expect(find.text('Active now'), findsWidgets);
    expect(find.text('Matches ready for a first hello'), findsNothing);
    expect(find.text('Noa'), findsOneWidget);
    expect(find.textContaining('Active now'), findsWidgets);
    expect(find.text('ACTIVE'), findsNothing);
    expect(find.text('For Dana'), findsNothing);
    expect(find.text('Ready to message'), findsNothing);
    expect(find.text('Message'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'View profile'), findsNothing);

    await tester.tap(find.text('Message').first);
    await tester.pumpAndSettle();

    expect(find.text('Conversation'), findsOneWidget);
    expect(find.text('No messages yet'), findsOneWidget);
  });

  testWidgets('opens the matched user profile from the tappable profile area', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedUserProvider.overrideWith((ref) async => currentUser),
          matchesProvider.overrideWith(
            (ref) async => MatchesResponse(
              matches: [match],
              totalCount: 1,
              offset: 0,
              limit: 20,
              hasMore: false,
            ),
          ),
          otherUserProfileProvider(match.otherUserId).overrideWith(
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
        child: MaterialApp(home: MatchesScreen(currentUser: currentUser)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ValueKey('match-profile-${match.matchId}')));
    await tester.pumpAndSettle();

    expect(find.text('Always up for a museum date.'), findsOneWidget);
  });

  testWidgets('opens safety actions for a match', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedUserProvider.overrideWith((ref) async => currentUser),
          matchesProvider.overrideWith(
            (ref) async => MatchesResponse(
              matches: [match],
              totalCount: 1,
              offset: 0,
              limit: 20,
              hasMore: false,
            ),
          ),
        ],
        child: MaterialApp(home: MatchesScreen(currentUser: currentUser)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Safety actions'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Safety actions').last);
    await tester.pumpAndSettle();

    expect(find.text('Block user'), findsOneWidget);
    expect(find.text('Report user'), findsOneWidget);
    expect(find.text('Unmatch'), findsOneWidget);
  });

  testWidgets('renders a dedicated media panel for match cards', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedUserProvider.overrideWith((ref) async => currentUser),
          matchesProvider.overrideWith(
            (ref) async => MatchesResponse(
              matches: [match],
              totalCount: 1,
              offset: 0,
              limit: 20,
              hasMore: false,
            ),
          ),
        ],
        child: MaterialApp(home: MatchesScreen(currentUser: currentUser)),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(ValueKey('match-profile-${match.matchId}')),
      findsOneWidget,
    );
    expect(find.byType(CircleAvatar), findsNothing);
  });

  testWidgets('does not surface a fake Why we match CTA', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeMatchesApiClient(
      matchQuality: MatchQuality.fromJson({
        'matchId': match.matchId,
        'perspectiveUserId': currentUser.id,
        'otherUserId': match.otherUserId,
        'compatibilityScore': 85,
        'compatibilityLabel': 'Great Match',
        'starDisplay': '⭐⭐⭐⭐',
        'paceSyncLevel': 'Good Sync',
        'distanceKm': 12.4,
        'ageDifference': 2,
        'highlights': [
          'Lives nearby (12.4 km away)',
          'You both enjoy Hiking',
          'Great communication sync',
        ],
      }),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          selectedUserProvider.overrideWith((ref) async => currentUser),
          matchesProvider.overrideWith(
            (ref) async => MatchesResponse(
              matches: [match],
              totalCount: 1,
              offset: 0,
              limit: 20,
              hasMore: false,
            ),
          ),
        ],
        child: MaterialApp(home: MatchesScreen(currentUser: currentUser)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Why we match'), findsNothing);
    expect(find.text('Great Match'), findsNothing);
    expect(apiClient.getMatchQualityCalls, 0);
  });
}

class _FakeMatchesApiClient extends ApiClient {
  _FakeMatchesApiClient({required this.matchQuality}) : super(dio: Dio());

  final MatchQuality matchQuality;
  int getMatchQualityCalls = 0;

  @override
  Future<MatchQuality> getMatchQuality({
    required String userId,
    required String matchId,
  }) async {
    getMatchQualityCalls++;
    return matchQuality;
  }
}
