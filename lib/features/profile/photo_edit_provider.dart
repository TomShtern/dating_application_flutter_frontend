import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/api_client.dart';
import '../../models/photo_dto.dart';
import '../../shared/providers/selected_user_guard.dart' as user_guard;
import '../auth/auth_controller.dart';
import 'profile_provider.dart';

final userPhotosProvider = FutureProvider<PhotoListResponse>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final currentUser = await user_guard.watchSelectedUser(ref);
  return apiClient.listUserPhotos(userId: currentUser.id);
});

final photoEditControllerProvider = Provider<PhotoEditController>((ref) {
  return PhotoEditController(ref);
});

class PhotoEditController {
  PhotoEditController(this._ref);

  final Ref _ref;

  /// Uploads a photo chosen via [XFile].
  ///
  /// Image Picker with `imageQuality` set re-encodes the image on most
  /// platforms, which strips EXIF metadata as a side effect. This is the
  /// frontend's best-effort EXIF removal. The backend remains the
  /// enforcement point for content policy and full EXIF hygiene.
  ///
  /// For progress tracking, retry on failure, and server rejection reasons,
  /// use [PhotoUploadNotifier] from `photo_upload_provider.dart` instead.
  Future<void> uploadFromXFile(XFile file) async {
    final currentUser = await user_guard.requireSelectedUser(_ref);
    final apiClient = _ref.read(apiClientProvider);

    final MultipartFile multipart;
    final path = file.path;
    if (path.isNotEmpty && File(path).existsSync()) {
      multipart = await MultipartFile.fromFile(path, filename: file.name);
    } else {
      final bytes = await file.readAsBytes();
      multipart = MultipartFile.fromBytes(bytes, filename: file.name);
    }

    await apiClient.uploadPhoto(userId: currentUser.id, photo: multipart);
    _invalidateAfterPhotoChange(currentUser.id);
  }

  Future<void> deletePhoto(String photoId) async {
    final currentUser = await user_guard.requireSelectedUser(_ref);
    final apiClient = _ref.read(apiClientProvider);
    await apiClient.deletePhoto(userId: currentUser.id, photoId: photoId);
    _invalidateAfterPhotoChange(currentUser.id);
  }

  Future<void> reorderPhotos(List<String> photoIds) async {
    final currentUser = await user_guard.requireSelectedUser(_ref);
    final apiClient = _ref.read(apiClientProvider);
    await apiClient.reorderPhotos(userId: currentUser.id, photoIds: photoIds);
    _invalidateAfterPhotoChange(currentUser.id);
  }

  Future<void> setPrimary(String photoId) async {
    final current = await _ref.read(userPhotosProvider.future);
    final ordered = <String>[
      photoId,
      for (final p in current.photos)
        if (p.id != photoId) p.id,
    ];
    await reorderPhotos(ordered);
  }

  void _invalidateAfterPhotoChange(String userId) {
    _ref.invalidate(userPhotosProvider);
    _ref.invalidate(profileProvider);
    _ref.invalidate(profileEditSnapshotProvider);
    _ref.invalidate(otherUserProfileProvider(userId));
    _ref.read(authControllerProvider.notifier).refreshMe();
  }
}