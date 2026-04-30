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

Finder notificationsScrollable() {
  return find.descendant(
    of: find.byType(NotificationsScreen),
    matching: find.byType(Scrollable),
  );
}

final DateTime _referenceNow = DateTime.utc(2026, 4, 23, 12);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'shows a notifications intro card summary and keeps refresh out of the app bar',
    (WidgetTester tester) async {
      final now = _referenceNow.toLocal();
      final notifications = [
        NotificationItem(
          id: 'notification-1',
          type: 'MATCH_FOUND',
          title: 'Unread match',
          message: 'A new match just came in.',
          createdAt: now.subtract(const Duration(minutes: 5)),
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
          title: 'Unread message',
          message: 'A new message arrived.',
          createdAt: now.subtract(const Duration(minutes: 20)),
          isRead: false,
          data: const {
            'conversationId': 'conversation-1',
            'senderId': 'user-2',
            'messageId': 'message-1',
          },
        ),
        NotificationItem(
          id: 'notification-3',
          type: 'SYSTEM',
          title: 'Read reminder',
          message: 'This one is already read.',
          createdAt: now.subtract(const Duration(hours: 2)),
          isRead: true,
          data: const {},
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationsProvider.overrideWith((ref) async => notifications),
          ],
          child: MaterialApp(home: NotificationsScreen(now: _referenceNow)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsWidgets);
      expect(find.text('2 unread of 3'), findsOneWidget);
      expect(find.text('Unread only'), findsOneWidget);
      expect(find.text('Mark all read'), findsOneWidget);
      expect(find.byTooltip('Refresh'), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
    },
  );

  testWidgets(
    'groups notifications by Today, Yesterday, and Earlier without inline status badges',
    (WidgetTester tester) async {
      final now = _referenceNow.toLocal();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final notifications = [
        NotificationItem(
          id: 'notification-1',
          type: 'MATCH',
          title: 'Today update',
          message: 'A fresh update from today.',
          createdAt: now.subtract(const Duration(minutes: 5)),
          isRead: false,
          data: const {},
        ),
        NotificationItem(
          id: 'notification-2',
          type: 'MESSAGE',
          title: 'Yesterday update',
          message: 'Something arrived yesterday.',
          createdAt: startOfToday.subtract(const Duration(hours: 2)),
          isRead: true,
          data: const {},
        ),
        NotificationItem(
          id: 'notification-3',
          type: 'MESSAGE',
          title: 'Earlier update',
          message: 'An older update for the earlier bucket.',
          createdAt: startOfToday
              .subtract(const Duration(days: 3))
              .add(const Duration(hours: 9)),
          isRead: true,
          data: const {},
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationsProvider.overrideWith((ref) async => notifications),
          ],
          child: MaterialApp(home: NotificationsScreen(now: _referenceNow)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsWidgets);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsWidgets);

      await tester.scrollUntilVisible(
        find.text('Earlier update'),
        250,
        scrollable: notificationsScrollable(),
      );
      await tester.pumpAndSettle();

      expect(find.text('Earlier'), findsOneWidget);
      expect(find.textContaining('5m ago'), findsOneWidget);
      expect(find.textContaining('3 days ago'), findsOneWidget);
      expect(find.text('Unread'), findsNothing);
      expect(find.text('Read'), findsNothing);
      expect(find.byTooltip('Mark read'), findsOneWidget);
    },
  );

  testWidgets(
    'opens routed notifications from the row and keeps incomplete or unknown items display only',
    (WidgetTester tester) async {
      final now = _referenceNow.toLocal();
      final notifications = [
        NotificationItem(
          id: 'notification-1',
          type: 'NEW_MESSAGE',
          title: 'Chat row',
          message: 'Tap the row, not a big button.',
          createdAt: now.subtract(const Duration(minutes: 2)),
          isRead: true,
          data: const {
            'conversationId': 'conversation-1',
            'senderId': 'user-2',
            'messageId': 'message-1',
          },
        ),
        NotificationItem(
          id: 'notification-2',
          type: 'MATCH_FOUND',
          title: 'Match row',
          message: 'This row used to expose an Open chat button.',
          createdAt: now.subtract(const Duration(minutes: 3)),
          isRead: true,
          data: const {
            'matchId': 'match-1',
            'conversationId': 'conversation-1',
            'otherUserId': 'user-2',
          },
        ),
        NotificationItem(
          id: 'notification-3',
          type: 'FRIEND_REQUEST',
          title: 'Profile row',
          message: 'This row used to expose a View profile button.',
          createdAt: now.subtract(const Duration(minutes: 4)),
          isRead: true,
          data: const {
            'requestId': 'request-1',
            'fromUserId': 'user-3',
            'matchId': 'match-2',
          },
        ),
        NotificationItem(
          id: 'notification-4',
          type: 'NEW_MESSAGE',
          title: 'Missing sender',
          message: 'This should stay display-only.',
          createdAt: now.subtract(const Duration(minutes: 5)),
          isRead: true,
          data: const {'conversationId': 'conversation-2'},
        ),
        NotificationItem(
          id: 'notification-5',
          type: 'FUTURE_EVENT',
          title: 'Future event',
          message: 'Unknown types should stay display-only.',
          createdAt: now.subtract(const Duration(minutes: 6)),
          isRead: true,
          data: const {},
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
          child: MaterialApp(home: NotificationsScreen(now: _referenceNow)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Open chat'), findsNothing);
      expect(find.text('Open thread'), findsNothing);
      expect(find.text('View profile'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('Missing sender'),
        250,
        scrollable: notificationsScrollable(),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Missing sender'));
      await tester.pumpAndSettle();
      expect(find.byType(ConversationThreadScreen), findsNothing);

      await tester.tap(find.text('Future event'));
      await tester.pumpAndSettle();
      expect(find.byType(ConversationThreadScreen), findsNothing);

      await tester.scrollUntilVisible(
        find.text('Chat row'),
        -250,
        scrollable: notificationsScrollable(),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chat row'));
      await tester.pumpAndSettle();

      expect(find.byType(ConversationThreadScreen), findsOneWidget);
    },
  );
}
