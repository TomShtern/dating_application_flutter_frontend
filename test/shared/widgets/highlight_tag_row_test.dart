import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/shared/widgets/highlight_tag_row.dart';

void main() {
  Widget buildSubject(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  testWidgets('returns an empty box when there are no tags', (tester) async {
    await tester.pumpWidget(buildSubject(const HighlightTagRow(tags: [])));

    expect(find.byType(SizedBox), findsOneWidget);
    expect(find.byType(Chip), findsNothing);
  });

  testWidgets('renders tags in a wrapping row', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        const HighlightTagRow(
          tags: ['Lives nearby', 'Hiking', 'Good sync'],
          icon: Icons.auto_awesome_outlined,
        ),
      ),
    );

    expect(find.byType(Wrap), findsOneWidget);
    expect(find.byType(Chip), findsNWidgets(3));
    expect(find.byIcon(Icons.auto_awesome_outlined), findsNWidgets(3));
  });
}
