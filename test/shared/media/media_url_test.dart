import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/shared/media/media_url.dart';

void main() {
  test('keeps absolute media URLs unchanged', () {
    expect(
      resolveMediaUrl(
        rawUrl: 'https://cdn.example.com/photos/noa.jpg',
        baseUrl: 'http://10.0.2.2:7070',
      ),
      'https://cdn.example.com/photos/noa.jpg',
    );
  });

  test('resolves relative media URLs against the configured API base URL', () {
    expect(
      resolveMediaUrl(
        rawUrl: '/photos/noa.jpg',
        baseUrl: 'http://10.0.2.2:7070',
      ),
      'http://10.0.2.2:7070/photos/noa.jpg',
    );
  });

  test('returns null for empty or invalid media URLs', () {
    expect(
      resolveMediaUrl(rawUrl: '   ', baseUrl: 'http://10.0.2.2:7070'),
      isNull,
    );
    expect(
      resolveMediaUrl(
        rawUrl: 'http://[broken',
        baseUrl: 'http://10.0.2.2:7070',
      ),
      isNull,
    );
  });
}
