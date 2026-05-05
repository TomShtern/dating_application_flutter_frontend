import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/shared/widgets/app_network_image.dart';

void main() {
  Widget buildSubject({
    required String url,
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: AppNetworkImage(
            url: url,
            width: width,
            height: height,
            borderRadius: borderRadius,
          ),
        ),
      ),
    );
  }

  testWidgets('renders without error when width and height are null', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(url: 'https://example.com/photo.jpg'));
    await tester.pump();
    expect(find.byType(AppNetworkImage), findsOneWidget);
    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
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
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: double.infinity,
              child: AppNetworkImage(
                url: 'https://example.com/photo.jpg',
                width: double.infinity,
                height: 300,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(AppNetworkImage), findsOneWidget);
  });

  testWidgets('renders without error when height is infinite', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              height: double.infinity,
              child: AppNetworkImage(
                url: 'https://example.com/photo.jpg',
                width: 200,
                height: double.infinity,
              ),
            ),
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
    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
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
