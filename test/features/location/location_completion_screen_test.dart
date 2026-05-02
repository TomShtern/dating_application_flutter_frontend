import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/location/location_completion_screen.dart';
import 'package:flutter_dating_application_1/models/location_metadata.dart';
import 'package:flutter_dating_application_1/models/profile_update_request.dart';
import 'package:flutter_dating_application_1/models/profile_update_response.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';

const _countries = <LocationCountry>[
  LocationCountry(
    code: 'IL',
    name: 'Israel',
    flagEmoji: '🇮🇱',
    available: true,
    defaultSelection: true,
  ),
  LocationCountry(
    code: 'US',
    name: 'United States',
    flagEmoji: '🇺🇸',
    available: true,
    defaultSelection: false,
  ),
];

void main() {
  const currentUser = UserSummary(
    id: '11111111-1111-1111-1111-111111111111',
    name: 'Dana',
    age: 27,
    state: 'ACTIVE',
  );

  testWidgets('shows a cleaner country selector and a stronger primary CTA', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeLocationApiClient();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(apiClient)],
        child: const MaterialApp(home: LocationCompletionScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.flag_outlined), findsAtLeastNWidgets(1));
    expect(find.text('Israel'), findsAtLeastNWidgets(1));
    expect(find.text('IL'), findsNothing);
    expect(find.text('Save location'), findsOneWidget);
    expect(find.text('You can change this anytime.'), findsOneWidget);
  });

  testWidgets('saves the chosen location and returns to the previous screen', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeLocationApiClient();

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
                        builder: (context) => const LocationCompletionScreen(),
                      ),
                    );
                  },
                  child: const Text('Open location'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Open location'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Israel').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Tel Aviv');
    await tester.pumpAndSettle();

    final locationScrollable = find
        .descendant(
          of: find.byType(LocationCompletionScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.drag(locationScrollable, const Offset(0, -240));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tel Aviv').last, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Selected city'), findsOneWidget);
    expect(find.text('Tel Aviv, Central District'), findsOneWidget);

    final saveButton = find.widgetWithText(FilledButton, 'Save location');
    await tester.scrollUntilVisible(
      saveButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final saveAction = tester.widget<FilledButton>(saveButton).onPressed;
    expect(saveAction, isNotNull);
    saveAction!.call();
    await tester.pumpAndSettle();

    expect(apiClient.lastResolvedCountryCode, 'IL');
    expect(apiClient.lastResolvedCityName, 'Tel Aviv');
    expect(apiClient.lastResolvedAllowApproximate, isTrue);
    expect(apiClient.updatedRequests, const [
      ProfileUpdateRequest(
        location: ProfileLocationRequest(
          countryCode: 'IL',
          cityName: 'Tel Aviv',
          allowApproximate: true,
        ),
      ),
    ]);
  });
}

class _FakeLocationApiClient extends ApiClient {
  _FakeLocationApiClient() : super(dio: Dio());

  final List<ProfileUpdateRequest> updatedRequests = <ProfileUpdateRequest>[];
  String? lastResolvedCountryCode;
  String? lastResolvedCityName;
  bool? lastResolvedAllowApproximate;

  @override
  Future<List<LocationCountry>> getLocationCountries() async {
    return _countries;
  }

  @override
  Future<List<LocationCity>> getLocationCities({
    String? countryCode,
    String query = '',
    int limit = 10,
  }) async {
    if (query.trim().length < 2) {
      return const <LocationCity>[];
    }

    return const <LocationCity>[
      LocationCity(
        name: 'Tel Aviv',
        district: 'Central District',
        countryCode: 'IL',
        priority: 10,
      ),
    ];
  }

  @override
  Future<ResolvedLocation> resolveLocation({
    required String countryCode,
    required String cityName,
    String? zipCode,
    bool allowApproximate = false,
  }) async {
    lastResolvedCountryCode = countryCode;
    lastResolvedCityName = cityName;
    lastResolvedAllowApproximate = allowApproximate;

    return const ResolvedLocation(
      label: 'Tel Aviv, Israel',
      latitude: 32.0853,
      longitude: 34.7818,
      precision: 'CITY',
      approximate: false,
      message: 'Saved.',
    );
  }

  @override
  Future<ProfileUpdateResponse> updateProfile({
    required String userId,
    required ProfileUpdateRequest request,
  }) async {
    updatedRequests.add(request);
    return const ProfileUpdateResponse();
  }
}
