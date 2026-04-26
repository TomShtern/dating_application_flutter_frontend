import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/chat/conversation_thread_provider.dart';
import 'package:flutter_dating_application_1/features/chat/conversation_thread_screen.dart';
import 'package:flutter_dating_application_1/features/notifications/notifications_provider.dart';
import 'package:flutter_dating_application_1/features/notifications/notifications_screen.dart';
import 'package:flutter_dating_application_1/models/message_dto.dart';
import 'package:flutter_dating_application_1/models/notification_item.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';

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
        createdAt: now.subtract(const Duration(minutes: 5)).toUtc(),
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
    expect(find.textContaining('5m ago'), findsOneWidget);
    expect(find.textContaining('3 days ago'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Read'),
      250,
      scrollable: notificationsScrollable(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Read'), findsOneWidget);
  });

  testWidgets(
    'shows safe route actions only for known types with required data',
    (WidgetTester tester) async {
      final notifications = [
        NotificationItem(
          id: 'notification-1',
          type: 'MATCH_FOUND',
          title: 'New match',
          message: 'You have a new match.',
          createdAt: DateTime.now(),
          isRead: false,
          data: const {
            'matchId': 'match-1',
            'conversationId': 'conversation-1',
            'otherUserId': 'user-2',
          },
        ),
        NotificationItem(
          id: 'notification-2',
          type: 'NEW_MESSAGE',
          title: 'Missing sender',
          message: 'This should stay display-only.',
          createdAt: DateTime.now(),
          isRead: true,
          data: const {'conversationId': 'conversation-2'},
        ),
        NotificationItem(
          id: 'notification-3',
          type: 'FUTURE_EVENT',
          title: 'Future event',
          message: 'Unknown types should stay display-only.',
          createdAt: DateTime.now(),
          isRead: true,
          data: const {'conversationId': 'conversation-3'},
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedUserProvider.overrideWith(
              (ref) async => const UserSummary(
                id: 'user-1',
                name: 'Dana',
                age: 29,
                state: 'ACTIVE',
              ),
            ),
            notificationsProvider.overrideWith((ref) async => notifications),
            conversationThreadProvider(
              'conversation-1',
            ).overrideWith((ref) async => const <MessageDto>[]),
          ],
          child: const MaterialApp(home: NotificationsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Open chat'), findsOneWidget);
      expect(find.text('Open thread'), findsNothing);
      expect(find.text('View profile'), findsNothing);

      await tester.tap(find.text('Open chat'));
      await tester.pumpAndSettle();

      expect(find.byType(ConversationThreadScreen), findsOneWidget);
    },
  );
}
