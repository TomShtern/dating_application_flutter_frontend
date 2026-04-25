import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/shared/widgets/shell_hero.dart';

void main() {
  Widget buildSubject(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  testWidgets('renders eyebrow pill, title, description, badges, and footer', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        ShellHero(
          title: 'Discover',
          description: 'Meet people nearby.',
          eyebrowLabel: 'Fresh today',
          eyebrowIcon: Icons.local_fire_department_outlined,
          badges: const [Chip(label: Text('2 pending likes'))],
          footer: const Text('Footer note'),
        ),
      ),
    );

    expect(find.text('Fresh today'), findsOneWidget);
    expect(find.byIcon(Icons.local_fire_department_outlined), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Meet people nearby.'), findsOneWidget);
    expect(find.text('2 pending likes'), findsOneWidget);
    expect(find.text('Footer note'), findsOneWidget);
  });

  testWidgets('supports centered compact layouts', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        const ShellHero(
          title: 'Compact hero',
          description: 'Centered copy',
          compact: true,
          centerContent: true,
        ),
      ),
    );

    final title = tester.widget<Text>(find.text('Compact hero'));
    expect(title.textAlign, TextAlign.center);
  });

  testWidgets('pill text truncates instead of overflowing', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        const ShellHeroPill(
          label: 'This eyebrow label is intentionally long to test ellipsis',
        ),
      ),
    );

    final text = tester.widget<Text>(find.byType(Text));
    expect(text.overflow, TextOverflow.ellipsis);
  });
}
