import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dating_application_1/shared/widgets/compact_context_strip.dart';

void main() {
  group('CompactContextStrip', () {
    Widget buildSubject({
      IconData? leadingIcon,
      String? label,
      Widget? trailing,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: CompactContextStrip(
            leadingIcon: leadingIcon,
            label: label,
            trailing: trailing,
          ),
        ),
      );
    }

    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(buildSubject(label: '2 km away'));

      expect(find.text('2 km away'), findsOneWidget);
    });

    testWidgets('renders leading icon when provided', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          leadingIcon: Icons.location_on_outlined,
          label: 'New York',
        ),
      );

      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    });

    testWidgets('does not render icon when null', (tester) async {
      await tester.pumpWidget(buildSubject(label: 'Test'));

      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('renders trailing widget', (tester) async {
      await tester.pumpWidget(
        buildSubject(label: 'Test', trailing: const Text('trail')),
      );

      expect(find.text('trail'), findsOneWidget);
    });

    testWidgets('renders inline children', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompactContextStrip(
              label: 'Parent',
              children: [Text('chip1'), Text('chip2')],
            ),
          ),
        ),
      );

      expect(find.text('chip1'), findsOneWidget);
      expect(find.text('chip2'), findsOneWidget);
    });
  });
}
