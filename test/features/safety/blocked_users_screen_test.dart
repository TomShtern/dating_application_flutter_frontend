import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/features/safety/blocked_users_provider.dart';
import 'package:flutter_dating_application_1/features/safety/blocked_users_screen.dart';
import 'package:flutter_dating_application_1/models/blocked_user_summary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('keeps the intro compact and lets blocked profiles own the screen', (
    WidgetTester tester,
  ) async {
    const blockedUsers = [
      BlockedUserSummary(
        userId: 'blocked-1',
        name: 'Noa',
        statusLabel: 'Hidden from your activity',
      ),
      BlockedUserSummary(
        userId: 'blocked-2',
        name: 'Mia',
        statusLabel: 'Recently blocked',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          blockedUsersProvider.overrideWith((ref) async => blockedUsers),
        ],
        child: const MaterialApp(home: BlockedUsersScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Blocked users'), findsOneWidget);
    expect(find.text('Safety stays on'), findsOneWidget);
    expect(find.text('2 blocked profiles'), findsOneWidget);
    expect(
      find.text(
        'Profiles you block stay out of discovery, matches, and chat until you unblock them here.',
      ),
      findsNothing,
    );
    expect(
      find.text(
        'Blocked profiles stay out of discovery, matches, and chat until you let them back in.',
      ),
      findsNothing,
    );
    expect(
      find.text(
        'Hidden from discovery, matches, and chat until you unblock them.',
      ),
      findsOneWidget,
    );
    expect(find.text('Pull to refresh'), findsNothing);
    expect(find.text('What happens here'), findsNothing);
    expect(find.text('Noa'), findsOneWidget);
    expect(find.text('Mia'), findsOneWidget);
    expect(find.text('Unblock'), findsNWidgets(2));
  });
}
