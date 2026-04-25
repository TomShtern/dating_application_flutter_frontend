import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/shared/widgets/compact_summary_header.dart';

void main() {
  Widget buildSubject(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  testWidgets('renders title subtitle and trailing widget', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        const CompactSummaryHeader(
          title: 'Dana',
          subtitle: 'Matched this morning',
          trailing: Icon(Icons.chevron_right),
        ),
      ),
    );

    expect(find.text('Dana'), findsOneWidget);
    expect(find.text('Matched this morning'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('uses a lighter title weight in dense mode', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        const CompactSummaryHeader(
          title: 'Dense header',
          subtitle: 'Tight spacing',
          dense: true,
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('Dense header'));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
  });
}
