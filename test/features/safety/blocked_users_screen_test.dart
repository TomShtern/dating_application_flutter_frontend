import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/safety/blocked_users_provider.dart';
import 'package:flutter_dating_application_1/features/safety/blocked_users_screen.dart';
import 'package:flutter_dating_application_1/models/blocked_user_summary.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const currentUser = UserSummary(
    id: '11111111-1111-1111-1111-111111111111',
    name: 'Dana',
    age: 27,
    state: 'ACTIVE',
  );

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
    expect(find.text('Unblock'), findsNothing);
    expect(find.byTooltip('Blocked user options'), findsNWidgets(2));
  });

  testWidgets('requires confirmation before unblocking a profile', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeBlockedUsersApiClient(
      blockedUsers: const [
        BlockedUserSummary(
          userId: 'blocked-1',
          name: 'Noa',
          statusLabel: 'Hidden from your activity',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          selectedUserProvider.overrideWith((ref) async => currentUser),
        ],
        child: const MaterialApp(home: BlockedUsersScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Blocked user options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unblock'));
    await tester.pumpAndSettle();

    expect(find.text('Unblock Noa?'), findsOneWidget);
    expect(apiClient.unblockedTargetId, isNull);

    await tester.tap(find.widgetWithText(FilledButton, 'Unblock'));
    await tester.pumpAndSettle();

    expect(apiClient.unblockedTargetId, 'blocked-1');
  });
}

class _FakeBlockedUsersApiClient extends ApiClient {
  _FakeBlockedUsersApiClient({required this.blockedUsers}) : super(dio: Dio());

  final List<BlockedUserSummary> blockedUsers;
  String? unblockedTargetId;

  @override
  Future<List<BlockedUserSummary>> getBlockedUsers({
    required String userId,
  }) async {
    return blockedUsers;
  }

  @override
  Future<String> unblockUser({
    required String userId,
    required String targetId,
  }) async {
    unblockedTargetId = targetId;
    return 'User unblocked.';
  }
}
