import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/api_client.dart';
import '../../api/api_error.dart';
import '../../models/photo_dto.dart';
import '../../shared/providers/selected_user_guard.dart' as user_guard;
import '../auth/auth_controller.dart';
import 'photo_edit_provider.dart';
import 'profile_provider.dart';
import 'upload_state.dart';

final photoUploadProvider =
    NotifierProvider<PhotoUploadNotifier, Map<String, PhotoUploadEntry>>(
      PhotoUploadNotifier.new,
    );

class PhotoUploadNotifier extends Notifier<Map<String, PhotoUploadEntry>> {
  int _nextUploadId = 0;

  @override
  Map<String, PhotoUploadEntry> build() => {};

  String _nextLocalId() {
    _nextUploadId += 1;
    return 'upload_$_nextUploadId';
  }

  Future<void> startUpload(XFile file) async {
    final localId = _nextLocalId();
    final entry = PhotoUploadEntry(
      localId: localId,
      file: file,
      status: PhotoUploadStatus.preparing,
      progress: 0.0,
    );
    state = {...state, localId: entry};
    await _doUpload(localId);
  }

  Future<void> retryUpload(String localId) async {
    final entry = state[localId];
    if (entry == null || !entry.canRetry) return;

    state = {
      ...state,
      localId: entry.copyWith(
        status: PhotoUploadStatus.preparing,
        progress: 0.0,
        clearServerPhotoId: true,
        clearErrorMessage: true,
        clearRejectionReason: true,
      ),
    };
    await _doUpload(localId);
  }

  void dismissUpload(String localId) {
    final updated = Map<String, PhotoUploadEntry>.from(state);
    updated.remove(localId);
    state = updated;
  }

  void clearTerminalUploads() {
    state = Map.fromEntries(state.entries.where((e) => !e.value.isTerminal));
  }

  Future<void> _doUpload(String localId) async {
    final entry = state[localId];
    if (entry == null) return;

    final currentUser = await user_guard.requireSelectedUser(ref);
    final apiClient = ref.read(apiClientProvider);

    final MultipartFile multipart;
    final path = entry.file.path;
    if (path.isNotEmpty && File(path).existsSync()) {
      multipart = await MultipartFile.fromFile(path, filename: entry.file.name);
    } else {
      final bytes = await entry.file.readAsBytes();
      multipart = MultipartFile.fromBytes(bytes, filename: entry.file.name);
    }

    _updateEntry(
      localId,
      (e) => e.copyWith(status: PhotoUploadStatus.uploading),
    );

    try {
      final response = await apiClient.uploadPhoto(
        userId: currentUser.id,
        photo: multipart,
        onSendProgress: (sent, total) {
          if (total > 0) {
            final progress = sent / total;
            _updateEntry(localId, (e) => e.copyWith(progress: progress));
          }
        },
      );

      final newPhoto = response.photo;

      if (newPhoto.moderationStatus == PhotoModerationStatus.rejected) {
        _updateEntry(
          localId,
          (e) => e.copyWith(
            status: PhotoUploadStatus.rejected,
            progress: 1.0,
            serverPhotoId: newPhoto.id,
            rejectionReason:
                newPhoto.rejectionReason ?? 'Photo was not approved.',
            clearErrorMessage: true,
          ),
        );
        _invalidateAfterPhotoChange(currentUser.id);
        return;
      }

      _updateEntry(
        localId,
        (e) => e.copyWith(
          status: PhotoUploadStatus.succeeded,
          progress: 1.0,
          serverPhotoId: newPhoto.id,
          clearErrorMessage: true,
          clearRejectionReason: true,
        ),
      );
      _invalidateAfterPhotoChange(currentUser.id);
    } on ApiError catch (error) {
      if (_isPhotoValidationError(error)) {
        _updateEntry(
          localId,
          (e) => e.copyWith(
            status: PhotoUploadStatus.rejected,
            progress: 1.0,
            rejectionReason: error.message,
            clearErrorMessage: true,
          ),
        );
      } else {
        _updateEntry(
          localId,
          (e) => e.copyWith(
            status: PhotoUploadStatus.failed,
            progress: 0.0,
            errorMessage: error.message,
            clearRejectionReason: true,
          ),
        );
      }
    } catch (_) {
      _updateEntry(
        localId,
        (e) => e.copyWith(
          status: PhotoUploadStatus.failed,
          progress: 0.0,
          errorMessage: 'Upload failed. Please try again.',
          clearRejectionReason: true,
        ),
      );
    }
  }

  bool _isPhotoValidationError(ApiError error) {
    final statusCode = error.statusCode;
    if (statusCode == 400 || statusCode == 422) {
      return true;
    }

    final code = error.code?.toLowerCase();
    if (code == null) {
      return false;
    }

    return code.contains('validation') ||
        code.contains('content') ||
        code.contains('moderation') ||
        code.contains('rejection') ||
        code.contains('rejected');
  }

  void _updateEntry(
    String localId,
    PhotoUploadEntry Function(PhotoUploadEntry) updater,
  ) {
    final entry = state[localId];
    if (entry == null) return;
    state = {...state, localId: updater(entry)};
  }

  void _invalidateAfterPhotoChange(String userId) {
    ref.invalidate(userPhotosProvider);
    ref.invalidate(profileProvider);
    ref.invalidate(profileEditSnapshotProvider);
    ref.invalidate(otherUserProfileProvider(userId));
    ref.read(authControllerProvider.notifier).refreshMe();
  }
}
