import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/api/api_error.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/profile/profile_edit_screen.dart';
import 'package:flutter_dating_application_1/features/profile/profile_provider.dart';
import 'package:flutter_dating_application_1/models/profile_presentation_context.dart';
import 'package:flutter_dating_application_1/models/profile_edit_snapshot.dart';
import 'package:flutter_dating_application_1/features/profile/profile_screen.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';
import 'package:flutter_dating_application_1/models/user_detail.dart';

void main() {
  const detail = UserDetail(
    id: '11111111-1111-1111-1111-111111111111',
    name: 'Dana',
    age: 27,
    bio: 'Loves coffee and beach walks.',
    gender: 'FEMALE',
    interestedIn: ['MALE'],
    approximateLocation: 'Tel Aviv',
    maxDistanceKm: 50,
    photoUrls: ['/photos/dana-1.jpg'],
    state: 'ACTIVE',
  );

  const sparseDetail = UserDetail(
    id: '22222222-2222-2222-2222-222222222222',
    name: 'Noa',
    age: 29,
    bio: '',
    gender: '',
    interestedIn: [],
    approximateLocation: '',
    maxDistanceKm: 0,
    photoUrls: [],
    state: 'ACTIVE',
  );

  const currentUser = UserSummary(
    id: '33333333-3333-3333-3333-333333333333',
    name: 'Roni',
    age: 30,
    state: 'ACTIVE',
  );

  const presentationContext = ProfilePresentationContext(
    viewerUserId: '33333333-3333-3333-3333-333333333333',
    targetUserId: '11111111-1111-1111-1111-111111111111',
    summary: 'Shown because this profile is nearby.',
    reasonTags: ['nearby', 'eligible_match_pool'],
    details: ['This profile is within your preferred distance.'],
    generatedAt: '2026-05-08T10:15:00Z',
  );

  const editSnapshot = ProfileEditSnapshot(
    userId: '11111111-1111-1111-1111-111111111111',
    editable: EditableProfileSnapshot(
      bio: 'Loves coffee and beach walks.',
      gender: 'FEMALE',
      interestedIn: ['MALE'],
      maxDistanceKm: 50,
      location: ProfileEditLocationSnapshot(label: 'Tel Aviv'),
    ),
    readOnly: ReadOnlyProfileSnapshot(
      name: 'Dana',
      state: 'ACTIVE',
      photoUrls: ['/photos/dana-1.jpg'],
    ),
  );

  testWidgets('shows a loading state before the profile resolves', (
    WidgetTester tester,
  ) async {
    final completer = Completer<UserDetail>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [profileProvider.overrideWith((ref) => completer.future)],
        child: const MaterialApp(home: ProfileScreen.currentUser()),
      ),
    );
    await tester.pump();

    expect(find.text('Loading profile…'), findsOneWidget);

    completer.complete(detail);
  });

  testWidgets('renders profile content and fallback text for empty fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedUserProvider.overrideWith((ref) async => currentUser),
          otherUserProfileProvider(
            sparseDetail.id,
          ).overrideWith((ref) async => sparseDetail),
          presentationContextProvider(
            sparseDetail.id,
          ).overrideWith((ref) async => presentationContext),
        ],
        child: MaterialApp(
          home: ProfileScreen.otherUser(
            userId: sparseDetail.id,
            userName: sparseDetail.name,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Noa, 29'), findsOneWidget);
    expect(find.text('About Noa'), findsOneWidget);
    expect(find.text('Shared details'), findsOneWidget);
    expect(find.text('Why this profile is shown'), findsOneWidget);
    expect(find.text('Shown because this profile is nearby.'), findsOneWidget);
    expect(
      find.text('This profile is within your preferred distance.'),
      findsOneWidget,
    );
    expect(find.text('No bio shared yet.'), findsOneWidget);
    expect(find.text('Not specified'), findsNWidgets(2));
    expect(find.text('Location not shared'), findsAtLeastNWidgets(1));
    expect(find.text('Distance preference not set'), findsOneWidget);
    expect(find.text('No photos shared yet.'), findsOneWidget);
  });

  testWidgets('prefers the resolved profile name in the app bar title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedUserProvider.overrideWith((ref) async => currentUser),
          otherUserProfileProvider(
            detail.id,
          ).overrideWith((ref) async => detail),
          presentationContextProvider(
            detail.id,
          ).overrideWith((ref) async => presentationContext),
        ],
        child: MaterialApp(
          home: ProfileScreen.otherUser(
            userId: detail.id,
            userName: 'Stale summary',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Dana's profile"), findsOneWidget);
  });

  testWidgets('shows an error state and retries the current profile load', (
    WidgetTester tester,
  ) async {
    var shouldFail = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith((ref) async {
            if (shouldFail) {
              throw const ApiError(
                message: 'Unable to load profile right now.',
              );
            }

            return detail;
          }),
        ],
        child: const MaterialApp(home: ProfileScreen.currentUser()),
      ),
    );
    await tester.pump();

    expect(find.text('Loading profile…'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Unable to load profile right now.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    shouldFail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Dana, 27'), findsOneWidget);
    expect(find.text('Loves coffee and beach walks.'), findsOneWidget);
  });

  testWidgets('shows an edit action for the current user profile', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith((ref) async => detail),
          profileEditSnapshotProvider.overrideWith((ref) async => editSnapshot),
        ],
        child: const MaterialApp(home: ProfileScreen.currentUser()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Edit profile'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit profile'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileEditScreen), findsOneWidget);
    expect(find.text('Edit profile'), findsOneWidget);
  });

  testWidgets(
    'shows user-friendly labels and a success state for complete profiles',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [profileProvider.overrideWith((ref) async => detail)],
          child: const MaterialApp(home: ProfileScreen.currentUser()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Female'), findsOneWidget);
      expect(find.text('Male'), findsOneWidget);
      expect(find.text('Active'), findsAtLeastNWidgets(1));
      expect(find.text('About Dana'), findsOneWidget);
      expect(find.text('Profile details'), findsOneWidget);
      expect(find.text('Profile ready'), findsOneWidget);
      expect(find.text('Review details'), findsNothing);
      expect(find.text('Edit profile'), findsOneWidget);
      expect(find.text('4 of 4 essentials are filled in.'), findsNothing);
    },
  );

  testWidgets('keeps other user profiles read-only', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedUserProvider.overrideWith((ref) async => currentUser),
          otherUserProfileProvider(
            detail.id,
          ).overrideWith((ref) async => detail),
          presentationContextProvider(
            detail.id,
          ).overrideWith((ref) async => presentationContext),
        ],
        child: MaterialApp(
          home: ProfileScreen.otherUser(
            userId: detail.id,
            userName: detail.name,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Edit profile'), findsNothing);
    expect(find.text('Shared details'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Like'), findsOneWidget);
  });

  testWidgets('shows safety actions for another user profile', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedUserProvider.overrideWith((ref) async => currentUser),
          otherUserProfileProvider(
            detail.id,
          ).overrideWith((ref) async => detail),
          presentationContextProvider(
            detail.id,
          ).overrideWith((ref) async => presentationContext),
        ],
        child: MaterialApp(
          home: ProfileScreen.otherUser(
            userId: detail.id,
            userName: detail.name,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Safety actions'), findsOneWidget);

    await tester.tap(find.byTooltip('Safety actions'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Safety actions').last);
    await tester.pumpAndSettle();

    expect(find.text('Block user'), findsOneWidget);
    expect(find.text('Report user'), findsOneWidget);
    expect(find.text('Unmatch'), findsNothing);
  });
}
