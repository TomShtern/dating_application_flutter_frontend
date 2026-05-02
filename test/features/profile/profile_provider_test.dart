import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/profile/profile_provider.dart';
import 'package:flutter_dating_application_1/models/profile_edit_snapshot.dart';
import 'package:flutter_dating_application_1/models/profile_presentation_context.dart';
import 'package:flutter_dating_application_1/models/profile_update_request.dart';
import 'package:flutter_dating_application_1/models/profile_update_response.dart';
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

  const presentationContext = ProfilePresentationContext(
    viewerUserId: '11111111-1111-1111-1111-111111111111',
    targetUserId: '22222222-2222-2222-2222-222222222222',
    summary: 'Shown because this profile is nearby.',
    reasonTags: ['nearby'],
    details: ['This profile is within your preferred distance.'],
    generatedAt: '2026-05-08T10:15:00Z',
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

  test(
    'profileEditSnapshotProvider loads backend edit-prefill values',
    () async {
      final apiClient = _FakeProfileApiClient(
        responses: {
          currentUser.id: currentUserDetail,
          otherUserDetail.id: otherUserDetail,
        },
        editSnapshot: editSnapshot,
      );

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          selectedUserProvider.overrideWith((ref) async => currentUser),
        ],
      );
      addTearDown(container.dispose);

      final snapshot = await container.read(profileEditSnapshotProvider.future);

      expect(snapshot.userId, currentUser.id);
      expect(snapshot.editable.minAge, 25);
      expect(snapshot.editable.maxAge, 35);
      expect(snapshot.editable.heightCm, 172);
      expect(apiClient.editSnapshotUserIds, [currentUser.id]);
    },
  );

  test(
    'presentationContextProvider loads context for the selected viewer',
    () async {
      final apiClient = _FakeProfileApiClient(
        responses: {
          currentUser.id: currentUserDetail,
          otherUserDetail.id: otherUserDetail,
        },
        presentationContext: presentationContext,
      );

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          selectedUserProvider.overrideWith((ref) async => currentUser),
        ],
      );
      addTearDown(container.dispose);

      final context = await container.read(
        presentationContextProvider(otherUserDetail.id).future,
      );

      expect(context.summary, 'Shown because this profile is nearby.');
      expect(context.details, [
        'This profile is within your preferred distance.',
      ]);
      expect(apiClient.presentationContextViewerIds, [currentUser.id]);
      expect(apiClient.presentationContextTargetIds, [otherUserDetail.id]);
    },
  );
}

class _FakeProfileApiClient extends ApiClient {
  _FakeProfileApiClient({
    required this.responses,
    this.editSnapshot,
    this.presentationContext,
  }) : super(dio: Dio());

  final Map<String, UserDetail> responses;
  final ProfileEditSnapshot? editSnapshot;
  final ProfilePresentationContext? presentationContext;
  final List<String> requestedUserIds = <String>[];
  final List<String?> requestedActingUserIds = <String?>[];
  final List<String> updatedUserIds = <String>[];
  final List<ProfileUpdateRequest> updatedRequests = <ProfileUpdateRequest>[];
  final List<String> editSnapshotUserIds = <String>[];
  final List<String> presentationContextViewerIds = <String>[];
  final List<String> presentationContextTargetIds = <String>[];

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
  Future<ProfileUpdateResponse> updateProfile({
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

    return const ProfileUpdateResponse();
  }

  @override
  Future<ProfileEditSnapshot> getProfileEditSnapshot({
    required String userId,
  }) async {
    editSnapshotUserIds.add(userId);
    return editSnapshot!;
  }

  @override
  Future<ProfilePresentationContext> getProfilePresentationContext({
    required String viewerUserId,
    required String targetUserId,
  }) async {
    presentationContextViewerIds.add(viewerUserId);
    presentationContextTargetIds.add(targetUserId);
    return presentationContext!;
  }
}
