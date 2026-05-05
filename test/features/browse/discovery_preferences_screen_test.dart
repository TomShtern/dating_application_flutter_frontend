import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/browse/discovery_preferences_screen.dart';
import 'package:flutter_dating_application_1/models/profile_completion_info.dart';
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

  testWidgets('renders discovery preference fields from snapshot', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeDiscoveryPrefsApiClient();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          selectedUserProvider.overrideWith((ref) async => currentUser),
        ],
        child: const MaterialApp(
          home: DiscoveryPreferencesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Discovery preferences'), findsOneWidget);
    expect(find.text('Age range'), findsOneWidget);
    expect(find.text('Distance'), findsOneWidget);
    expect(find.text('Interested in'), findsOneWidget);

    // Verify age values loaded from snapshot (before scrolling away)
    // TextFormField renders controller text as EditableText and hint as Text,
    // so each age value appears twice.
    expect(find.text('25'), findsNWidgets(2));
    expect(find.text('35'), findsNWidgets(2));

    // Verify distance value
    expect(find.text('42 km'), findsOneWidget);

    // Scroll down to find Dealbreakers section
    await tester.scrollUntilVisible(
      find.text('Dealbreakers'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Dealbreakers'), findsOneWidget);
  });

  testWidgets('saving calls updateProfile and pops', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeDiscoveryPrefsApiClient();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          selectedUserProvider.overrideWith((ref) async => currentUser),
        ],
        child: const MaterialApp(
          home: DiscoveryPreferencesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(apiClient.updateProfileCalls, 0);

    await tester.tap(find.widgetWithText(FilledButton, 'Save preferences'));
    await tester.pumpAndSettle();

    expect(apiClient.updateProfileCalls, 1);
    // Screen should pop after successful save
    expect(find.text('Discovery preferences'), findsNothing);
  });

  testWidgets('shows unavailable controls for unsupported features', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeDiscoveryPrefsApiClient();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          selectedUserProvider.overrideWith((ref) async => currentUser),
        ],
        child: const MaterialApp(
          home: DiscoveryPreferencesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll down to find unavailable controls
    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(find.text('Verified only'), findsOneWidget);
    expect(find.text('Travel mode'), findsWidgets);
    expect(find.text('Show me less like this'), findsWidgets);
    expect(find.text('Unavailable'), findsNWidgets(3));
  });

  testWidgets('changing distance updates slider label', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeDiscoveryPrefsApiClient();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          selectedUserProvider.overrideWith((ref) async => currentUser),
        ],
        child: const MaterialApp(
          home: DiscoveryPreferencesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('42 km'), findsOneWidget);

    // Drag slider to change value
    final slider = find.byType(Slider);
    expect(slider, findsOneWidget);

    final rect = tester.getRect(slider);
    final center = rect.center;
    await tester.tapAt(Offset(center.dx + 50, center.dy));
    await tester.pumpAndSettle();

    // The distance label should have changed from 42 km
    expect(find.text('42 km'), findsNothing);
  });
}

class _FakeDiscoveryPrefsApiClient extends ApiClient {
  _FakeDiscoveryPrefsApiClient() : super(dio: Dio());

  int updateProfileCalls = 0;

  @override
  Future<ProfileEditSnapshot> getProfileEditSnapshot({
    required String userId,
  }) async {
    return ProfileEditSnapshot.fromJson({
      'userId': userId,
      'editable': {
        'minAge': 25,
        'maxAge': 35,
        'maxDistanceKm': 42,
        'interestedIn': ['MALE'],
        'dealbreakers': {
          'acceptableSmoking': [],
          'acceptableDrinking': [],
          'acceptableKidsStance': [],
          'acceptableLookingFor': [],
          'acceptableEducation': [],
        },
      },
      'readOnly': {
        'name': 'Dana',
        'state': 'ACTIVE',
        'photoUrls': [],
      },
    });
  }

  @override
  Future<ProfileUpdateResponse> updateProfile({
    required String userId,
    required ProfileUpdateRequest request,
  }) async {
    updateProfileCalls++;
    return const ProfileUpdateResponse(
      completionInfo: ProfileCompletionInfo(),
    );
  }
}
