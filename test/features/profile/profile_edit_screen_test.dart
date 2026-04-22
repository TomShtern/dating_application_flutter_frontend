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
      find.text('Show people a version of you that feels true.'),
      findsOneWidget,
    );
    expect(find.text('About'), findsOneWidget);

    final genderChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Female'),
    );
    expect(genderChip.selected, isTrue);

    expect(find.text(detail.bio), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Preferences'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Preferences'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Location'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Location'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.widgetWithText(FilterChip, 'Male'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.widgetWithText(FilterChip, 'Male'), findsOneWidget);
    expect(
      _editableTextByValue(detail.maxDistanceKm.toString()),
      findsOneWidget,
    );
  });

  testWidgets('validates numeric preferences before saving', (
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

    await tester.scrollUntilVisible(
      find.text('Maximum distance (km)'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.bySemanticsLabel('Maximum distance (km)'),
      '-1',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();

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
        ProfileUpdateRequest(bio: 'A short bio for a sparse profile.'),
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
      _editableTextByValue(detail.bio),
      'Updated bio for the edit flow.',
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'Non-binary'));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.widgetWithText(FilterChip, 'Non-binary'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final interestedInChip = find.widgetWithText(FilterChip, 'Non-binary');
    await tester.ensureVisible(interestedInChip);
    final chipWidget = tester.widget<FilterChip>(interestedInChip);
    expect(chipWidget.onSelected, isNotNull);
    chipWidget.onSelected!(true);
    await tester.pump();
    final saveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save changes'),
    );
    expect(saveButton.onPressed, isNotNull);
    saveButton.onPressed!();
    await tester.pumpAndSettle();

    expect(apiClient.updatedRequests, isNotEmpty);
    expect(
      apiClient.updatedRequests.last.bio,
      'Updated bio for the edit flow.',
    );
    expect(apiClient.updatedRequests.last.gender, 'NON_BINARY');
    expect(apiClient.updatedRequests.last.maxDistanceKm, 50);
    expect(
      apiClient.updatedRequests.last.interestedIn,
      containsAllInOrder(const ['MALE', 'NON_BINARY']),
    );
  });
}

Finder _editableTextByValue(String value) {
  return find.byWidgetPredicate(
    (widget) => widget is EditableText && widget.controller.text == value,
  );
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
