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

  Future<void> pumpStandoutsScreen(
    WidgetTester tester, {
    Size size = const Size(412, 915),
    List overrides = const [],
  }) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(size);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          standoutsProvider.overrideWith((ref) async => snapshot),
          ...overrides,
        ],
        child: const MaterialApp(home: StandoutsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'defaults to list view on phone-width screens with a stronger profile CTA',
    (WidgetTester tester) async {
      await pumpStandoutsScreen(tester);

      expect(
        find.text('Backend rank suggests high reply odds this week'),
        findsOneWidget,
      );
      expect(
        find.text('Server says you both prioritize thoughtful conversation.'),
        findsOneWidget,
      );
      expect(find.text('Profiles worth a closer look'), findsNothing);
      expect(find.text('View'), findsOneWidget);
      expect(find.text('Grid'), findsOneWidget);
      expect(find.text('List'), findsOneWidget);
      expect(find.text('Haifa'), findsOneWidget);
      expect(find.text('Museum dates and quiet coffee.'), findsOneWidget);
      expect(find.text('Rank #1'), findsNothing);
      expect(find.text('Score 97'), findsNothing);
      expect(find.byKey(ValueKey('standout-rank-${standout.id}')), findsOneWidget);
      expect(
        find.byKey(ValueKey('standout-media-${standout.id}')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('standouts-list')), findsOneWidget);
      expect(find.byKey(const ValueKey('standouts-grid')), findsNothing);
      expect(find.widgetWithText(TextButton, 'Open profile'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Open profile'), findsOneWidget);
    },
  );

  testWidgets('switches to a true grid layout on phone-width screens', (
    WidgetTester tester,
  ) async {
    await pumpStandoutsScreen(tester);

    await tester.tap(find.text('Grid'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('standouts-grid')), findsOneWidget);
    expect(find.byKey(const ValueKey('standouts-list')), findsNothing);

    final cardSize = tester.getSize(
      find.byKey(ValueKey('standout-card-${standout.id}')),
    );
    expect(cardSize.width, lessThan(220));
  });

  testWidgets('defaults to grid view on wide screens with the same CTA wording', (
    WidgetTester tester,
  ) async {
    await pumpStandoutsScreen(tester, size: const Size(900, 915));

    expect(find.byKey(const ValueKey('standouts-grid')), findsOneWidget);
    expect(find.byKey(const ValueKey('standouts-list')), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Open profile'), findsOneWidget);
  });

  testWidgets('opens the standout profile from the whole card tap target', (
    WidgetTester tester,
  ) async {
    await pumpStandoutsScreen(
      tester,
      overrides: [
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
    );

    await tester.tap(find.byKey(ValueKey('standout-card-${standout.id}')));
    await tester.pumpAndSettle();

    expect(find.text('Always up for a museum date.'), findsOneWidget);
  });
}
