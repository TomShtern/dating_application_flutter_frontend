import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/browse/browse_provider.dart';
import 'package:flutter_dating_application_1/features/browse/discovery_preferences_provider.dart';
import 'package:flutter_dating_application_1/features/browse/pending_likers_provider.dart';
import 'package:flutter_dating_application_1/features/browse/standouts_provider.dart';
import 'package:flutter_dating_application_1/models/browse_candidate.dart';
import 'package:flutter_dating_application_1/models/browse_response.dart';
import 'package:flutter_dating_application_1/models/discovery_preferences.dart';
import 'package:flutter_dating_application_1/models/pending_liker.dart';
import 'package:flutter_dating_application_1/models/profile_completion_info.dart';
import 'package:flutter_dating_application_1/models/profile_edit_snapshot.dart';
import 'package:flutter_dating_application_1/models/profile_update_response.dart';
import 'package:flutter_dating_application_1/models/standout.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';

void main() {
  test('loads discovery preferences from profile edit snapshot', () async {
    final apiClient = _FakeDiscoveryApiClient();

    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(apiClient),
        selectedUserProvider.overrideWith(
          (ref) async => const UserSummary(
            id: '11111111-1111-1111-1111-111111111111',
            name: 'Dana',
            age: 27,
            state: 'ACTIVE',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final prefs = await container.read(discoveryPreferencesProvider.future);

    expect(prefs.minAge, 25);
    expect(prefs.maxAge, 35);
    expect(prefs.maxDistanceKm, 42);
    expect(prefs.interestedIn, ['MALE']);
  });

  test('save updates profile and invalidates browse-related providers', () async {
    final apiClient = _FakeDiscoveryApiClient();

    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(apiClient),
        selectedUserProvider.overrideWith(
          (ref) async => const UserSummary(
            id: '11111111-1111-1111-1111-111111111111',
            name: 'Dana',
            age: 27,
            state: 'ACTIVE',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    // Prime the providers so invalidation causes a refetch.
    await container.read(browseProvider.future);
    await container.read(standoutsProvider.future);
    await container.read(pendingLikersProvider.future);

    expect(apiClient.browseCalls, 1);
    expect(apiClient.standoutsCalls, 1);
    expect(apiClient.pendingLikersCalls, 1);
    expect(apiClient.updateProfileCalls, 0);

    const prefs = DiscoveryPreferences(
      minAge: 28,
      maxAge: 40,
      maxDistanceKm: 60,
    );

    await container
        .read(discoveryPreferencesControllerProvider)
        .save(prefs);

    expect(apiClient.updateProfileCalls, 1);

    // Invalidation should trigger refetch on next read.
    final refreshedBrowse = await container.read(browseProvider.future);
    final refreshedStandouts = await container.read(standoutsProvider.future);
    final refreshedPendingLikers = await container.read(
      pendingLikersProvider.future,
    );

    expect(apiClient.browseCalls, 2);
    expect(apiClient.standoutsCalls, 2);
    expect(apiClient.pendingLikersCalls, 2);
    expect(refreshedBrowse.candidates.single.id, 'target-2');
    expect(refreshedStandouts.standouts.isEmpty, isTrue);
    expect(refreshedPendingLikers.isEmpty, isTrue);
  });
}

class _FakeDiscoveryApiClient extends ApiClient {
  _FakeDiscoveryApiClient() : super(dio: Dio());

  int browseCalls = 0;
  int standoutsCalls = 0;
  int pendingLikersCalls = 0;
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
    required request,
  }) async {
    updateProfileCalls++;
    return const ProfileUpdateResponse(
      completionInfo: ProfileCompletionInfo(),
    );
  }

  @override
  Future<BrowseResponse> getBrowse({required String userId}) async {
    browseCalls++;
    return BrowseResponse(
      candidates: [
        BrowseCandidate(
          id: 'target-$browseCalls',
          name: 'Noa',
          age: 29,
          state: 'ACTIVE',
        ),
      ],
      dailyPick: null,
      dailyPickViewed: false,
      locationMissing: false,
    );
  }

  @override
  Future<StandoutsSnapshot> getStandouts({required String userId}) async {
    standoutsCalls++;
    return StandoutsSnapshot(
      standouts: const [],
      totalCandidates: 0,
      fromCache: false,
      message: 'OK',
    );
  }

  @override
  Future<List<PendingLiker>> getPendingLikers({
    required String userId,
  }) async {
    pendingLikersCalls++;
    return const [];
  }
}
