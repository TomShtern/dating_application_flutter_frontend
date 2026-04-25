import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/location/location_completion_screen.dart';
import 'package:flutter_dating_application_1/features/profile/profile_edit_screen.dart';
import 'package:flutter_dating_application_1/models/location_metadata.dart';
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

  testWidgets('prevents a maximum preferred age below the minimum age', (
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
      find.text('Minimum preferred age'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.enterText(
      find.bySemanticsLabel('Minimum preferred age'),
      '35',
    );
    await tester.enterText(
      find.bySemanticsLabel('Maximum preferred age'),
      '30',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();

    expect(
      find.text('Maximum age must be greater than or equal to minimum age.'),
      findsOneWidget,
    );
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
    await tester.pumpAndSettle();
    await tester.tap(interestedInChip);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
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

  testWidgets('updates the displayed location after returning from setup', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeProfileApiClient(
      resolvedLocation: const ResolvedLocation(
        label: 'Haifa, Israel',
        latitude: 32.794,
        longitude: 34.9896,
        precision: 'CITY',
        approximate: false,
        message: 'Saved.',
      ),
    );

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
      find.text('Location'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Showing people near Tel Aviv.'), findsOneWidget);

    final updateLocationButton = find.widgetWithText(
      OutlinedButton,
      'Update location',
    );
    await tester.ensureVisible(updateLocationButton);
    await tester.pumpAndSettle();
    await tester.tap(updateLocationButton);
    await tester.pumpAndSettle();

    expect(find.byType(LocationCompletionScreen), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Haifa');
    await tester.tap(find.widgetWithText(FilledButton, 'Use this location'));
    await tester.pumpAndSettle();

    expect(find.byType(LocationCompletionScreen), findsNothing);
    expect(find.text('Showing people near Haifa, Israel.'), findsOneWidget);
    expect(find.text('Update location'), findsOneWidget);
  });
}

Finder _editableTextByValue(String value) {
  return find.byWidgetPredicate(
    (widget) => widget is EditableText && widget.controller.text == value,
  );
}

class _FakeProfileApiClient extends ApiClient {
  _FakeProfileApiClient({
    this.resolvedLocation = const ResolvedLocation(
      label: 'Tel Aviv, Israel',
      latitude: 32.0853,
      longitude: 34.7818,
      precision: 'CITY',
      approximate: false,
      message: 'Saved.',
    ),
  }) : super(dio: Dio());

  final List<ProfileUpdateRequest> updatedRequests = <ProfileUpdateRequest>[];
  final ResolvedLocation resolvedLocation;

  @override
  Future<void> updateProfile({
    required String userId,
    required ProfileUpdateRequest request,
  }) async {
    updatedRequests.add(request);
  }

  @override
  Future<List<LocationCountry>> getLocationCountries() async {
    return const <LocationCountry>[
      LocationCountry(
        code: 'IL',
        name: 'Israel',
        flagEmoji: '🇮🇱',
        available: true,
        defaultSelection: true,
      ),
    ];
  }

  @override
  Future<List<LocationCity>> getLocationCities({
    String? countryCode,
    String query = '',
    int limit = 10,
  }) async {
    return const <LocationCity>[];
  }

  @override
  Future<ResolvedLocation> resolveLocation({
    required String countryCode,
    required String cityName,
    String? zipCode,
    bool allowApproximate = false,
  }) async {
    return resolvedLocation;
  }
}
