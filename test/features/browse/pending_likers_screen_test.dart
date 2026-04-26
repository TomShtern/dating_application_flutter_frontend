import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/features/browse/pending_likers_provider.dart';
import 'package:flutter_dating_application_1/features/browse/pending_likers_screen.dart';
import 'package:flutter_dating_application_1/features/profile/profile_provider.dart';
import 'package:flutter_dating_application_1/models/pending_liker.dart';
import 'package:flutter_dating_application_1/models/user_detail.dart';

void main() {
  const datedLiker = PendingLiker(
    userId: '22222222-2222-2222-2222-222222222222',
    name: 'Noa',
    age: 29,
    likedAt: null,
    primaryPhotoUrl: '/photos/noa-1.jpg',
    photoUrls: ['/photos/noa-1.jpg'],
    approximateLocation: 'Haifa',
    summaryLine: 'Museum dates and quiet coffee.',
  );

  final likers = <PendingLiker>[
    PendingLiker(
      userId: '22222222-2222-2222-2222-222222222222',
      name: 'Noa',
      age: 29,
      likedAt: DateTime(2026, 4, 18, 14, 20),
      primaryPhotoUrl: '/photos/noa-1.jpg',
      photoUrls: const ['/photos/noa-1.jpg'],
      approximateLocation: 'Haifa',
      summaryLine: 'Museum dates and quiet coffee.',
    ),
    const PendingLiker(
      userId: '33333333-3333-3333-3333-333333333333',
      name: 'Maya',
      age: 31,
      likedAt: null,
      primaryPhotoUrl: '/photos/maya-1.jpg',
      photoUrls: ['/photos/maya-1.jpg'],
      approximateLocation: 'Tel Aviv',
      summaryLine: 'Beach walks and strong espresso.',
    ),
  ];

  testWidgets('varies support copy and uses a single clear CTA per card', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [pendingLikersProvider.overrideWith((ref) async => likers)],
        child: const MaterialApp(home: PendingLikersScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open their profile to learn more.'), findsNothing);
    expect(
      find.text('Noa made the first move on Apr 18, 2026.'),
      findsOneWidget,
    );
    expect(find.text('Maya is one of your newest likes.'), findsOneWidget);
    expect(find.text('Liked Apr 18, 2026'), findsOneWidget);
    expect(find.text('Recent like'), findsOneWidget);
    expect(
      find.text(
        'Liked your profile on Apr 18, 2026. Open it when you want a closer look.',
      ),
      findsNothing,
    );
    expect(
      find.text(
        'They liked your profile recently. Open it when you want a closer look.',
      ),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey('pending-liker-media-${likers.first.userId}')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Open profile'), findsNWidgets(2));
  });

  testWidgets('opens a liker profile from the card CTA', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pendingLikersProvider.overrideWith((ref) async => [datedLiker]),
          otherUserProfileProvider(datedLiker.userId).overrideWith(
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
        child: const MaterialApp(home: PendingLikersScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Open profile'));
    await tester.pumpAndSettle();

    expect(find.text('Always up for a museum date.'), findsOneWidget);
  });
}
