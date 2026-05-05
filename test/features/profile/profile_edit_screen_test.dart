import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/location/location_completion_screen.dart';
import 'package:flutter_dating_application_1/features/profile/profile_edit_screen.dart';
import 'package:flutter_dating_application_1/features/profile/profile_provider.dart';
import 'package:flutter_dating_application_1/models/location_metadata.dart';
import 'package:flutter_dating_application_1/models/photo_dto.dart';
import 'package:flutter_dating_application_1/models/profile_edit_snapshot.dart';
import 'package:flutter_dating_application_1/models/profile_update_request.dart';
import 'package:flutter_dating_application_1/models/profile_update_response.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';

void main() {
  const currentUser = UserSummary(
    id: '11111111-1111-1111-1111-111111111111',
    name: 'Dana',
    age: 27,
    state: 'ACTIVE',
  );

  const editSnapshot = ProfileEditSnapshot(
    userId: '11111111-1111-1111-1111-111111111111',
    editable: EditableProfileSnapshot(
      bio: 'Loves coffee and beach walks.',
      gender: 'FEMALE',
      interestedIn: ['MALE'],
      maxDistanceKm: 50,
      minAge: 25,
      maxAge: 35,
      heightCm: 172,
      location: ProfileEditLocationSnapshot(label: 'Tel Aviv'),
    ),
    readOnly: ReadOnlyProfileSnapshot(
      name: 'Dana',
      state: 'ACTIVE',
      photoUrls: ['/photos/dana-1.jpg'],
    ),
  );

  const sparseEditSnapshot = ProfileEditSnapshot(
    userId: '11111111-1111-1111-1111-111111111111',
    editable: EditableProfileSnapshot(
      interestedIn: [],
      location: ProfileEditLocationSnapshot(label: 'Tel Aviv'),
    ),
    readOnly: ReadOnlyProfileSnapshot(
      name: 'Dana',
      state: 'ACTIVE',
      photoUrls: [],
    ),
  );

  testWidgets('loads the initial profile values into the edit form', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileEditSnapshotProvider.overrideWith((ref) async => editSnapshot),
        ],
        child: const MaterialApp(home: ProfileEditScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dana'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Basics'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Basics'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Distance'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Showing matches within'), findsOneWidget);
    expect(find.text('50 km'), findsOneWidget);
    expect(find.text('Female'), findsWidgets);
    expect(find.text('Male'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('About'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('About'), findsOneWidget);
    expect(find.text(editSnapshot.editable.bio!), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Location'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Location'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Fine-tune matching'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await _expandAgeAndHeightFilters(tester);
    await tester.pumpAndSettle();

    expect(_editableTextByValue('25'), findsOneWidget);
    expect(_editableTextByValue('35'), findsOneWidget);
    expect(_editableTextByValue('172'), findsOneWidget);
  });

  testWidgets('updates maximum distance with the slider before saving', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeProfileApiClient();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          selectedUserProvider.overrideWith((ref) async => currentUser),
          profileEditSnapshotProvider.overrideWith((ref) async => editSnapshot),
        ],
        child: const MaterialApp(home: ProfileEditScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byType(Slider),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final sliderFinder = find.byType(Slider);
    expect(sliderFinder, findsOneWidget);
    final slider = tester.widget<Slider>(sliderFinder);
    slider.onChanged?.call(80);
    await tester.pumpAndSettle();

    expect(find.text('80 km'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();

    expect(apiClient.updatedRequests.last.maxDistanceKm, 80);
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
          profileEditSnapshotProvider.overrideWith((ref) async => editSnapshot),
        ],
        child: const MaterialApp(home: ProfileEditScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byType(ExpansionTile),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await _expandAgeAndHeightFilters(tester);
    await tester.pumpAndSettle();

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
            profileEditSnapshotProvider.overrideWith(
              (ref) async => sparseEditSnapshot,
            ),
          ],
          child: const MaterialApp(home: ProfileEditScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('About'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
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
          profileEditSnapshotProvider.overrideWith((ref) async => editSnapshot),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const ProfileEditScreen(),
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

    await tester.scrollUntilVisible(
      find.text('Basics'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Non-binary').at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Non-binary').at(0), warnIfMissed: false);
    await tester.pump();

    final interestedInChip = find.text('Non-binary').at(1);
    await tester.ensureVisible(interestedInChip);
    await tester.pumpAndSettle();
    await tester.tap(interestedInChip);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      _editableTextByValue(editSnapshot.editable.bio!),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      _editableTextByValue(editSnapshot.editable.bio!),
      'Updated bio for the edit flow.',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();

    expect(apiClient.updatedRequests, isNotEmpty);
    expect(
      apiClient.updatedRequests.last.bio,
      'Updated bio for the edit flow.',
    );
    expect(apiClient.updatedRequests.last.gender, 'NON_BINARY');
    expect(apiClient.updatedRequests.last.maxDistanceKm, 50);
    expect(apiClient.updatedRequests.last.minAge, 25);
    expect(apiClient.updatedRequests.last.maxAge, 35);
    expect(apiClient.updatedRequests.last.heightCm, 172);
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
          profileEditSnapshotProvider.overrideWith((ref) async => editSnapshot),
        ],
        child: const MaterialApp(home: ProfileEditScreen()),
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
    await tester.tap(find.widgetWithText(FilledButton, 'Save location'));
    await tester.pumpAndSettle();

    expect(find.byType(LocationCompletionScreen), findsNothing);
    expect(find.text('Showing people near Haifa, Israel.'), findsOneWidget);
    expect(find.text('Update location'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();

    expect(
      apiClient.updatedRequests.last.location,
      const ProfileLocationRequest(
        countryCode: 'IL',
        cityName: 'Haifa',
        allowApproximate: true,
      ),
    );
  });
}

Finder _editableTextByValue(String value) {
  return find.byWidgetPredicate(
    (widget) => widget is EditableText && widget.controller.text == value,
  );
}

Future<void> _expandAgeAndHeightFilters(WidgetTester tester) async {
  final scrollable = find.byType(Scrollable).first;

  await tester.scrollUntilVisible(
    find.text('Fine-tune matching'),
    200,
    scrollable: scrollable,
  );
  await tester.drag(scrollable, const Offset(0, -120));
  await tester.pumpAndSettle();

  final tileFinder = find.byType(ExpansionTile);
  await tester.ensureVisible(tileFinder);
  await tester.pumpAndSettle();

  final box = tester.renderObject<RenderBox>(tileFinder);
  await tester.tapAt(box.localToGlobal(box.size.center(Offset.zero)));
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
  Future<ProfileUpdateResponse> updateProfile({
    required String userId,
    required ProfileUpdateRequest request,
  }) async {
    updatedRequests.add(request);
    return const ProfileUpdateResponse();
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

  @override
  Future<PhotoListResponse> listUserPhotos({required String userId}) async {
    return const PhotoListResponse(primaryUrl: null, photos: []);
  }
}
