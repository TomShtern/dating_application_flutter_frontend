import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dating_application_1/shared/widgets/compatibility_meter.dart';

void main() {
  group('CompatibilityMeter', () {
    Widget buildSubject({
      required int score,
      String? label,
      String? starDisplay,
      bool compact = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: CompatibilityMeter(
            score: score,
            label: label,
            starDisplay: starDisplay,
            compact: compact,
          ),
        ),
      );
    }

    testWidgets('renders score number', (tester) async {
      await tester.pumpWidget(buildSubject(score: 85));

      expect(find.text('85'), findsOneWidget);
    });

    testWidgets('renders label when provided', (tester) async {
      await tester.pumpWidget(buildSubject(score: 72, label: 'Match'));

      expect(find.text('Match'), findsOneWidget);
    });

    testWidgets('renders star display when provided', (tester) async {
      await tester.pumpWidget(buildSubject(score: 90, starDisplay: '★★★★½'));

      expect(find.text('★★★★½'), findsOneWidget);
    });

    testWidgets('renders progress bar', (tester) async {
      await tester.pumpWidget(buildSubject(score: 60));

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('compact mode renders smaller elements', (tester) async {
      await tester.pumpWidget(buildSubject(score: 50, compact: true));

      expect(find.text('50'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('score is clamped to 0-100 range', (tester) async {
      await tester.pumpWidget(buildSubject(score: 150));

      // Score text shows raw value but bar is clamped
      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, 1.0);
    });

    testWidgets('zero score renders bar at 0', (tester) async {
      await tester.pumpWidget(buildSubject(score: 0));

      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, 0.0);
    });
  });
}
