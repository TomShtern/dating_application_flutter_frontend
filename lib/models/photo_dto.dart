/// A single uploaded photo as returned by the backend.
///
/// `url` is an absolute URL ready to display (the backend resolves the
/// internal `/photos/...` path to a public URL before sending it).
class PhotoDto {
  const PhotoDto({required this.id, required this.url});

  final String id;
  final String url;

  factory PhotoDto.fromJson(Map<String, dynamic> json) {
    return PhotoDto(
      id: json['id'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'url': url};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PhotoDto && other.id == id && other.url == url);

  @override
  int get hashCode => Object.hash(id, url);
}

/// Standard response shape for any photo mutation endpoint
/// (upload / delete / reorder). Always returns the canonical photo
/// list and the current primary URL.
class PhotoListResponse {
  const PhotoListResponse({required this.primaryUrl, required this.photos});

  final String? primaryUrl;
  final List<PhotoDto> photos;

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
    );
  }
}

/// Upload responses include the newly created photo in addition to the
/// full list. We reuse `PhotoListResponse` but also expose the new one
/// so callers can highlight it without diffing.
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
