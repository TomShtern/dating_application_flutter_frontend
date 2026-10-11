import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/api/api_error.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/presence/presence_provider.dart';
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
  const conversationId = '$noaId-conversation';

  late _FakePresenceApiClient apiClient;
  UserSummary? signedInUser;

  setUp(() {
    apiClient = _FakePresenceApiClient();
    signedInUser = dana;
  });

  /// Timers must be cancelled before the test body ends, so every test
  /// disposes its container itself.
  Future<ProviderContainer> startPresence(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(apiClient),
        selectedUserProvider.overrideWith((ref) async => signedInUser),
      ],
    );
    container.listen(presenceControllerProvider, (previous, next) {});
    await tester.pump();
    return container;
  }

  void sendToBackground(WidgetTester tester) {
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
  }

  void bringToForeground(WidgetTester tester) {
    for (final state in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
  }

  testWidgets('heartbeat starts at once, repeats every 60 s, and follows the '
      'app lifecycle', (tester) async {
    final container = await startPresence(tester);

    expect(apiClient.heartbeatUserIds, [dana.id]);

    await tester.pump(const Duration(seconds: 59));
    expect(apiClient.heartbeatUserIds, hasLength(1));
    await tester.pump(const Duration(seconds: 1));
    expect(apiClient.heartbeatUserIds, hasLength(2));

    sendToBackground(tester);
    await tester.pump(const Duration(minutes: 5));
    expect(apiClient.heartbeatUserIds, hasLength(2));

    bringToForeground(tester);
    await tester.pump();
    expect(apiClient.heartbeatUserIds, hasLength(3));

    await tester.pump(const Duration(seconds: 60));
    expect(apiClient.heartbeatUserIds, hasLength(4));

    container.dispose();
  });

  testWidgets('heartbeat does not start while signed out and stops on '
      'sign-out', (tester) async {
    signedInUser = null;
    final container = await startPresence(tester);

    await tester.pump(const Duration(minutes: 2));
    expect(apiClient.heartbeatUserIds, isEmpty);

    // A bare container rebuilds an invalidated provider on a timer, so time
    // has to pass for the sign-in and sign-out to land.
    signedInUser = dana;
    container.invalidate(selectedUserProvider);
    await tester.pump(const Duration(seconds: 1));
    expect(apiClient.heartbeatUserIds, hasLength(1));

    signedInUser = null;
    container.invalidate(selectedUserProvider);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(minutes: 5));
    expect(apiClient.heartbeatUserIds, hasLength(1));

    container.dispose();
  });

  testWidgets('a failing heartbeat is swallowed and a 429 skips beats', (
    tester,
  ) async {
    apiClient.heartbeatError = const ApiError(
      message: 'Slow down',
      statusCode: 429,
    );
    final container = await startPresence(tester);
    expect(apiClient.heartbeatUserIds, hasLength(1));

    // The next two beats are skipped, the third is sent.
    await tester.pump(const Duration(seconds: 120));
    expect(apiClient.heartbeatUserIds, hasLength(1));
    await tester.pump(const Duration(seconds: 60));
    expect(apiClient.heartbeatUserIds, hasLength(2));

    container.dispose();
  });

  testWidgets('typing is sent at most once per 5 seconds', (tester) async {
    final container = await startPresence(tester);
    final presence = container.read(presenceControllerProvider.notifier);

    for (var i = 0; i < 10; i++) {
      presence.notifyTyping(conversationId);
    }
    expect(apiClient.typingRequests, [(dana.id, conversationId)]);

    await tester.pump(const Duration(milliseconds: 4900));
    presence.notifyTyping(conversationId);
    expect(apiClient.typingRequests, hasLength(1));

    await tester.pump(const Duration(milliseconds: 100));
    presence.notifyTyping(conversationId);
    presence.notifyTyping(conversationId);
    expect(apiClient.typingRequests, hasLength(2));

    container.dispose();
  });

  testWidgets('typing is not sent in the background', (tester) async {
    final container = await startPresence(tester);
    final presence = container.read(presenceControllerProvider.notifier);

    sendToBackground(tester);
    await tester.pump();
    presence.notifyTyping(conversationId);
    expect(apiClient.typingRequests, isEmpty);

    bringToForeground(tester);
    await tester.pump();
    container.dispose();
  });

  testWidgets('an open chat polls presence every 5 s with its conversation '
      'id and stops when closed or backgrounded', (tester) async {
    apiClient.presence = const UserPresence(
      status: PresenceStatus.online,
      typing: true,
    );
    final container = await startPresence(tester);
    final presence = container.read(presenceControllerProvider.notifier);

    final watch = presence.watch(noaId, conversationId: conversationId);
    await tester.pump();

    expect(apiClient.presenceRequests, [(noaId, conversationId)]);
    final state = container.read(presenceControllerProvider)[noaId];
    expect(state?.status, PresenceStatus.online);
    expect(state?.typing, isTrue);

    await tester.pump(const Duration(seconds: 5));
    expect(apiClient.presenceRequests, hasLength(2));

    sendToBackground(tester);
    await tester.pump(const Duration(seconds: 30));
    expect(apiClient.presenceRequests, hasLength(2));
    expect(container.read(presenceControllerProvider), isEmpty);

    bringToForeground(tester);
    await tester.pump();
    expect(apiClient.presenceRequests, hasLength(3));

    presence.unwatch(watch);
    await tester.pump(const Duration(seconds: 30));
    expect(apiClient.presenceRequests, hasLength(3));

    container.dispose();
  });

  testWidgets('a list row is read once, cached while scrolling, and '
      'refreshed every 60 s only while on screen', (tester) async {
    apiClient.presence = const UserPresence(
      status: PresenceStatus.online,
      typing: false,
    );
    final container = await startPresence(tester);
    final presence = container.read(presenceControllerProvider.notifier);

    var watch = presence.watch(noaId);
    await tester.pump();
    expect(apiClient.presenceRequests, [(noaId, null)]);

    // Scrolled away and back within the minute: no second request.
    presence.unwatch(watch);
    watch = presence.watch(noaId);
    final secondRow = presence.watch(noaId);
    await tester.pump();
    expect(apiClient.presenceRequests, hasLength(1));

    await tester.pump(const Duration(seconds: 60));
    expect(apiClient.presenceRequests, hasLength(2));

    // Off screen: no more refreshes, and the cached value is dropped.
    presence.unwatch(watch);
    presence.unwatch(secondRow);
    await tester.pump(const Duration(seconds: 60));
    expect(apiClient.presenceRequests, hasLength(2));
    expect(container.read(presenceControllerProvider), isEmpty);

    container.dispose();
  });

  testWidgets('a 403 drops only that user and never asks about them again', (
    tester,
  ) async {
    const formerMatchId = '33333333-3333-3333-3333-333333333333';
    apiClient.presence = const UserPresence(
      status: PresenceStatus.online,
      typing: false,
    );
    apiClient.forbiddenUserIds.add(formerMatchId);
    final container = await startPresence(tester);
    final presence = container.read(presenceControllerProvider.notifier);

    presence.watch(formerMatchId);
    await tester.pump();
    presence.watch(noaId);
    await tester.pump();

    final state = container.read(presenceControllerProvider);
    expect(state, isNot(contains(formerMatchId)));
    expect(state, contains(noaId));

    await tester.pump(const Duration(seconds: 120));
    final requestedUserIds = apiClient.presenceRequests.map((r) => r.$1);
    expect(requestedUserIds.where((id) => id == formerMatchId), hasLength(1));
    expect(requestedUserIds.where((id) => id == noaId), hasLength(3));

    container.dispose();
  });

  for (final status in [401, 404]) {
    testWidgets('a $status hides the user and pauses polling for a minute', (
      tester,
    ) async {
      apiClient.presence = const UserPresence(
        status: PresenceStatus.online,
        typing: false,
      );
      final container = await startPresence(tester);
      final presence = container.read(presenceControllerProvider.notifier);
      presence.watch(noaId, conversationId: conversationId);
      await tester.pump();
      expect(container.read(presenceControllerProvider), contains(noaId));

      apiClient.presenceError = ApiError(
        message: 'Refused',
        statusCode: status,
      );
      await tester.pump(const Duration(seconds: 5));
      expect(container.read(presenceControllerProvider), isEmpty);
      final requestsAfterFailure = apiClient.presenceRequests.length;

      await tester.pump(const Duration(seconds: 55));
      expect(apiClient.presenceRequests, hasLength(requestsAfterFailure));

      apiClient.presenceError = null;
      await tester.pump(const Duration(seconds: 10));
      expect(
        apiClient.presenceRequests.length,
        greaterThan(requestsAfterFailure),
      );
      expect(container.read(presenceControllerProvider), contains(noaId));

      container.dispose();
    });
  }

  testWidgets('a 429 hides everyone and backs off longer each time', (
    tester,
  ) async {
    apiClient.presenceError = const ApiError(
      message: 'Slow down',
      statusCode: 429,
    );
    final container = await startPresence(tester);
    final presence = container.read(presenceControllerProvider.notifier);
    presence.watch(noaId, conversationId: conversationId);
    await tester.pump();
    expect(apiClient.presenceRequests, hasLength(1));
    expect(container.read(presenceControllerProvider), isEmpty);

    // First back-off: 30 s without a request, then one more attempt.
    await tester.pump(const Duration(seconds: 29));
    expect(apiClient.presenceRequests, hasLength(1));
    await tester.pump(const Duration(seconds: 6));
    expect(apiClient.presenceRequests, hasLength(2));

    // Second back-off is twice as long.
    await tester.pump(const Duration(seconds: 55));
    expect(apiClient.presenceRequests, hasLength(2));
    await tester.pump(const Duration(seconds: 10));
    expect(apiClient.presenceRequests, hasLength(3));

    container.dispose();
  });
}

class _FakePresenceApiClient extends ApiClient {
  _FakePresenceApiClient() : super(dio: Dio());

  final List<String> heartbeatUserIds = [];
  final List<(String, String)> typingRequests = [];
  final List<(String, String?)> presenceRequests = [];
  ApiError? heartbeatError;
  ApiError? presenceError;
  final Set<String> forbiddenUserIds = {};
  UserPresence presence = const UserPresence(
    status: PresenceStatus.offline,
    typing: false,
  );

  @override
  Future<void> sendHeartbeat({required String userId}) async {
    heartbeatUserIds.add(userId);
    if (heartbeatError case final error?) {
      heartbeatError = null;
      throw error;
    }
  }

  @override
  Future<void> sendTyping({
    required String userId,
    required String conversationId,
  }) async {
    typingRequests.add((userId, conversationId));
  }

  @override
  Future<UserPresence> getPresence({
    required String userId,
    String? conversationId,
  }) async {
    presenceRequests.add((userId, conversationId));
    if (forbiddenUserIds.contains(userId)) {
      throw const ApiError(message: 'Forbidden', statusCode: 403);
    }
    if (presenceError case final error?) {
      throw error;
    }
    return presence;
  }
}
