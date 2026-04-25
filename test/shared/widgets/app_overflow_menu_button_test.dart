import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dating_application_1/shared/widgets/app_overflow_menu_button.dart';

void main() {
  group('AppOverflowMenuButton', () {
    Widget buildSubject({void Function(String)? onSelected}) {
      return MaterialApp(
        home: Scaffold(
          body: AppOverflowMenuButton<String>(
            items: const [
              PopupMenuItem(value: 'block', child: Text('Block')),
              PopupMenuItem(value: 'report', child: Text('Report')),
            ],
            onSelected: onSelected,
          ),
        ),
      );
    }

    testWidgets('renders overflow icon', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('shows popup menu on tap', (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Block'), findsOneWidget);
      expect(find.text('Report'), findsOneWidget);
    });

    testWidgets('calls onSelected when menu item tapped', (tester) async {
      String? selected;
      await tester.pumpWidget(
        buildSubject(onSelected: (value) => selected = value),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Block'));
      await tester.pumpAndSettle();

      expect(selected, 'block');
    });
  });
}
