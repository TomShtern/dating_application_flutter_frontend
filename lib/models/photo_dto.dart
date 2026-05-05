import 'profile_completion_info.dart';

enum PhotoModerationStatus {
  pending,
  approved,
  rejected;

  static PhotoModerationStatus? fromJson(dynamic value) {
    if (value is! String) return null;
    return switch (value.toUpperCase()) {
      'PENDING' => pending,
      'APPROVED' => approved,
      'REJECTED' => rejected,
      _ => null,
    };
  }
}

class PhotoDto {
  const PhotoDto({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    this.mediumUrl,
    this.moderationStatus,
    this.rejectionReason,
  });

  final String id;
  final String url;
  final String? thumbnailUrl;
  final String? mediumUrl;
  final PhotoModerationStatus? moderationStatus;
  final String? rejectionReason;

  factory PhotoDto.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.trim().isEmpty) {
      throw const FormatException('PhotoDto is missing a non-empty id.');
    }
    final url = json['url'];
    if (url is! String || url.trim().isEmpty) {
      throw const FormatException('PhotoDto is missing a non-empty url.');
    }
    return PhotoDto(
      id: id,
      url: url,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      mediumUrl: json['mediumUrl'] as String?,
      moderationStatus: PhotoModerationStatus.fromJson(json['moderationStatus']),
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
    if (mediumUrl != null) 'mediumUrl': mediumUrl,
    if (moderationStatus != null)
      'moderationStatus': moderationStatus!.name.toUpperCase(),
    if (rejectionReason != null) 'rejectionReason': rejectionReason,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PhotoDto &&
          other.id == id &&
          other.url == url &&
          other.thumbnailUrl == thumbnailUrl &&
          other.mediumUrl == mediumUrl &&
          other.moderationStatus == moderationStatus &&
          other.rejectionReason == rejectionReason);

  @override
  int get hashCode => Object.hash(
        id,
        url,
        thumbnailUrl,
        mediumUrl,
        moderationStatus,
        rejectionReason,
      );
}

class PhotoListResponse {
  const PhotoListResponse({
    required this.primaryUrl,
    required this.photos,
    this.completionInfo = const ProfileCompletionInfo(),
  });

  final String? primaryUrl;
  final List<PhotoDto> photos;
  final ProfileCompletionInfo completionInfo;

  factory PhotoListResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['photos'];
    final photos = raw is List
        ? raw
              .whereType<Map>()
              .map(
                (item) => PhotoDto.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(growable: false)
        : const <PhotoDto>[];

    return PhotoListResponse(
      primaryUrl: json['primaryUrl'] as String?,
      photos: photos,
      completionInfo: ProfileCompletionInfo.fromJson(
        json['completionInfo'] is Map
            ? Map<String, dynamic>.from(json['completionInfo'] as Map)
            : json,
      ),
    );
  }
}

class PhotoUploadResponse {
  const PhotoUploadResponse({
    required this.photo,
    required this.list,
  });

  final PhotoDto photo;
  final PhotoListResponse list;

  factory PhotoUploadResponse.fromJson(Map<String, dynamic> json) {
    final photoJson = json['photo'];
    if (photoJson is! Map) {
      throw const FormatException('Upload response missing the photo.');
    }

    return PhotoUploadResponse(
      photo: PhotoDto.fromJson(Map<String, dynamic>.from(photoJson)),
      list: PhotoListResponse.fromJson(json),
    );
  }
}