import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/profile/photo_edit_provider.dart';
import 'package:flutter_dating_application_1/models/photo_dto.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';

void main() {
  const userId = '11111111-1111-1111-1111-111111111111';
  const seededUser = UserSummary(
    id: userId,
    name: 'Dana',
    age: 27,
    state: 'ACTIVE',
  );

  ProviderContainer makeContainer(_FakeApiClient apiClient) {
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(apiClient),
        selectedUserProvider.overrideWith((ref) async => seededUser),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('userPhotosProvider fetches the photo list for the selected user',
      () async {
    final apiClient = _FakeApiClient(
      listResponses: const [
        PhotoListResponse(
          primaryUrl: '/photos/dana-1.jpg',
          photos: [
            PhotoDto(id: 'photo-1', url: '/photos/dana-1.jpg'),
            PhotoDto(id: 'photo-2', url: '/photos/dana-2.jpg'),
          ],
        ),
      ],
    );
    final container = makeContainer(apiClient);

    final list = await container.read(userPhotosProvider.future);

    expect(list.photos.map((p) => p.id), ['photo-1', 'photo-2']);
    expect(apiClient.listCalls, [userId]);
  });

  test('deletePhoto calls the API and invalidates the photos provider',
      () async {
    final apiClient = _FakeApiClient(
      listResponses: const [
        PhotoListResponse(
          primaryUrl: '/photos/dana-1.jpg',
          photos: [
            PhotoDto(id: 'photo-1', url: '/photos/dana-1.jpg'),
            PhotoDto(id: 'photo-2', url: '/photos/dana-2.jpg'),
          ],
        ),
        PhotoListResponse(
          primaryUrl: '/photos/dana-2.jpg',
          photos: [
            PhotoDto(id: 'photo-2', url: '/photos/dana-2.jpg'),
          ],
        ),
      ],
      deleteResponse: const PhotoListResponse(
        primaryUrl: '/photos/dana-2.jpg',
        photos: [
          PhotoDto(id: 'photo-2', url: '/photos/dana-2.jpg'),
        ],
      ),
    );
    final container = makeContainer(apiClient);

    await container.read(userPhotosProvider.future);
    await container.read(photoEditControllerProvider).deletePhoto('photo-1');
    final refreshed = await container.read(userPhotosProvider.future);

    expect(apiClient.deleteCalls, hasLength(1));
    expect(apiClient.deleteCalls.single.$1, userId);
    expect(apiClient.deleteCalls.single.$2, 'photo-1');
    expect(refreshed.photos.single.id, 'photo-2');
    expect(apiClient.listCalls.length, 2);
  });

  test('setPrimary moves the chosen photo to index 0 via reorderPhotos',
      () async {
    final apiClient = _FakeApiClient(
      listResponses: const [
        PhotoListResponse(
          primaryUrl: '/photos/dana-1.jpg',
          photos: [
            PhotoDto(id: 'photo-1', url: '/photos/dana-1.jpg'),
            PhotoDto(id: 'photo-2', url: '/photos/dana-2.jpg'),
            PhotoDto(id: 'photo-3', url: '/photos/dana-3.jpg'),
          ],
        ),
      ],
      reorderResponse: const PhotoListResponse(
        primaryUrl: '/photos/dana-3.jpg',
        photos: [
          PhotoDto(id: 'photo-3', url: '/photos/dana-3.jpg'),
          PhotoDto(id: 'photo-1', url: '/photos/dana-1.jpg'),
          PhotoDto(id: 'photo-2', url: '/photos/dana-2.jpg'),
        ],
      ),
    );
    final container = makeContainer(apiClient);

    await container.read(photoEditControllerProvider).setPrimary('photo-3');

    expect(apiClient.reorderCalls, hasLength(1));
    expect(apiClient.reorderCalls.single.$1, userId);
    expect(apiClient.reorderCalls.single.$2,
        ['photo-3', 'photo-1', 'photo-2']);
  });

  test(
    'uploadFromXFile builds a MultipartFile and calls uploadPhoto',
    () async {
      final apiClient = _FakeApiClient(
        listResponses: const [
          PhotoListResponse(primaryUrl: null, photos: []),
        ],
        uploadResponse: const PhotoUploadResponse(
          photo: PhotoDto(id: 'photo-new', url: '/photos/new.jpg'),
          list: PhotoListResponse(
            primaryUrl: '/photos/new.jpg',
            photos: [PhotoDto(id: 'photo-new', url: '/photos/new.jpg')],
          ),
        ),
      );
      final container = makeContainer(apiClient);

      // XFile from raw bytes — no real file on disk, controller falls back to
      // MultipartFile.fromBytes.
      final picked = XFile.fromData(
        Uint8List.fromList(<int>[0, 0, 0, 0]),
        name: 'avatar.jpg',
        mimeType: 'image/jpeg',
      );
      await container
          .read(photoEditControllerProvider)
          .uploadFromXFile(picked);

      expect(apiClient.uploadCalls, hasLength(1));
      expect(apiClient.uploadCalls.single.$1, userId);
      expect(apiClient.uploadCalls.single.$2, isA<MultipartFile>());
    },
  );
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient({
    this.listResponses = const <PhotoListResponse>[],
    this.deleteResponse,
    this.reorderResponse,
    this.uploadResponse,
  }) : super(dio: Dio());

  final List<PhotoListResponse> listResponses;
  final PhotoListResponse? deleteResponse;
  final PhotoListResponse? reorderResponse;
  final PhotoUploadResponse? uploadResponse;

  final List<String> listCalls = <String>[];
  final List<(String, String)> deleteCalls = <(String, String)>[];
  final List<(String, List<String>)> reorderCalls = <(String, List<String>)>[];
  final List<(String, MultipartFile)> uploadCalls = <(String, MultipartFile)>[];

  @override
  Future<PhotoListResponse> listUserPhotos({required String userId}) async {
    listCalls.add(userId);
    final index = listCalls.length - 1;
    if (listResponses.isEmpty) {
      throw StateError('No fake list response queued');
    }
    return listResponses[index < listResponses.length
        ? index
        : listResponses.length - 1];
  }

  @override
  Future<PhotoListResponse> deletePhoto({
    required String userId,
    required String photoId,
  }) async {
    deleteCalls.add((userId, photoId));
    if (deleteResponse == null) {
      throw StateError('No fake delete response queued');
    }
    return deleteResponse!;
  }

  @override
  Future<PhotoListResponse> reorderPhotos({
    required String userId,
    required List<String> photoIds,
  }) async {
    reorderCalls.add((userId, photoIds));
    if (reorderResponse == null) {
      throw StateError('No fake reorder response queued');
    }
    return reorderResponse!;
  }

  @override
  Future<PhotoUploadResponse> uploadPhoto({
    required String userId,
    required MultipartFile photo,
  }) async {
    uploadCalls.add((userId, photo));
    if (uploadResponse == null) {
      throw StateError('No fake upload response queued');
    }
    return uploadResponse!;
  }
}
