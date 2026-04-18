import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/features/chat/conversation_thread_provider.dart';
import 'package:flutter_dating_application_1/features/matches/matches_provider.dart';
import 'package:flutter_dating_application_1/features/matches/matches_screen.dart';
import 'package:flutter_dating_application_1/models/match_summary.dart';
import 'package:flutter_dating_application_1/models/matches_response.dart';
import 'package:flutter_dating_application_1/models/message_dto.dart';
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
  );

  testWidgets('opens the conversation thread when a match card is tapped', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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
    expect(find.text('Noa'), findsOneWidget);

    await tester.tap(find.widgetWithText(ListTile, 'Noa'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Noa'), findsOneWidget);
    expect(
      find.text('No messages yet. Say hello to start the conversation.'),
      findsOneWidget,
    );
  });
}
