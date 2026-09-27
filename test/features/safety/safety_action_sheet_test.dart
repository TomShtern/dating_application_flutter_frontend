import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/api/report_reason.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/safety/safety_action_sheet.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';

void main() {
  const currentUser = UserSummary(
    id: '11111111-1111-1111-1111-111111111111',
    name: 'Dana',
    age: 27,
    state: 'ACTIVE',
  );

  const otherUser = UserSummary(
    id: '22222222-2222-2222-2222-222222222222',
    name: 'Noa',
    age: 29,
    state: 'ACTIVE',
  );

  testWidgets('shows report, block, and unmatch actions for another user', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedUserProvider.overrideWith((ref) async => currentUser),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SafetyActionSheet(
              targetUserId: otherUser.id,
              targetUserName: otherUser.name,
              canUnmatch: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Block user'), findsOneWidget);
    expect(find.text('Report user'), findsOneWidget);
    expect(find.text('Unmatch'), findsOneWidget);
    expect(find.text('Report ${otherUser.name}?'), findsNothing);
  });

  testWidgets('submits a report with the chosen reason and block flag', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final apiClient = _FakeSafetyActionApiClient();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          selectedUserProvider.overrideWith((ref) async => currentUser),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SafetyActionsButton(
                targetUserId: otherUser.id,
                targetUserName: otherUser.name,
                canUnmatch: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Safety actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Safety actions').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Report user'));
    await tester.tap(find.text('Report user'));
    await tester.pumpAndSettle();

    expect(find.text('Report ${otherUser.name}?'), findsOneWidget);

    await tester.ensureVisible(find.text('Spam or scam'));
    await tester.tap(find.text('Spam or scam'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Submit report'));
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();

    expect(apiClient.reportCalls, [otherUser.id]);
    expect(apiClient.lastReport?.reason, ReportReason.spam);
    expect(apiClient.lastReport?.blockUser, isTrue);
    expect(find.text('User reported.'), findsOneWidget);
  });

  testWidgets('hides safety actions for the current user', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedUserProvider.overrideWith((ref) async => currentUser),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SafetyActionsButton(
                targetUserId: currentUser.id,
                targetUserName: currentUser.name,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Safety actions'), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsNothing);
  });

  testWidgets('direct sheet instances suppress self-directed actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedUserProvider.overrideWith((ref) async => currentUser),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SafetyActionSheet(
              targetUserId: currentUser.id,
              targetUserName: currentUser.name,
              canUnmatch: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Safety actions are unavailable for your own profile.'),
      findsOneWidget,
    );
    expect(find.text('Block user'), findsNothing);
    expect(find.text('Report user'), findsNothing);
    expect(find.text('Unmatch'), findsNothing);
  });
}

class _FakeSafetyActionApiClient extends ApiClient {
  _FakeSafetyActionApiClient() : super(dio: Dio());

  final List<String> reportCalls = <String>[];
  ReportUserRequest? lastReport;

  @override
  Future<String> reportUser({
    required String userId,
    required String targetId,
    required ReportUserRequest report,
  }) async {
    reportCalls.add(targetId);
    lastReport = report;
    return 'User reported.';
  }
}
