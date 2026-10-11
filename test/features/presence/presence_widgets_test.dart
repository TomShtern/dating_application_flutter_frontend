import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/api/api_error.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/presence/presence_widgets.dart';
import 'package:flutter_dating_application_1/models/user_presence.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';

void main() {
  const dana = UserSummary(
    id: '11111111-1111-1111-1111-111111111111',
    name: 'Dana',
    age: 27,
    state: 'ACTIVE',
  );
  const noaId = '22222222-2222-2222-2222-222222222222';
  const mayaId = '33333333-3333-3333-3333-333333333333';

  Future<void> pumpDots(
    WidgetTester tester,
    _FakeListPresenceApiClient apiClient,
    Widget child,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          selectedUserProvider.overrideWith((ref) async => dana),
        ],
        child: MaterialApp(home: Scaffold(body: child)),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('the list dot shows only for an ONLINE user', (tester) async {
    final apiClient = _FakeListPresenceApiClient({
      noaId: PresenceStatus.online,
      mayaId: PresenceStatus.away,
    });

    await pumpDots(
      tester,
      apiClient,
      const Column(
        children: [
          PresenceDot(key: Key('noa'), userId: noaId),
          PresenceDot(key: Key('maya'), userId: mayaId),
        ],
      ),
    );

    Finder dotOf(String key) => find.descendant(
      of: find.byKey(Key(key)),
      matching: find.bySemanticsLabel('Online'),
    );
    expect(dotOf('noa'), findsOneWidget);
    expect(dotOf('maya'), findsNothing);
    // List rows ask without a conversation id.
    expect(apiClient.requests, containsAll([(noaId, null), (mayaId, null)]));

    // The next minute's refresh picks up the change.
    apiClient.statuses[noaId] = PresenceStatus.offline;
    apiClient.statuses[mayaId] = PresenceStatus.online;
    await tester.pump(const Duration(seconds: 60));
    await tester.pump();

    expect(dotOf('noa'), findsNothing);
    expect(dotOf('maya'), findsOneWidget);
  });

  testWidgets('the list dot hides silently when presence fails', (
    tester,
  ) async {
    final apiClient = _FakeListPresenceApiClient({
      noaId: PresenceStatus.online,
    });
    await pumpDots(tester, apiClient, const PresenceDot(userId: noaId));
    expect(find.bySemanticsLabel('Online'), findsOneWidget);

    apiClient.error = const ApiError(message: 'Refused', statusCode: 403);
    await tester.pump(const Duration(seconds: 60));
    await tester.pump();

    expect(find.bySemanticsLabel('Online'), findsNothing);
    expect(find.text('Refused'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a row on a tab that is not showing is not fetched', (
    tester,
  ) async {
    final apiClient = _FakeListPresenceApiClient({
      noaId: PresenceStatus.online,
      mayaId: PresenceStatus.online,
    });

    await pumpDots(
      tester,
      apiClient,
      const IndexedStack(
        index: 0,
        children: [
          PresenceDot(userId: noaId),
          PresenceDot(userId: mayaId),
        ],
      ),
    );
    await tester.pump(const Duration(seconds: 60));

    expect(apiClient.requests.map((request) => request.$1).toSet(), {noaId});
  });
}

class _FakeListPresenceApiClient extends ApiClient {
  _FakeListPresenceApiClient(this.statuses) : super(dio: Dio());

  final Map<String, PresenceStatus> statuses;
  final List<(String, String?)> requests = [];
  ApiError? error;

  @override
  Future<void> sendHeartbeat({required String userId}) async {}

  @override
  Future<UserPresence> getPresence({
    required String userId,
    String? conversationId,
  }) async {
    requests.add((userId, conversationId));
    if (error case final error?) {
      throw error;
    }
    return UserPresence(
      status: statuses[userId] ?? PresenceStatus.offline,
      typing: false,
    );
  }
}
