import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/browse/pending_likers_provider.dart';
import 'package:flutter_dating_application_1/features/browse/pending_likers_screen.dart';
import 'package:flutter_dating_application_1/features/profile/profile_provider.dart';
import 'package:flutter_dating_application_1/models/pending_liker.dart';
import 'package:flutter_dating_application_1/models/profile_presentation_context.dart';
import 'package:flutter_dating_application_1/models/user_detail.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';

void main() {
  const currentUser = UserSummary(
    id: '11111111-1111-1111-1111-111111111111',
    name: 'Dana',
    age: 27,
    state: 'ACTIVE',
  );

  const noaPresentationContext = ProfilePresentationContext(
    viewerUserId: '11111111-1111-1111-1111-111111111111',
    targetUserId: '22222222-2222-2222-2222-222222222222',
    summary: 'Shown because you both enjoy quiet museum dates.',
    reasonTags: ['NEARBY', 'SHARED_INTERESTS'],
    details: ['Both profiles mention museums and calm coffee spots.'],
    generatedAt: '2026-04-23T12:00:00Z',
  );

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
        overrides: [
          pendingLikersProvider.overrideWith((ref) async => likers),
          selectedUserProvider.overrideWith((ref) async => currentUser),
        ],
        child: const MaterialApp(home: PendingLikersScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open their profile to learn more.'), findsNothing);
    expect(find.text('Already interested'), findsOneWidget);
    expect(find.text('2 people waiting'), findsOneWidget);
    expect(find.text('Tap a profile for a closer look.'), findsOneWidget);
    expect(find.text('“Museum dates and quiet coffee.”'), findsOneWidget);
    expect(find.text('“Beach walks and strong espresso.”'), findsOneWidget);
    expect(find.text('Liked Apr 18, 2026'), findsOneWidget);
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
    expect(find.byTooltip('More actions for Noa'), findsOneWidget);
    expect(find.byTooltip('More actions for Maya'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(2));
    expect(find.widgetWithText(FilledButton, 'Open profile'), findsNothing);
    expect(find.text('Open profile'), findsNWidgets(2));
  });

  testWidgets('opens a liker profile from the card CTA', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pendingLikersProvider.overrideWith((ref) async => [datedLiker]),
          selectedUserProvider.overrideWith((ref) async => currentUser),
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
          presentationContextProvider(
            datedLiker.userId,
          ).overrideWith((ref) async => noaPresentationContext),
        ],
        child: const MaterialApp(home: PendingLikersScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open profile').first);
    await tester.pumpAndSettle();

    expect(find.text('Always up for a museum date.'), findsOneWidget);
    expect(find.text('Why this profile is shown'), findsOneWidget);
    expect(
      find.text('Shown because you both enjoy quiet museum dates.'),
      findsOneWidget,
    );
  });
}
