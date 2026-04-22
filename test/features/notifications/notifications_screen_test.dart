import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/features/notifications/notifications_provider.dart';
import 'package:flutter_dating_application_1/features/notifications/notifications_screen.dart';
import 'package:flutter_dating_application_1/models/notification_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Finder notificationsScrollable() {
    return find.descendant(
      of: find.byType(NotificationsScreen),
      matching: find.byType(Scrollable),
    );
  }

  testWidgets('renders a compact filter bar with consistent read states', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final notifications = [
      NotificationItem(
        id: 'notification-1',
        type: 'MATCH',
        title: 'It is a match',
        message: 'Noa liked you back.',
        createdAt: now.subtract(const Duration(hours: 2, minutes: 5)).toUtc(),
        isRead: false,
        data: const {},
      ),
      NotificationItem(
        id: 'notification-2',
        type: 'MESSAGE',
        title: 'New message',
        message: 'You have a fresh reply waiting.',
        createdAt: now.subtract(const Duration(days: 3, minutes: 10)).toUtc(),
        isRead: true,
        data: const {},
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationsProvider.overrideWith((ref) async => notifications),
        ],
        child: const MaterialApp(home: NotificationsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Notifications'), findsOneWidget);
    expect(
      find.text('Catch up on matches, messages, and other updates.'),
      findsNothing,
    );
    expect(find.text('2 notifications'), findsOneWidget);
    expect(find.text('1 unread'), findsOneWidget);
    expect(find.text('Read state and timing'), findsNothing);
    expect(find.text('Showing all activity'), findsNothing);
    expect(find.byType(FilterChip), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Unread'),
      250,
      scrollable: notificationsScrollable(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unread'), findsOneWidget);
    expect(find.text('Mark read'), findsOneWidget);
    expect(find.textContaining('2h ago'), findsOneWidget);
    expect(find.textContaining('Apr '), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Read'),
      250,
      scrollable: notificationsScrollable(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Read'), findsOneWidget);
  });
}
