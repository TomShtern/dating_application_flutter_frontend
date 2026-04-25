import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dating_application_1/shared/widgets/person_photo_card.dart';
import 'package:flutter_dating_application_1/app/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('PersonPhotoCard', () {
    Widget buildSubject({
      int? age,
      String? photoUrl,
      String? location,
      VoidCallback? onTap,
      Widget? trailing,
      bool compact = false,
    }) {
      return ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              baseUrl: 'http://localhost:7070',
              lanSharedSecret: 'test',
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: PersonPhotoCard(
              name: 'Alice',
              age: age,
              photoUrl: photoUrl,
              location: location,
              onTap: onTap,
              trailing: trailing,
              compact: compact,
            ),
          ),
        ),
      );
    }

    testWidgets('renders name', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('renders age when provided', (tester) async {
      await tester.pumpWidget(buildSubject(age: 28));

      expect(find.text('28'), findsOneWidget);
    });

    testWidgets('does not render age when null', (tester) async {
      await tester.pumpWidget(buildSubject());

      // Should only find the name text, not an age
      expect(find.text('28'), findsNothing);
    });

    testWidgets('renders location when provided', (tester) async {
      await tester.pumpWidget(buildSubject(location: 'New York'));

      expect(find.text('New York'), findsOneWidget);
    });

    testWidgets('renders monogram fallback without photo', (tester) async {
      await tester.pumpWidget(buildSubject());

      // Falls back to initials: 'A' for 'Alice'
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('renders trailing widget', (tester) async {
      await tester.pumpWidget(
        buildSubject(trailing: const Icon(Icons.chevron_right)),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('responds to tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildSubject(onTap: () => tapped = true));

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('compact mode renders with smaller avatar', (tester) async {
      await tester.pumpWidget(buildSubject(compact: true));

      expect(find.text('Alice'), findsOneWidget);
      // Compact photos have a 44px diameter vs 56px
      final sizedBoxes = tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .where((box) => box.width == 44)
          .toList(growable: false);
      expect(sizedBoxes.length, 1);
    });
  });
}
