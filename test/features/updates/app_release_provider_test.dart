import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/features/updates/app_release_provider.dart';

/// Answers every request with one scripted status and body.
class _FixedAdapter implements HttpClientAdapter {
  _FixedAdapter(this.status, this.body);

  final int status;
  final String body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // GitHub serves release files as a download, not as JSON.
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: ['application/octet-stream'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  final manifestUrl = Uri.parse('https://example.com/latest.json');
  const manifest = {
    'versionCode': 5,
    'versionName': '1.0.4',
    'apkUrl': 'https://example.com/app-5.apk',
    'sha256': 'abc123',
    'notes': 'Bug fixes',
  };

  Dio dioAnswering(int status, Object? body) => Dio()
    ..httpClientAdapter = _FixedAdapter(
      status,
      body is String ? body : jsonEncode(body),
    );

  group('AppRelease.tryParse', () {
    test('reads a complete manifest', () {
      final release = AppRelease.tryParse(manifest)!;

      expect(release.versionCode, 5);
      expect(release.versionName, '1.0.4');
      expect(release.apkUrl, Uri.parse('https://example.com/app-5.apk'));
      expect(release.sha256, 'abc123');
      expect(release.notes, 'Bug fixes');
    });

    test('empty notes become null', () {
      expect(AppRelease.tryParse({...manifest, 'notes': ''})!.notes, isNull);
    });

    test('rejects anything that is not a usable manifest', () {
      expect(AppRelease.tryParse('nope'), isNull);
      expect(AppRelease.tryParse({...manifest, 'versionCode': '5'}), isNull);
      expect(AppRelease.tryParse({...manifest}..remove('apkUrl')), isNull);
      expect(AppRelease.tryParse({...manifest}..remove('sha256')), isNull);
      expect(AppRelease.tryParse({...manifest, 'sha256': ''}), isNull);
    });

    test('accepts only an https link with a host', () {
      for (final url in [
        'http://example.com/app.apk',
        'file:///sdcard/app.apk',
        '/app.apk',
        'https:///app.apk',
      ]) {
        expect(
          AppRelease.tryParse({...manifest, 'apkUrl': url}),
          isNull,
          reason: url,
        );
      }
    });
  });

  group('fetchNewerRelease', () {
    test('returns a build newer than the installed one', () async {
      final release = await fetchNewerRelease(
        dioAnswering(200, manifest),
        manifestUrl,
        4,
      );

      expect(release?.versionCode, 5);
    });

    test('returns null when the installed build is current or newer', () async {
      final dio = dioAnswering(200, manifest);

      expect(await fetchNewerRelease(dio, manifestUrl, 5), isNull);
      expect(await fetchNewerRelease(dio, manifestUrl, 6), isNull);
    });

    test('fails when nothing is published', () {
      expect(
        fetchNewerRelease(dioAnswering(404, 'Not Found'), manifestUrl, 4),
        throwsA(isA<DioException>()),
      );
    });

    test('fails on a file that is not a manifest', () {
      expect(
        fetchNewerRelease(dioAnswering(200, '<html></html>'), manifestUrl, 4),
        throwsA(isA<FormatException>()),
      );
      expect(
        fetchNewerRelease(
          dioAnswering(200, {'versionCode': 9}),
          manifestUrl,
          4,
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('ReleaseDownload', () {
    final release = AppRelease.tryParse(manifest)!;

    ProviderContainer containerWith(
      Stream<int> Function(AppRelease) installer,
    ) {
      final container = ProviderContainer(
        overrides: [releaseInstallerProvider.overrideWithValue(installer)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('follows the percent and returns to idle when done', () async {
      final seen = <int?>[];
      final container = containerWith((_) => Stream.fromIterable([10, 60]));
      container.listen(releaseDownloadProvider, (_, next) => seen.add(next));

      final ok = await container
          .read(releaseDownloadProvider.notifier)
          .run(release);

      expect(ok, isTrue);
      expect(seen, [0, 10, 60, null]);
    });

    test('reports a failed install and returns to idle', () async {
      final container = containerWith(
        (_) => Stream.error(StateError('checksum mismatch')),
      );

      final ok = await container
          .read(releaseDownloadProvider.notifier)
          .run(release);

      expect(ok, isFalse);
      expect(container.read(releaseDownloadProvider), isNull);
    });

    test('a second run while one is downloading starts nothing', () async {
      var started = 0;
      final container = containerWith((_) async* {
        started++;
        yield 5;
      });
      final notifier = container.read(releaseDownloadProvider.notifier);

      final first = notifier.run(release);
      final second = await notifier.run(release);
      await first;

      expect(second, isTrue);
      expect(started, 1);
    });
  });
}
