import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/api/api_error.dart';
import 'package:flutter_dating_application_1/app/app_config.dart';
import 'package:flutter_dating_application_1/shared/media/authenticated_photo_image.dart';
import 'package:flutter_dating_application_1/shared/widgets/app_network_image.dart';

/// A valid 1x1 PNG.
final _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
  '60e6kgAAAABJRU5ErkJggg==',
);

void main() {
  late _FakePhotoApiClient apiClient;

  setUp(() {
    apiClient = _FakePhotoApiClient();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  Widget scoped(Widget child) {
    return ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(
          const AppConfig(
            baseUrl: 'http://localhost:7070',
            lanSharedSecret: 'test-secret',
          ),
        ),
        apiClientProvider.overrideWithValue(apiClient),
      ],
      child: MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  Widget buildSubject({
    required String url,
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return scoped(
      AppNetworkImage(
        url: url,
        width: width,
        height: height,
        borderRadius: borderRadius,
      ),
    );
  }

  testWidgets('renders without error when width and height are null', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(url: 'https://example.com/photo.jpg'));
    await tester.pump();
    expect(find.byType(AppNetworkImage), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.height, isNull);
  });

  testWidgets('renders without error with finite width and height', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        url: 'https://example.com/photo.jpg',
        width: 200,
        height: 300,
      ),
    );
    await tester.pump();
    expect(find.byType(AppNetworkImage), findsOneWidget);
  });

  testWidgets('renders without error when width is infinite', (tester) async {
    await tester.pumpWidget(
      scoped(
        const SizedBox(
          width: double.infinity,
          child: AppNetworkImage(
            url: 'https://example.com/photo.jpg',
            width: double.infinity,
            height: 300,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(AppNetworkImage), findsOneWidget);
  });

  testWidgets('renders without error when height is infinite', (tester) async {
    await tester.pumpWidget(
      scoped(
        const SizedBox(
          height: double.infinity,
          child: AppNetworkImage(
            url: 'https://example.com/photo.jpg',
            width: 200,
            height: double.infinity,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(AppNetworkImage), findsOneWidget);
  });

  testWidgets('renders without error when width is zero', (tester) async {
    await tester.pumpWidget(
      buildSubject(url: 'https://example.com/photo.jpg', width: 0, height: 300),
    );
    await tester.pump();
    expect(find.byType(AppNetworkImage), findsOneWidget);
  });

  testWidgets('sanitizes negative height to null internally', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        url: 'https://example.com/photo.jpg',
        width: 200,
        height: -10,
      ),
    );
    await tester.pump();
    expect(find.byType(AppNetworkImage), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.height, isNull);
  });

  testWidgets('renders with borderRadius without error', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        url: 'https://example.com/photo.jpg',
        width: 200,
        height: 300,
        borderRadius: BorderRadius.circular(12),
      ),
    );
    await tester.pump();
    expect(find.byType(AppNetworkImage), findsOneWidget);
    expect(find.byType(ClipRRect), findsOneWidget);
  });

  testWidgets('loads a backend photo through the API client', (tester) async {
    await tester.pumpWidget(buildSubject(url: '/photos/u-1/a.jpg'));
    await tester.pump();

    expect(apiClient.requestedUrls, ['http://localhost:7070/photos/u-1/a.jpg']);
  });

  testWidgets('shows the decoded photo once its bytes arrive', (tester) async {
    apiClient.bytes = _pngBytes;
    const url = 'http://localhost:7070/photos/u-1/a.jpg';

    await tester.pumpWidget(scoped(const SizedBox.shrink()));
    await tester.runAsync(
      () => precacheImage(
        AuthenticatedPhotoImage(url, loadBytes: apiClient.getPhotoBytes),
        tester.element(find.byType(SizedBox).first),
      ),
    );
    await tester.pumpWidget(
      scoped(
        AppNetworkImage(
          url: url,
          fallbackBuilder: (context) => const Text('fallback'),
        ),
      ),
    );
    await tester.pump();

    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
    expect(find.text('fallback'), findsNothing);
  });

  for (final status in [401, 403, 404, 429]) {
    testWidgets('a $status shows the fallback quietly and is not retried', (
      tester,
    ) async {
      apiClient.error = ApiError(message: 'Refused', statusCode: status);

      await tester.pumpWidget(
        scoped(
          AppNetworkImage(
            url: '/photos/u-1/a.jpg',
            fallbackBuilder: (context) => const Text('fallback'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 30));

      expect(find.text('fallback'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
      expect(apiClient.requestedUrls, hasLength(1));
    });
  }

  test('cacheDim returns null for null, infinite, NaN, zero, and negative', () {
    const dpr = 2.0;

    expect(AppNetworkImage.cacheDim(null, dpr), isNull);
    expect(AppNetworkImage.cacheDim(double.infinity, dpr), isNull);
    expect(AppNetworkImage.cacheDim(double.nan, dpr), isNull);
    expect(AppNetworkImage.cacheDim(0, dpr), isNull);
    expect(AppNetworkImage.cacheDim(-50, dpr), isNull);

    expect(AppNetworkImage.cacheDim(100, dpr), 200);
    expect(AppNetworkImage.cacheDim(150.5, dpr), 301);
  });

  test('cacheDim computes correctly with fractional dpr', () {
    expect(AppNetworkImage.cacheDim(100, 1.5), 150);
    expect(AppNetworkImage.cacheDim(1, 3.0), 3);
  });
}

class _FakePhotoApiClient extends ApiClient {
  _FakePhotoApiClient() : super(dio: Dio());

  final List<String> requestedUrls = [];
  Uint8List? bytes;
  ApiError error = const ApiError(message: 'Not found', statusCode: 404);

  @override
  Future<Uint8List> getPhotoBytes(String url) async {
    requestedUrls.add(url);
    final bytes = this.bytes;
    if (bytes == null) {
      throw error;
    }
    return bytes;
  }
}
