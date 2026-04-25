import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/app/app_config.dart';
import 'package:flutter_dating_application_1/shared/widgets/user_avatar.dart';

void main() {
  Widget buildSubject({
    required String name,
    String? photoUrl,
    double radius = 24,
  }) {
    return ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(
          const AppConfig(
            baseUrl: 'http://localhost:7070',
            lanSharedSecret: 'test-secret',
          ),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: UserAvatar(name: name, photoUrl: photoUrl, radius: radius),
          ),
        ),
      ),
    );
  }

  testWidgets('renders monogram initials for two-word names', (tester) async {
    await tester.pumpWidget(buildSubject(name: 'Dana Sela'));

    expect(find.text('DS'), findsOneWidget);
  });

  testWidgets('renders a bullet for empty names', (tester) async {
    await tester.pumpWidget(buildSubject(name: '   '));

    expect(find.text('•'), findsOneWidget);
  });

  testWidgets('creates a network image when a photo url is provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(name: 'Dana', photoUrl: '/images/dana.jpg'),
    );

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('sizes the avatar from the radius', (tester) async {
    await tester.pumpWidget(buildSubject(name: 'Dana', radius: 30));

    final size = tester.getSize(find.byType(AnimatedContainer));
    expect(size.width, 60);
    expect(size.height, 60);
  });
}
