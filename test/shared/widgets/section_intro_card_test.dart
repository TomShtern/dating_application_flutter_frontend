import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/shared/widgets/section_intro_card.dart';

void main() {
  Widget buildSubject(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  testWidgets('renders icon, title, description, trailing, and badges', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        SectionIntroCard(
          icon: Icons.favorite_outline,
          title: 'Standouts',
          description: 'The people worth a closer look.',
          trailing: const Icon(Icons.chevron_right),
          badges: const [Chip(label: Text('Updated today'))],
        ),
      ),
    );

    expect(find.byIcon(Icons.favorite_outline), findsOneWidget);
    expect(find.text('Standouts'), findsOneWidget);
    expect(find.text('The people worth a closer look.'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(find.text('Updated today'), findsOneWidget);
  });
}
