import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_config.dart';
import '../models/blocked_user_summary.dart';
import '../models/browse_response.dart';
import '../models/conversation_summary.dart';
import '../models/health_status.dart';
import '../models/like_result.dart';
import '../models/location_metadata.dart';
import '../models/message_dto.dart';
import '../models/matches_response.dart';
import '../models/achievement_summary.dart';
import '../models/notification_item.dart';
import '../models/pending_liker.dart';
import '../models/profile_update_request.dart';
import '../models/standout.dart';
import '../models/undo_swipe_result.dart';
import '../models/user_stats.dart';
import '../models/user_detail.dart';
import '../models/user_summary.dart';
import '../models/verification_result.dart';
import 'api_endpoints.dart';
import 'api_error.dart';
import 'api_headers.dart';

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.receiveTimeout,
      sendTimeout: config.sendTimeout,
      responseType: ResponseType.json,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final userId = options.extra['userId'] as String?;
        options.headers.addAll(
          ApiHeaders.build(
            path: options.path,
            sharedSecret: config.lanSharedSecret,
            userId: userId,
          ),
        );

        handler.next(options);
      },
    ),
  );

  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);

  return ApiClient(dio: dio);
});

class ApiClient {
  ApiClient({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<HealthStatus> getHealth() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.health);
      return HealthStatus.fromJson(
        _expectMap(response.data, context: 'loading backend health'),
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<List<UserSummary>> getUsers() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.users);

      final payload = _expectList(response.data, context: 'loading users');

      return payload
          .map(
            (item) =>
                UserSummary.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<UserDetail> getUserDetail({
    required String userId,
    String? actingUserId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.userDetail(userId),
        options: Options(extra: {'userId': actingUserId ?? userId}),
      );

      return UserDetail.fromJson(
        _expectMap(response.data, context: 'loading a user profile'),
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<void> updateProfile({
    required String userId,
    required ProfileUpdateRequest request,
  }) async {
    try {
      await _dio.put<dynamic>(
        ApiEndpoints.updateProfile(userId),
        data: request.toJson(),
        options: Options(extra: {'userId': userId}),
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<List<LocationCountry>> getLocationCountries() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.locationCountries);
      final payload = _expectList(
        response.data,
        context: 'loading location countries',
      );

      return payload
          .map(
            (item) => LocationCountry.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<List<LocationCity>> getLocationCities({
    String? countryCode,
    String query = '',
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.locationCities,
        queryParameters: {
          if (countryCode != null && countryCode.isNotEmpty)
            'countryCode': countryCode,
          if (query.isNotEmpty) 'query': query,
          'limit': limit,
        },
      );
      final payload = _expectList(
        response.data,
        context: 'loading location cities',
      );

      return payload
          .map(
            (item) =>
                LocationCity.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<ResolvedLocation> resolveLocation({
    required String countryCode,
    required String cityName,
    String? zipCode,
    bool allowApproximate = false,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.resolveLocation,
        data: {
          'countryCode': countryCode,
          'cityName': cityName,
          if (zipCode != null && zipCode.isNotEmpty) 'zipCode': zipCode,
          'allowApproximate': allowApproximate,
        },
      );

      return ResolvedLocation.fromJson(
        _expectMap(response.data, context: 'resolving a location selection'),
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<String> blockUser({
    required String userId,
    required String targetId,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.blockUser(userId, targetId),
        options: Options(extra: {'userId': userId}),
      );

      return _extractMessage(response.data, fallback: 'User blocked.');
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<String> unblockUser({
    required String userId,
    required String targetId,
  }) async {
    try {
      final response = await _dio.delete<dynamic>(
        ApiEndpoints.unblockUser(userId, targetId),
        options: Options(extra: {'userId': userId}),
      );

      return _extractMessage(response.data, fallback: 'User unblocked.');
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<String> reportUser({
    required String userId,
    required String targetId,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.reportUser(userId, targetId),
        options: Options(extra: {'userId': userId}),
      );

      return _extractMessage(response.data, fallback: 'User reported.');
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<String> unmatchUser({
    required String userId,
    required String targetId,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.unmatchUser(userId, targetId),
        options: Options(extra: {'userId': userId}),
      );

      return _extractMessage(response.data, fallback: 'Match removed.');
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<BrowseResponse> getBrowse({required String userId}) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.browse(userId),
        options: Options(extra: {'userId': userId}),
      );

      return BrowseResponse.fromJson(
        _expectMap(response.data, context: 'loading browse candidates'),
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<LikeResult> likeUser({
    required String userId,
    required String targetId,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.like(userId, targetId),
        options: Options(extra: {'userId': userId}),
      );

      return LikeResult.fromJson(
        _expectMap(response.data, context: 'liking a candidate'),
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<String> passUser({
    required String userId,
    required String targetId,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.pass(userId, targetId),
        options: Options(extra: {'userId': userId}),
      );
      final payload = _expectMap(response.data, context: 'passing a candidate');
      return payload['message'] as String? ?? 'Passed';
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<UndoSwipeResult> undoLastSwipe({required String userId}) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.undo(userId),
        options: Options(extra: {'userId': userId}),
      );

      return UndoSwipeResult.fromJson(
        _expectMap(response.data, context: 'undoing the last swipe'),
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<MatchesResponse> getMatches({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.matches(userId),
        queryParameters: {'limit': limit, 'offset': offset},
        options: Options(extra: {'userId': userId}),
      );

      return MatchesResponse.fromJson(
        _expectMap(response.data, context: 'loading matches'),
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<List<ConversationSummary>> getConversations({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.conversations(userId),
        queryParameters: {'limit': limit, 'offset': offset},
        options: Options(extra: {'userId': userId}),
      );

      final payload = _expectList(
        response.data,
        context: 'loading conversations',
      );

      return payload
          .map(
            (item) => ConversationSummary.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<UserStats> getStats({required String userId}) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.stats(userId),
        options: Options(extra: {'userId': userId}),
      );

      return UserStats.fromJson(
        _expectMap(response.data, context: 'loading stats'),
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<List<BlockedUserSummary>> getBlockedUsers({
    required String userId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.blockedUsers(userId),
        options: Options(extra: {'userId': userId}),
      );

      final payload = _extractWrappedList(
        response.data,
        key: 'blockedUsers',
        context: 'loading blocked users',
      );

      return payload.map(BlockedUserSummary.fromJson).toList(growable: false);
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<List<AchievementSummary>> getAchievements({
    required String userId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.achievements(userId),
        options: Options(extra: {'userId': userId}),
      );

      final payload = _extractAchievementItems(
        response.data,
        context: 'loading achievements',
      );

      return payload.map(AchievementSummary.fromJson).toList(growable: false);
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<List<PendingLiker>> getPendingLikers({required String userId}) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.pendingLikers(userId),
        options: Options(extra: {'userId': userId}),
      );

      final payload = _extractWrappedList(
        response.data,
        key: 'pendingLikers',
        context: 'loading people who liked you',
      );

      return payload.map(PendingLiker.fromJson).toList(growable: false);
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<StandoutsSnapshot> getStandouts({required String userId}) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.standouts(userId),
        options: Options(extra: {'userId': userId}),
      );

      return StandoutsSnapshot.fromJson(
        _expectMap(response.data, context: 'loading standouts'),
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<List<NotificationItem>> getNotifications({
    required String userId,
    bool unreadOnly = false,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.notifications(userId),
        queryParameters: {'unreadOnly': unreadOnly},
        options: Options(extra: {'userId': userId}),
      );

      final payload = _expectList(
        response.data,
        context: 'loading notifications',
      );

      return payload
          .map(
            (item) => NotificationItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<void> markNotificationRead({
    required String userId,
    required String notificationId,
  }) async {
    try {
      await _dio.post<dynamic>(
        ApiEndpoints.markNotificationRead(userId, notificationId),
        options: Options(extra: {'userId': userId}),
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<int> markAllNotificationsRead({required String userId}) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.markAllNotificationsRead(userId),
        options: Options(extra: {'userId': userId}),
      );
      final payload = _expectMap(
        response.data,
        context: 'marking all notifications as read',
      );

      return (payload['updatedCount'] as num?)?.toInt() ?? 0;
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<VerificationStartResult> startVerification({
    required String userId,
    required String method,
    required String contact,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.startVerification(userId),
        data: {'method': method, 'contact': contact},
        options: Options(extra: {'userId': userId}),
      );

      return VerificationStartResult.fromJson(
        _expectMap(response.data, context: 'starting verification'),
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<VerificationConfirmationResult> confirmVerification({
    required String userId,
    required String verificationCode,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.confirmVerification(userId),
        data: {'verificationCode': verificationCode},
        options: Options(extra: {'userId': userId}),
      );

      return VerificationConfirmationResult.fromJson(
        _expectMap(response.data, context: 'confirming verification'),
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<List<MessageDto>> getMessages({
    required String conversationId,
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.messages(conversationId),
        queryParameters: {'limit': limit, 'offset': offset},
        options: Options(extra: {'userId': userId}),
      );

      final payload = _expectList(response.data, context: 'loading messages');

      return payload
          .map(
            (item) =>
                MessageDto.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<MessageDto> sendMessage({
    required String conversationId,
    required String userId,
    required String content,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.messages(conversationId),
        data: {'senderId': userId, 'content': content},
        options: Options(extra: {'userId': userId}),
      );

      return MessageDto.fromJson(
        _expectMap(response.data, context: 'sending a message'),
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  ApiError _toApiError(DioException error) {
    return ApiError.fromDioException(error, baseUrl: _dio.options.baseUrl);
  }

  Map<String, dynamic> _expectMap(dynamic payload, {required String context}) {
    if (payload is! Map) {
      throw ApiError(message: 'Unexpected response while $context.');
    }

    return Map<String, dynamic>.from(payload);
  }

  List<dynamic> _expectList(dynamic payload, {required String context}) {
    if (payload is! List) {
      throw ApiError(message: 'Unexpected response while $context.');
    }

    return payload;
  }

  List<Map<String, dynamic>> _extractAchievementItems(
    dynamic payload, {
    required String context,
  }) {
    if (payload is List) {
      return payload
          .map((item) => _expectMap(item, context: context))
          .toList(growable: false);
    }

    if (payload is Map) {
      final map = Map<String, dynamic>.from(payload);
      for (final key in const ['achievements', 'items', 'content', 'results']) {
        final value = map[key];
        if (value != null) {
          return _extractAchievementItems(value, context: context);
        }
      }

      if (map.containsKey('unlocked') ||
          map.containsKey('newlyUnlocked') ||
          map.containsKey('unlockedCount') ||
          map.containsKey('newlyUnlockedCount')) {
        return _combineAchievementSnapshotItems(
          _extractAchievementSnapshotItems(map['unlocked'], context: context),
          _extractAchievementSnapshotItems(
            map['newlyUnlocked'],
            context: context,
          ),
        );
      }
    }

    throw ApiError(message: 'Unexpected response while $context.');
  }

  List<Map<String, dynamic>> _extractWrappedList(
    dynamic payload, {
    required String key,
    required String context,
  }) {
    if (payload is List) {
      return payload
          .map((item) => _expectMap(item, context: context))
          .toList(growable: false);
    }

    if (payload is Map) {
      final map = _expectMap(payload, context: context);
      return _expectList(map[key], context: context)
          .map((item) => _expectMap(item, context: context))
          .toList(growable: false);
    }

    throw ApiError(message: 'Unexpected response while $context.');
  }

  List<Map<String, dynamic>> _extractAchievementSnapshotItems(
    dynamic payload, {
    required String context,
  }) {
    if (payload == null) {
      return const <Map<String, dynamic>>[];
    }

    if (payload is! List) {
      throw ApiError(message: 'Unexpected response while $context.');
    }

    return payload
        .map((item) {
          final map = _expectMap(item, context: context);
          if (map['unlocked'] is bool) {
            return map;
          }

          return <String, dynamic>{...map, 'unlocked': true};
        })
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _combineAchievementSnapshotItems(
    List<Map<String, dynamic>> unlocked,
    List<Map<String, dynamic>> newlyUnlocked,
  ) {
    if (unlocked.isEmpty && newlyUnlocked.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    final seen = <String>{};
    final combined = <Map<String, dynamic>>[];

    for (final item in [...unlocked, ...newlyUnlocked]) {
      final key = _achievementSnapshotItemKey(item);
      if (seen.add(key)) {
        combined.add(item);
      }
    }

    return combined;
  }

  String _achievementSnapshotItemKey(Map<String, dynamic> item) {
    for (final keyName in const [
      'id',
      'achievementId',
      'achievementKey',
      'title',
      'achievementName',
      'name',
    ]) {
      final value = item[keyName];
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) {
          return '$keyName:$trimmed';
        }
      } else if (value != null) {
        return '$keyName:$value';
      }
    }

    final entries =
        item.entries
            .map((entry) => '${entry.key}=${entry.value}')
            .toList(growable: false)
          ..sort();
    return entries.join('|');
  }

  String _extractMessage(dynamic payload, {required String fallback}) {
    if (payload == null) {
      return fallback;
    }

    if (payload is String) {
      final message = payload.trim();
      return message.isEmpty ? fallback : message;
    }

    if (payload is Map) {
      final message = Map<String, dynamic>.from(payload)['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    return fallback;
  }
}
