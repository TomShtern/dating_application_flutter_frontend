import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/profile/profile_provider.dart';
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

  const currentUserDetail = UserDetail(
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

  const otherUserDetail = UserDetail(
    id: '22222222-2222-2222-2222-222222222222',
    name: 'Noa',
    age: 29,
    bio: 'Always up for a good museum date.',
    gender: 'FEMALE',
    interestedIn: ['FEMALE', 'MALE'],
    approximateLocation: 'Haifa',
    maxDistanceKm: 25,
    photoUrls: ['/photos/noa-1.jpg'],
    state: 'ACTIVE',
  );

  const updatedRequest = ProfileUpdateRequest(
    bio: 'Updated bio for the edit flow.',
    gender: 'FEMALE',
    interestedIn: ['MALE', 'FEMALE'],
    maxDistanceKm: 15,
  );

  test(
    'profileProvider loads the current user detail from the API client',
    () async {
      final apiClient = _FakeProfileApiClient(
        responses: {
          currentUser.id: currentUserDetail,
          otherUserDetail.id: otherUserDetail,
        },
      );

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          selectedUserProvider.overrideWith((ref) async => currentUser),
        ],
      );
      addTearDown(container.dispose);

      final detail = await container.read(profileProvider.future);

      expect(detail.id, currentUserDetail.id);
      expect(detail.name, currentUserDetail.name);
      expect(apiClient.requestedUserIds, [currentUser.id]);
      expect(apiClient.requestedActingUserIds, [currentUser.id]);
    },
  );

  test(
    'otherUserProfileProvider loads another user detail from the API client',
    () async {
      final apiClient = _FakeProfileApiClient(
        responses: {
          currentUser.id: currentUserDetail,
          otherUserDetail.id: otherUserDetail,
        },
      );

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          selectedUserProvider.overrideWith((ref) async => currentUser),
        ],
      );
      addTearDown(container.dispose);

      final detail = await container.read(
        otherUserProfileProvider(otherUserDetail.id).future,
      );

      expect(detail.id, otherUserDetail.id);
      expect(detail.name, otherUserDetail.name);
      expect(apiClient.requestedUserIds, [otherUserDetail.id]);
      expect(apiClient.requestedActingUserIds, [currentUser.id]);
    },
  );

  test(
    'updateProfile sends the request and invalidates the current profile data',
    () async {
      final apiClient = _FakeProfileApiClient(
        responses: {
          currentUser.id: currentUserDetail,
          otherUserDetail.id: otherUserDetail,
        },
      );

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          selectedUserProvider.overrideWith((ref) async => currentUser),
        ],
      );
      addTearDown(container.dispose);

      final initialDetail = await container.read(profileProvider.future);
      expect(initialDetail.bio, currentUserDetail.bio);

      await container
          .read(profileControllerProvider)
          .updateProfile(updatedRequest);

      final refreshedDetail = await container.read(profileProvider.future);

      expect(apiClient.updatedUserIds, [currentUser.id]);
      expect(apiClient.updatedRequests, [updatedRequest]);
      expect(refreshedDetail.bio, updatedRequest.bio);
      expect(refreshedDetail.interestedIn, updatedRequest.interestedIn);
      expect(refreshedDetail.maxDistanceKm, updatedRequest.maxDistanceKm);
      expect(apiClient.requestedUserIds, [currentUser.id, currentUser.id]);
      expect(apiClient.requestedActingUserIds, [
        currentUser.id,
        currentUser.id,
      ]);
    },
  );
}

class _FakeProfileApiClient extends ApiClient {
  _FakeProfileApiClient({required this.responses}) : super(dio: Dio());

  final Map<String, UserDetail> responses;
  final List<String> requestedUserIds = <String>[];
  final List<String?> requestedActingUserIds = <String?>[];
  final List<String> updatedUserIds = <String>[];
  final List<ProfileUpdateRequest> updatedRequests = <ProfileUpdateRequest>[];

  @override
  Future<UserDetail> getUserDetail({
    required String userId,
    String? actingUserId,
  }) async {
    requestedUserIds.add(userId);
    requestedActingUserIds.add(actingUserId);
    return responses[userId]!;
  }

  @override
  Future<void> updateProfile({
    required String userId,
    required ProfileUpdateRequest request,
  }) async {
    updatedUserIds.add(userId);
    updatedRequests.add(request);

    final previous = responses[userId]!;
    responses[userId] = UserDetail(
      id: previous.id,
      name: previous.name,
      age: previous.age,
      bio: request.bio ?? previous.bio,
      gender: request.gender ?? previous.gender,
      interestedIn: request.interestedIn ?? previous.interestedIn,
      approximateLocation: previous.approximateLocation,
      maxDistanceKm: request.maxDistanceKm ?? previous.maxDistanceKm,
      photoUrls: previous.photoUrls,
      state: previous.state,
    );
  }
}
