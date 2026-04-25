import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dating_application_1/shared/widgets/developer_only_callout_card.dart';

void main() {
  group('DeveloperOnlyCalloutCard', () {
    Widget buildSubject({
      String? description,
      Widget? child,
      List<Widget>? actions,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: DeveloperOnlyCalloutCard(
            title: 'Pick test user',
            description: description,
            actions: actions ?? [],
            child: child,
          ),
        ),
      );
    }

    testWidgets('renders developer badge', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Developer only'), findsOneWidget);
    });

    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Pick test user'), findsOneWidget);
    });

    testWidgets('renders description when provided', (tester) async {
      await tester.pumpWidget(
        buildSubject(description: 'Select a user for testing'),
      );

      expect(find.text('Select a user for testing'), findsOneWidget);
    });

    testWidgets('does not render description when null', (tester) async {
      await tester.pumpWidget(buildSubject());

      // Only the title and badge text should exist, no extra description
      final textWidgets = find
          .byType(Text)
          .evaluate()
          .map((e) => e.widget as Text)
          .toList();
      expect(
        textWidgets.any((t) => t.data == 'Select a user for testing'),
        isFalse,
      );
    });

    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(buildSubject(child: const Text('Child content')));

      expect(find.text('Child content'), findsOneWidget);
    });

    testWidgets('renders action buttons', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          actions: [TextButton(onPressed: () {}, child: const Text('Action'))],
        ),
      );

      expect(find.text('Action'), findsOneWidget);
    });
  });
}
