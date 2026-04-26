import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/api/api_endpoints.dart';
import 'package:flutter_dating_application_1/models/match_quality.dart';
import 'package:flutter_dating_application_1/models/profile_edit_snapshot.dart';
import 'package:flutter_dating_application_1/models/profile_presentation_context.dart';
import 'package:flutter_dating_application_1/models/profile_update_request.dart';

void main() {
  test(
    'getMatchQuality uses the live Stage A route and parses the response',
    () async {
      final recorder = _RequestRecorder();
      const userId = '11111111-1111-1111-1111-111111111111';
      const matchId =
          '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222';
      final client = ApiClient(
        dio: _buildTestDio(
          recorder: recorder,
          responder: (options) => {
            'matchId': matchId,
            'perspectiveUserId': userId,
            'otherUserId': '22222222-2222-2222-2222-222222222222',
            'compatibilityScore': 85,
            'compatibilityLabel': 'Great Match',
            'starDisplay': '⭐⭐⭐⭐',
            'paceSyncLevel': 'Good Sync',
            'distanceKm': 12.4,
            'ageDifference': 2,
            'highlights': [
              'Lives nearby (12.4 km away)',
              'You both enjoy Hiking',
              'Great communication sync',
            ],
          },
        ),
      );

      final matchQuality = await client.getMatchQuality(
        userId: userId,
        matchId: matchId,
      );

      expect(matchQuality, isA<MatchQuality>());
      expect(matchQuality.compatibilityScore, 85);
      expect(matchQuality.highlights, hasLength(3));
      expect(recorder.requests.single.method, 'GET');
      expect(
        recorder.requests.single.path,
        ApiEndpoints.matchQuality(userId, matchId),
      );
      expect(recorder.requests.single.extra['userId'], userId);
    },
  );

  test(
    'getProfilePresentationContext uses the Stage B route and parses response',
    () async {
      final recorder = _RequestRecorder();
      const viewerId = '11111111-1111-1111-1111-111111111111';
      const targetId = '33333333-3333-3333-3333-333333333333';
      final client = ApiClient(
        dio: _buildTestDio(
          recorder: recorder,
          responder: (options) => {
            'viewerUserId': viewerId,
            'targetUserId': targetId,
            'summary': 'Shown because this profile is nearby.',
            'reasonTags': ['nearby', 'shared_interests'],
            'details': ['This profile is within your preferred distance.'],
            'generatedAt': '2026-05-08T10:15:00Z',
          },
        ),
      );

      final context = await client.getProfilePresentationContext(
        viewerUserId: viewerId,
        targetUserId: targetId,
      );

      expect(context, isA<ProfilePresentationContext>());
      expect(context.targetUserId, targetId);
      expect(context.reasonTags, ['nearby', 'shared_interests']);
      expect(
        recorder.requests.single.path,
        ApiEndpoints.profilePresentationContext(viewerId, targetId),
      );
      expect(recorder.requests.single.extra['userId'], viewerId);
    },
  );

  test(
    'getProfileEditSnapshot uses the Stage B route and parses response',
    () async {
      final recorder = _RequestRecorder();
      const userId = '11111111-1111-1111-1111-111111111111';
      final client = ApiClient(
        dio: _buildTestDio(
          recorder: recorder,
          responder: (options) => {
            'userId': userId,
            'editable': {
              'bio': 'Runner, coffee person, and weekend hiker.',
              'interestedIn': ['MALE'],
              'interests': ['COFFEE'],
              'dealbreakers': {
                'acceptableSmoking': ['NEVER'],
                'acceptableDrinking': [],
                'acceptableKidsStance': ['OPEN'],
                'acceptableLookingFor': ['LONG_TERM'],
                'acceptableEducation': ['BACHELORS'],
                'maxAgeDifference': 6,
              },
            },
            'readOnly': {
              'name': 'Dana',
              'state': 'ACTIVE',
              'photoUrls': ['/photos/dana-1.jpg'],
              'verified': true,
              'verificationMethod': 'EMAIL',
              'verifiedAt': '2026-04-24T08:30:00Z',
            },
          },
        ),
      );

      final snapshot = await client.getProfileEditSnapshot(userId: userId);

      expect(snapshot, isA<ProfileEditSnapshot>());
      expect(snapshot.userId, userId);
      expect(snapshot.editable.interests, ['COFFEE']);
      expect(snapshot.readOnly.photoUrls, ['/photos/dana-1.jpg']);
      expect(
        recorder.requests.single.path,
        ApiEndpoints.profileEditSnapshot(userId),
      );
      expect(recorder.requests.single.extra['userId'], userId);
    },
  );

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

  test(
    'getAchievements accepts backend achievement snapshot payloads',
    () async {
      final recorder = _RequestRecorder();
      const userId = '11111111-1111-1111-1111-111111111111';
      final client = ApiClient(
        dio: _buildTestDio(
          recorder: recorder,
          responder: (options) => {
            'unlocked': [
              {
                'id': 'achievement-1',
                'achievementName': 'Conversation Starter',
                'description': 'Sent the first message',
              },
            ],
            'newlyUnlocked': [
              {
                'id': 'achievement-1',
                'achievementName': 'Conversation Starter',
                'description': 'Sent the first message',
              },
            ],
            'unlockedCount': 1,
            'newlyUnlockedCount': 1,
          },
        ),
      );

      final achievements = await client.getAchievements(userId: userId);

      expect(achievements, hasLength(1));
      expect(achievements.single.title, 'Conversation Starter');
      expect(achievements.single.subtitle, 'Sent the first message');
      expect(achievements.single.statusLabel, 'Unlocked');
      expect(recorder.requests.single.path, ApiEndpoints.achievements(userId));
    },
  );

  test(
    'getAchievements merges unlocked and newly unlocked achievements without duplicates',
    () async {
      final recorder = _RequestRecorder();
      const userId = '11111111-1111-1111-1111-111111111111';
      final client = ApiClient(
        dio: _buildTestDio(
          recorder: recorder,
          responder: (options) => {
            'unlocked': [
              {
                'id': 'achievement-1',
                'achievementName': 'Conversation Starter',
                'description': 'Sent the first message',
              },
            ],
            'newlyUnlocked': [
              {
                'id': 'achievement-1',
                'achievementName': 'Conversation Starter',
                'description': 'Sent the first message',
              },
              {
                'id': 'achievement-2',
                'achievementName': 'First Match',
                'description': 'Matched with someone new',
              },
            ],
          },
        ),
      );

      final achievements = await client.getAchievements(userId: userId);

      expect(achievements, hasLength(2));
      expect(achievements.map((achievement) => achievement.title).toList(), [
        'Conversation Starter',
        'First Match',
      ]);
    },
  );

  test('getBlockedUsers unwraps the blockedUsers payload', () async {
    final recorder = _RequestRecorder();
    const userId = '11111111-1111-1111-1111-111111111111';
    final client = ApiClient(
      dio: _buildTestDio(
        recorder: recorder,
        responder: (options) => {
          'blockedUsers': [
            {
              'userId': '22222222-2222-2222-2222-222222222222',
              'name': 'Noa',
              'statusLabel': 'Blocked profile',
            },
          ],
        },
      ),
    );

    final blockedUsers = await client.getBlockedUsers(userId: userId);

    expect(blockedUsers.single.name, 'Noa');
    expect(recorder.requests.single.path, ApiEndpoints.blockedUsers(userId));
    expect(recorder.requests.single.extra['userId'], userId);
  });

  test(
    'getNotifications includes unreadOnly and parses the list payload',
    () async {
      final recorder = _RequestRecorder();
      const userId = '11111111-1111-1111-1111-111111111111';
      final client = ApiClient(
        dio: _buildTestDio(
          recorder: recorder,
          responder: (options) => [
            {
              'id': 'notification-1',
              'type': 'MATCH',
              'title': 'New match',
              'message': 'You matched with Dana',
              'createdAt': '2026-04-19T09:00:00Z',
              'isRead': false,
              'data': {'matchId': 'match-1'},
            },
          ],
        ),
      );

      final notifications = await client.getNotifications(
        userId: userId,
        unreadOnly: true,
      );

      expect(notifications.single.title, 'New match');
      expect(notifications.single.data['matchId'], 'match-1');
      expect(recorder.requests.single.path, ApiEndpoints.notifications(userId));
      expect(recorder.requests.single.queryParameters, {'unreadOnly': true});
    },
  );

  test('markAllNotificationsRead posts to the bulk-read route', () async {
    final recorder = _RequestRecorder();
    const userId = '11111111-1111-1111-1111-111111111111';
    final client = ApiClient(
      dio: _buildTestDio(
        recorder: recorder,
        responder: (options) => {'updatedCount': 3},
      ),
    );

    final updatedCount = await client.markAllNotificationsRead(userId: userId);

    expect(updatedCount, 3);
    expect(recorder.requests.single.method, 'POST');
    expect(
      recorder.requests.single.path,
      ApiEndpoints.markAllNotificationsRead(userId),
    );
  });

  test('getPendingLikers unwraps the pending likers response', () async {
    final recorder = _RequestRecorder();
    const userId = '11111111-1111-1111-1111-111111111111';
    final client = ApiClient(
      dio: _buildTestDio(
        recorder: recorder,
        responder: (options) => {
          'pendingLikers': [
            {
              'userId': '22222222-2222-2222-2222-222222222222',
              'name': 'Maya',
              'age': 31,
              'likedAt': '2026-04-19T10:15:00Z',
            },
          ],
        },
      ),
    );

    final likers = await client.getPendingLikers(userId: userId);

    expect(likers.single.name, 'Maya');
    expect(recorder.requests.single.path, ApiEndpoints.pendingLikers(userId));
  });

  test('getStandouts parses standout metadata and items', () async {
    final recorder = _RequestRecorder();
    const userId = '11111111-1111-1111-1111-111111111111';
    final client = ApiClient(
      dio: _buildTestDio(
        recorder: recorder,
        responder: (options) => {
          'standouts': [
            {
              'id': 'standout-1',
              'standoutUserId': '22222222-2222-2222-2222-222222222222',
              'standoutUserName': 'Dana',
              'standoutUserAge': 27,
              'rank': 1,
              'score': 97,
              'reason': 'High compatibility',
              'createdAt': '2026-04-19T09:00:00Z',
            },
          ],
          'totalCandidates': 4,
          'fromCache': true,
          'message': 'Fresh standouts ready',
        },
      ),
    );

    final snapshot = await client.getStandouts(userId: userId);

    expect(snapshot.standouts.single.standoutUserName, 'Dana');
    expect(snapshot.totalCandidates, 4);
    expect(snapshot.fromCache, isTrue);
    expect(recorder.requests.single.path, ApiEndpoints.standouts(userId));
  });

  test('verification flow posts the expected request bodies', () async {
    final recorder = _RequestRecorder();
    const userId = '11111111-1111-1111-1111-111111111111';
    var callCount = 0;
    final client = ApiClient(
      dio: _buildTestDio(
        recorder: recorder,
        responder: (options) {
          callCount++;
          if (callCount == 1) {
            return {
              'userId': userId,
              'method': 'EMAIL',
              'contact': 'test@example.com',
              'devVerificationCode': '123456',
            };
          }

          return {'verified': true, 'verifiedAt': '2026-04-19T11:00:00Z'};
        },
      ),
    );

    final startResult = await client.startVerification(
      userId: userId,
      method: 'EMAIL',
      contact: 'test@example.com',
    );
    final confirmResult = await client.confirmVerification(
      userId: userId,
      verificationCode: '123456',
    );

    expect(startResult.devVerificationCode, '123456');
    expect(confirmResult.verified, isTrue);
    expect(recorder.requests[0].path, ApiEndpoints.startVerification(userId));
    expect(recorder.requests[0].data, {
      'method': 'EMAIL',
      'contact': 'test@example.com',
    });
    expect(recorder.requests[1].path, ApiEndpoints.confirmVerification(userId));
    expect(recorder.requests[1].data, {'verificationCode': '123456'});
  });

  test(
    'resolveLocation and updateProfile send the new location payload shape',
    () async {
      final recorder = _RequestRecorder();
      const userId = '11111111-1111-1111-1111-111111111111';
      var callCount = 0;
      final client = ApiClient(
        dio: _buildTestDio(
          recorder: recorder,
          responder: (options) {
            callCount++;
            if (callCount == 1) {
              return {
                'label': 'Tel Aviv, IL',
                'latitude': 32.0853,
                'longitude': 34.7818,
                'precision': 'CITY',
                'approximate': true,
                'message': 'Resolved location',
              };
            }

            return {'ok': true};
          },
        ),
      );

      final resolved = await client.resolveLocation(
        countryCode: 'IL',
        cityName: 'Tel Aviv',
        zipCode: '61000',
        allowApproximate: true,
      );
      await client.updateProfile(
        userId: userId,
        request: const ProfileUpdateRequest(
          location: ProfileLocationRequest(
            countryCode: 'IL',
            cityName: 'Tel Aviv',
            zipCode: '61000',
            allowApproximate: true,
          ),
        ),
      );

      expect(resolved.label, 'Tel Aviv, IL');
      expect(recorder.requests[0].path, ApiEndpoints.resolveLocation);
      expect(recorder.requests[0].data, {
        'countryCode': 'IL',
        'cityName': 'Tel Aviv',
        'zipCode': '61000',
        'allowApproximate': true,
      });
      expect(recorder.requests[1].path, ApiEndpoints.updateProfile(userId));
      expect(recorder.requests[1].data, {
        'location': {
          'countryCode': 'IL',
          'cityName': 'Tel Aviv',
          'zipCode': '61000',
          'allowApproximate': true,
        },
      });
    },
  );
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
