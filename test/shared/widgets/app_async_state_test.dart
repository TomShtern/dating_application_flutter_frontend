import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/shared/widgets/app_async_state.dart';

void main() {
  Widget buildSubject(Widget child, {Size? size}) {
    final effectiveSize = size ?? const Size(400, 700);

    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: effectiveSize.width,
            height: effectiveSize.height,
            child: child,
          ),
        ),
      ),
    );
  }

  testWidgets('renders loading state copy and spinner', (tester) async {
    await tester.pumpWidget(
      buildSubject(const AppAsyncState.loading(message: 'Loading candidates…')),
    );

    expect(find.text('Setting the mood'), findsOneWidget);
    expect(find.text('Loading candidates…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders empty state refresh action when provided', (
    tester,
  ) async {
    var refreshed = false;

    await tester.pumpWidget(
      buildSubject(
        AppAsyncState.empty(
          message: 'Nothing to see here.',
          onRefresh: () => refreshed = true,
        ),
      ),
    );

    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Refresh'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Refresh'));
    expect(refreshed, isTrue);
  });

  testWidgets('renders error state retry action', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      buildSubject(
        AppAsyncState.error(
          message: 'Backend unavailable.',
          onRetry: () => retried = true,
        ),
      ),
    );

    expect(find.text('That did not go to plan'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    expect(retried, isTrue);
  });

  testWidgets('uses compact layout without helper copy in tight spaces', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        const AppAsyncState.empty(message: 'Still empty.'),
        size: const Size(320, 180),
      ),
    );

    expect(find.text('Check back later for updates.'), findsNothing);
    expect(find.text('Still empty.'), findsOneWidget);
  });
}
