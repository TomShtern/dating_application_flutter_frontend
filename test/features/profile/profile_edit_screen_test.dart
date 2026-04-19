import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/profile/profile_edit_screen.dart';
import 'package:flutter_dating_application_1/models/profile_update_request.dart';
import 'package:flutter_dating_application_1/models/user_detail.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';

void main() {
  const currentUser = UserSummary(
    id: '11111111-1111-1111-1111-111111111111',
    name: 'Dana',
    age: 27,
    state: 'ACTIVE',
  );

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
    id: '11111111-1111-1111-1111-111111111111',
    name: 'Dana',
    age: 27,
    bio: '',
    gender: '',
    interestedIn: [],
    approximateLocation: 'Tel Aviv',
    maxDistanceKm: 0,
    photoUrls: [],
    state: 'ACTIVE',
  );

  testWidgets('loads the initial profile values into the edit form', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ProfileEditScreen(initialDetail: detail)),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(0))
          .controller
          ?.text,
      detail.bio,
    );
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(1))
          .controller
          ?.text,
      detail.gender,
    );
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(2))
          .controller
          ?.text,
      detail.interestedIn.join(', '),
    );
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(3))
          .controller
          ?.text,
      detail.maxDistanceKm.toString(),
    );
  });

  testWidgets('validates enum-like fields and numeric distance before saving', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeProfileApiClient();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          selectedUserProvider.overrideWith((ref) async => currentUser),
        ],
        child: const MaterialApp(
          home: ProfileEditScreen(initialDetail: detail),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), 'unknown');
    await tester.enterText(find.byType(TextFormField).at(2), 'aliens');
    await tester.enterText(find.byType(TextFormField).at(3), '-1');
    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();

    expect(
      find.text('Use FEMALE, MALE, NON_BINARY, or OTHER.'),
      findsOneWidget,
    );
    expect(
      find.text('Use MALE, FEMALE, NON_BINARY, or OTHER.'),
      findsOneWidget,
    );
    expect(find.text('Please enter a valid maximum distance.'), findsOneWidget);
    expect(apiClient.updatedRequests, isEmpty);
  });

  testWidgets(
    'allows saving a sparse profile without forcing optional fields',
    (WidgetTester tester) async {
      final apiClient = _FakeProfileApiClient();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(apiClient),
            selectedUserProvider.overrideWith((ref) async => currentUser),
          ],
          child: const MaterialApp(
            home: ProfileEditScreen(initialDetail: sparseDetail),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'A short bio for a sparse profile.',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
      await tester.pumpAndSettle();

      expect(apiClient.updatedRequests, const [
        ProfileUpdateRequest(
          bio: 'A short bio for a sparse profile.',
          gender: '',
          interestedIn: [],
          maxDistanceKm: 0,
        ),
      ]);
    },
  );

  testWidgets('saves successfully and returns to the previous screen', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeProfileApiClient();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          selectedUserProvider.overrideWith((ref) async => currentUser),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) =>
                            const ProfileEditScreen(initialDetail: detail),
                      ),
                    );
                  },
                  child: const Text('Open editor'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Open editor'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'Updated bio for the edit flow.',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'FEMALE');
    await tester.enterText(find.byType(TextFormField).at(2), 'MALE, FEMALE');
    await tester.enterText(find.byType(TextFormField).at(3), '15');
    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Open editor'), findsOneWidget);
    expect(apiClient.updatedRequests, const [
      ProfileUpdateRequest(
        bio: 'Updated bio for the edit flow.',
        gender: 'FEMALE',
        interestedIn: ['MALE', 'FEMALE'],
        maxDistanceKm: 15,
      ),
    ]);
  });
}

class _FakeProfileApiClient extends ApiClient {
  _FakeProfileApiClient() : super(dio: Dio());

  final List<ProfileUpdateRequest> updatedRequests = <ProfileUpdateRequest>[];

  @override
  Future<void> updateProfile({
    required String userId,
    required ProfileUpdateRequest request,
  }) async {
    updatedRequests.add(request);
  }
}
