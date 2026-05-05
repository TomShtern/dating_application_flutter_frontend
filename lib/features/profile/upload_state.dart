import 'package:image_picker/image_picker.dart';

enum PhotoUploadStatus { preparing, uploading, succeeded, failed, rejected }

class PhotoUploadEntry {
  const PhotoUploadEntry({
    required this.localId,
    required this.file,
    this.progress = 0.0,
    this.status = PhotoUploadStatus.preparing,
    this.serverPhotoId,
    this.errorMessage,
    this.rejectionReason,
  });

  final String localId;
  final XFile file;
  final double progress;
  final PhotoUploadStatus status;
  final String? serverPhotoId;
  final String? errorMessage;
  final String? rejectionReason;

  PhotoUploadEntry copyWith({
    double? progress,
    PhotoUploadStatus? status,
    String? serverPhotoId,
    String? errorMessage,
    String? rejectionReason,
    bool clearServerPhotoId = false,
    bool clearErrorMessage = false,
    bool clearRejectionReason = false,
  }) {
    return PhotoUploadEntry(
      localId: localId,
      file: file,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      serverPhotoId: clearServerPhotoId
          ? null
          : serverPhotoId ?? this.serverPhotoId,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      rejectionReason: clearRejectionReason
          ? null
          : rejectionReason ?? this.rejectionReason,
    );
  }

  bool get isTerminal =>
      status == PhotoUploadStatus.succeeded ||
      status == PhotoUploadStatus.failed ||
      status == PhotoUploadStatus.rejected;

  bool get canRetry =>
      status == PhotoUploadStatus.failed ||
      status == PhotoUploadStatus.rejected;
}
