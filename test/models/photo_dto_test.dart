import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/models/photo_dto.dart';

void main() {
  group('PhotoListResponse', () {
    test('parses a delete-style payload with primaryUrl + photos', () {
      final response = PhotoListResponse.fromJson({
        'primaryUrl': 'http://localhost:7070/photos/u/p1.jpg',
        'photos': [
          {'id': 'p1', 'url': 'http://localhost:7070/photos/u/p1.jpg'},
          {'id': 'p2', 'url': 'http://localhost:7070/photos/u/p2.jpg'},
        ],
      });

      expect(response.primaryUrl, 'http://localhost:7070/photos/u/p1.jpg');
      expect(response.photos, hasLength(2));
      expect(response.photos.first, const PhotoDto(
        id: 'p1',
        url: 'http://localhost:7070/photos/u/p1.jpg',
      ));
    });

    test('treats null primaryUrl + empty photos as a valid empty state', () {
      final response = PhotoListResponse.fromJson({
        'primaryUrl': null,
        'photos': <dynamic>[],
      });

      expect(response.primaryUrl, isNull);
      expect(response.photos, isEmpty);
    });
  });

  group('PhotoUploadResponse', () {
    test('parses upload payload with photo + list together', () {
      final upload = PhotoUploadResponse.fromJson({
        'photo': {'id': 'new', 'url': 'http://h/photos/u/new.jpg'},
        'primaryUrl': 'http://h/photos/u/old.jpg',
        'photos': [
          {'id': 'old', 'url': 'http://h/photos/u/old.jpg'},
          {'id': 'new', 'url': 'http://h/photos/u/new.jpg'},
        ],
      });

      expect(upload.photo.id, 'new');
      expect(upload.list.photos, hasLength(2));
      expect(upload.list.primaryUrl, 'http://h/photos/u/old.jpg');
    });

    test('throws when the photo field is missing', () {
      expect(
        () => PhotoUploadResponse.fromJson({
          'primaryUrl': null,
          'photos': <dynamic>[],
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
