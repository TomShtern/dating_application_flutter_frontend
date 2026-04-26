import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/features/browse/standouts_provider.dart';
import 'package:flutter_dating_application_1/features/browse/standouts_screen.dart';
import 'package:flutter_dating_application_1/features/profile/profile_provider.dart';
import 'package:flutter_dating_application_1/models/standout.dart';
import 'package:flutter_dating_application_1/models/user_detail.dart';

void main() {
  const standout = Standout(
    id: 'standout-1',
    standoutUserId: '22222222-2222-2222-2222-222222222222',
    standoutUserName: 'Noa',
    standoutUserAge: 29,
    rank: 1,
    score: 97,
    reason: 'Server says you both prioritize thoughtful conversation.',
    createdAt: null,
    interactedAt: null,
    primaryPhotoUrl: '/photos/noa-1.jpg',
    photoUrls: ['/photos/noa-1.jpg'],
    approximateLocation: 'Haifa',
    summaryLine: 'Museum dates and quiet coffee.',
  );

  const snapshot = StandoutsSnapshot(
    standouts: [standout],
    totalCandidates: 1,
    fromCache: false,
    message: 'Backend rank suggests high reply odds this week',
  );

  testWidgets(
    'renders server-provided standout copy and keeps one clear profile action',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [standoutsProvider.overrideWith((ref) async => snapshot)],
          child: const MaterialApp(home: StandoutsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Backend rank suggests high reply odds this week'),
        findsOneWidget,
      );
      expect(
        find.text('Server says you both prioritize thoughtful conversation.'),
        findsOneWidget,
      );
      expect(find.text('Haifa'), findsOneWidget);
      expect(find.text('Museum dates and quiet coffee.'), findsOneWidget);
      expect(find.text('Rank #1'), findsNothing);
      expect(find.text('Score 97'), findsNothing);
      expect(find.text('#1 · 97 points'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
      expect(find.widgetWithText(TextButton, 'Open profile'), findsOneWidget);
    },
  );

  testWidgets('opens the standout profile from the card CTA', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          standoutsProvider.overrideWith((ref) async => snapshot),
          otherUserProfileProvider(standout.standoutUserId).overrideWith(
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
        child: const MaterialApp(home: StandoutsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Open profile'));
    await tester.pumpAndSettle();

    expect(find.text('Always up for a museum date.'), findsOneWidget);
  });
}
