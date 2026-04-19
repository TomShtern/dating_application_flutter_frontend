import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/api/api_endpoints.dart';

void main() {
  test(
    'getHealth requests the health endpoint and parses the payload',
    () async {
      final recorder = _RequestRecorder();
      final client = ApiClient(
        dio: _buildTestDio(
          recorder: recorder,
          responder: (options) => {
            'status': 'ok',
            'timestamp': DateTime.utc(2026, 4, 19, 9).millisecondsSinceEpoch,
          },
        ),
      );

      final health = await client.getHealth();

      expect(health.status, 'ok');
      expect(health.isHealthy, isTrue);
      expect(recorder.requests.single.method, 'GET');
      expect(recorder.requests.single.path, ApiEndpoints.health);
    },
  );

  test(
    'getConversations sends the selected user and pagination data',
    () async {
      final recorder = _RequestRecorder();
      const userId = '11111111-1111-1111-1111-111111111111';
      final client = ApiClient(
        dio: _buildTestDio(
          recorder: recorder,
          responder: (options) => [
            {
              'id': 'conversation-1',
              'otherUserId': '22222222-2222-2222-2222-222222222222',
              'otherUserName': 'Noa',
              'messageCount': 3,
              'lastMessageAt': '2026-04-19T09:00:00Z',
            },
          ],
        ),
      );

      final conversations = await client.getConversations(
        userId: userId,
        limit: 20,
        offset: 5,
      );

      final request = recorder.requests.single;
      expect(conversations.single.otherUserName, 'Noa');
      expect(request.method, 'GET');
      expect(request.path, ApiEndpoints.conversations(userId));
      expect(request.queryParameters, {'limit': 20, 'offset': 5});
      expect(request.extra['userId'], userId);
    },
  );

  test(
    'reportUser uses the user-scoped route and extracts the response message',
    () async {
      final recorder = _RequestRecorder();
      const userId = '11111111-1111-1111-1111-111111111111';
      const targetId = '22222222-2222-2222-2222-222222222222';
      final client = ApiClient(
        dio: _buildTestDio(
          recorder: recorder,
          responder: (options) => {'message': 'User reported.'},
        ),
      );

      final message = await client.reportUser(
        userId: userId,
        targetId: targetId,
      );

      final request = recorder.requests.single;
      expect(message, 'User reported.');
      expect(request.method, 'POST');
      expect(request.path, ApiEndpoints.reportUser(userId, targetId));
      expect(request.extra['userId'], userId);
    },
  );

  test(
    'undoLastSwipe posts to the undo route and parses the payload',
    () async {
      final recorder = _RequestRecorder();
      const userId = '11111111-1111-1111-1111-111111111111';
      final client = ApiClient(
        dio: _buildTestDio(
          recorder: recorder,
          responder: (options) => {
            'success': true,
            'message': 'Last swipe undone',
            'matchDeleted': true,
          },
        ),
      );

      final result = await client.undoLastSwipe(userId: userId);

      final request = recorder.requests.single;
      expect(result.success, isTrue);
      expect(result.message, 'Last swipe undone');
      expect(result.matchDeleted, isTrue);
      expect(request.method, 'POST');
      expect(request.path, ApiEndpoints.undo(userId));
      expect(request.extra['userId'], userId);
    },
  );

  test(
    'getStats parses a read-only stats payload into labeled items',
    () async {
      final recorder = _RequestRecorder();
      const userId = '11111111-1111-1111-1111-111111111111';
      final client = ApiClient(
        dio: _buildTestDio(
          recorder: recorder,
          responder: (options) => {
            'likesSent': 12,
            'matches': 4,
            'engagement': {'replyRate': 0.75},
          },
        ),
      );

      final stats = await client.getStats(userId: userId);

      expect(stats.items.any((item) => item.label == 'Likes Sent'), isTrue);
      expect(
        stats.items.any(
          (item) =>
              item.label == 'Engagement Reply Rate' && item.value == '0.75',
        ),
        isTrue,
      );
      expect(recorder.requests.single.path, ApiEndpoints.stats(userId));
    },
  );

  test('getAchievements accepts wrapped achievement lists', () async {
    final recorder = _RequestRecorder();
    const userId = '11111111-1111-1111-1111-111111111111';
    final client = ApiClient(
      dio: _buildTestDio(
        recorder: recorder,
        responder: (options) => {
          'achievements': [
            {
              'title': 'Early Bird',
              'description': 'Opened the app before 8am',
              'unlocked': true,
            },
          ],
        },
      ),
    );

    final achievements = await client.getAchievements(userId: userId);

    expect(achievements.single.title, 'Early Bird');
    expect(achievements.single.statusLabel, 'Unlocked');
    expect(recorder.requests.single.path, ApiEndpoints.achievements(userId));
  });
}

Dio _buildTestDio({
  required _RequestRecorder recorder,
  required dynamic Function(RequestOptions options) responder,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        recorder.requests.add(
          _RecordedRequest(
            method: options.method,
            path: options.path,
            queryParameters: Map<String, dynamic>.from(options.queryParameters),
            data: options.data,
            extra: Map<String, dynamic>.from(options.extra),
          ),
        );

        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            data: responder(options),
            statusCode: 200,
          ),
        );
      },
    ),
  );

  return dio;
}

class _RequestRecorder {
  final List<_RecordedRequest> requests = <_RecordedRequest>[];
}

class _RecordedRequest {
  const _RecordedRequest({
    required this.method,
    required this.path,
    required this.queryParameters,
    required this.data,
    required this.extra,
  });

  final String method;
  final String path;
  final Map<String, dynamic> queryParameters;
  final dynamic data;
  final Map<String, dynamic> extra;
}
