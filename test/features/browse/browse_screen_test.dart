import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/browse/browse_screen.dart';
import 'package:flutter_dating_application_1/features/chat/conversation_thread_provider.dart';
import 'package:flutter_dating_application_1/features/home/backend_health_provider.dart';
import 'package:flutter_dating_application_1/models/browse_candidate.dart';
import 'package:flutter_dating_application_1/models/browse_response.dart';
import 'package:flutter_dating_application_1/models/health_status.dart';
import 'package:flutter_dating_application_1/models/like_result.dart';
import 'package:flutter_dating_application_1/models/message_dto.dart';
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

  testWidgets('offers a message handoff when a like becomes a match', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeBrowseApiClient(
      browseResponse: const BrowseResponse(
        candidates: [candidate],
        dailyPick: null,
        dailyPickViewed: false,
        locationMissing: false,
      ),
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
          selectedUserProvider.overrideWith((ref) async => currentUser),
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
}

class _FakeBrowseApiClient extends ApiClient {
  _FakeBrowseApiClient({required this.browseResponse, required this.likeResult})
    : super(dio: Dio());

  final BrowseResponse browseResponse;
  final LikeResult likeResult;

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
}
