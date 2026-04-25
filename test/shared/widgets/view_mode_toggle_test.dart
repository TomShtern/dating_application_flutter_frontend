import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dating_application_1/shared/widgets/view_mode_toggle.dart';

void main() {
  group('ViewModeToggle', () {
    Widget buildSubject({required bool isGrid, ValueChanged<bool>? onChanged}) {
      return MaterialApp(
        home: Scaffold(
          body: ViewModeToggle(isGrid: isGrid, onChanged: onChanged),
        ),
      );
    }

    testWidgets('renders list icon unselected when isGrid is true', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(isGrid: true));

      expect(find.byIcon(Icons.view_list_outlined), findsOneWidget);
      expect(find.byIcon(Icons.grid_view_outlined), findsOneWidget);
    });

    testWidgets('renders both list and grid icons', (tester) async {
      await tester.pumpWidget(buildSubject(isGrid: false));

      expect(find.byIcon(Icons.view_list_outlined), findsOneWidget);
      expect(find.byIcon(Icons.grid_view_outlined), findsOneWidget);
    });

    testWidgets('calls onChanged with true when grid tapped', (tester) async {
      bool? selected;
      await tester.pumpWidget(
        buildSubject(isGrid: false, onChanged: (v) => selected = v),
      );

      await tester.tap(find.byIcon(Icons.grid_view_outlined));
      await tester.pumpAndSettle();

      expect(selected, true);
    });

    testWidgets('calls onChanged with false when list tapped', (tester) async {
      bool? selected;
      await tester.pumpWidget(
        buildSubject(isGrid: true, onChanged: (v) => selected = v),
      );

      await tester.tap(find.byIcon(Icons.view_list_outlined));
      await tester.pumpAndSettle();

      expect(selected, false);
    });
  });
}
