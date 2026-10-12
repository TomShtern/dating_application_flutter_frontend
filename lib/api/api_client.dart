import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_config.dart';
import '../models/blocked_user_summary.dart';
import '../models/browse_response.dart';
import '../models/conversation_summary.dart';
import '../models/daily_status.dart';
import '../models/health_status.dart';
import '../models/like_result.dart';
import '../models/location_metadata.dart';
import '../models/match_quality.dart';
import '../models/message_dto.dart';
import '../models/matches_response.dart';
import '../models/achievement_summary.dart';
import '../models/notification_item.dart';
import '../models/pending_liker.dart';
import '../models/photo_dto.dart';
import '../models/profile_edit_snapshot.dart';
import '../models/profile_presentation_context.dart';
import '../models/profile_update_request.dart';
import '../models/profile_update_response.dart';
import '../models/report_result.dart';
import '../models/standout.dart';
import '../models/undo_swipe_result.dart';
import '../models/user_stats.dart';
import '../models/user_detail.dart';
import '../models/user_presence.dart';
import '../models/user_summary.dart';
import '../models/verification_result.dart';
import '../models/auth_user.dart';
import 'api_endpoints.dart';
import 'api_error.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/clerk_auth_provider.dart';
import 'clerk_auth_interceptor.dart';
import 'report_reason.dart';

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
    ClerkAuthInterceptor(
      dio: dio,
      sharedSecret: config.lanSharedSecret,
      // Collaborators are read lazily so building the client never builds the
      // auth controller (which itself needs the client).
      getToken: () async {
        try {
          final token = await ref.read(clerkAuthStateProvider).sessionToken();
          return token.jwt;
        } catch (_) {
          // Signed out, or Clerk could not produce a token.
          return null;
        }
      },
      provision: () => ref.read(authControllerProvider.notifier).provision(),
      onSessionInvalid: () =>
          ref.read(authControllerProvider.notifier).expireSession(),
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

  Future<UserDetail> getUserDetail({required String userId}) async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.userDetail(userId));

      return UserDetail.fromJson(
        _expectMap(response.data, context: 'loading a user profile'),
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<ProfileUpdateResponse> updateProfile({
    required String userId,
    required ProfileUpdateRequest request,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        ApiEndpoints.updateProfile(userId),
        data: request.toJson(),
      );

      return ProfileUpdateResponse.fromJson(
        _expectMap(response.data, context: 'updating profile'),
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<ProfileEditSnapshot> getProfileEditSnapshot({
    required String userId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.profileEditSnapshot(userId),
      );

      return ProfileEditSnapshot.fromJson(
        _expectMap(response.data, context: 'loading profile edit values'),
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<ProfilePresentationContext> getProfilePresentationContext({
    required String viewerUserId,
    required String targetUserId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.profilePresentationContext(viewerUserId, targetUserId),
      );

      return ProfilePresentationContext.fromJson(
        _expectMap(response.data, context: 'loading presentation context'),
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
      ).withProfileLocationInput(
        countryCode: countryCode,
        cityName: cityName,
        zipCode: zipCode,
        allowApproximate: allowApproximate,
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
      );

      return _extractMessage(response.data, fallback: 'User unblocked.');
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<ReportResult> reportUser({
    required String userId,
    required String targetId,
    required ReportUserRequest report,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.reportUser(userId, targetId),
        data: report.toJson(),
      );

      return ReportResult.fromJson(
        _expectMap(response.data, context: 'reporting a user'),
      );
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
      );

      return _extractMessage(response.data, fallback: 'Match removed.');
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<String> gracefulExit({
    required String userId,
    required String targetId,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.gracefulExit(userId, targetId),
      );

      return _extractMessage(
        response.data,
        fallback: 'Connection ended gracefully.',
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<String> archiveMatch({
    required String userId,
    required String matchId,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.archiveMatch(userId, matchId),
      );

      return _extractMessage(response.data, fallback: 'Match archived.');
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<BrowseResponse> getBrowse({required String userId}) async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.browse(userId));

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
      );

      return LikeResult.fromJson(
        _expectMap(response.data, context: 'liking a candidate'),
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<LikeResult> superLikeUser({
    required String userId,
    required String targetId,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.superLike(userId, targetId),
      );

      return LikeResult.fromJson(
        _expectMap(response.data, context: 'super-liking a candidate'),
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
      );
      return _extractMessage(response.data, fallback: 'Passed');
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<UndoSwipeResult> undoLastSwipe({required String userId}) async {
    try {
      final response = await _dio.post<dynamic>(ApiEndpoints.undo(userId));

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
      );

      return MatchesResponse.fromJson(
        _expectMap(response.data, context: 'loading matches'),
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<MatchQuality> getMatchQuality({
    required String userId,
    required String matchId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.matchQuality(userId, matchId),
      );

      return MatchQuality.fromJson(
        _expectMap(response.data, context: 'loading match quality'),
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

  /// Hides the conversation for [userId] only. No messages are removed, and a
  /// new message from either side brings it back.
  Future<void> deleteConversation({
    required String userId,
    required String conversationId,
  }) async {
    try {
      await _dio.delete<dynamic>(
        ApiEndpoints.conversation(userId, conversationId),
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<void> archiveConversation({
    required String userId,
    required String conversationId,
  }) async {
    try {
      await _dio.post<dynamic>(
        ApiEndpoints.archiveConversation(userId, conversationId),
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<void> unarchiveConversation({
    required String userId,
    required String conversationId,
  }) async {
    try {
      await _dio.post<dynamic>(
        ApiEndpoints.unarchiveConversation(userId, conversationId),
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<DailyStatus> getDailyStatus({required String userId}) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.dailyStatus(userId),
      );

      return DailyStatus.fromJson(
        _expectMap(response.data, context: 'loading today\'s swipe allowance'),
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  /// Returns the caller's profile with its new `state` (`PAUSED`).
  Future<UserDetail> pauseProfile({required String userId}) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.pauseProfile(userId),
      );

      return UserDetail.fromJson(
        _expectMap(response.data, context: 'pausing your profile'),
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  /// Returns the caller's profile with its new `state` (`ACTIVE`).
  Future<UserDetail> resumeProfile({required String userId}) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.resumeProfile(userId),
      );

      return UserDetail.fromJson(
        _expectMap(response.data, context: 'resuming your profile'),
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<UserStats> getStats({required String userId}) async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.stats(userId));

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
      final response = await _dio.get<dynamic>(ApiEndpoints.standouts(userId));

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
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<int> markAllNotificationsRead({required String userId}) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.markAllNotificationsRead(userId),
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
      );

      return MessageDto.fromJson(
        _expectMap(response.data, context: 'sending a message'),
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    try {
      await _dio.delete<dynamic>(
        ApiEndpoints.message(conversationId, messageId),
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  // ── Presence ────────────────────────────────────────────────────────────
  //
  // Presence is decoration. These calls are marked passive so a failure is
  // never retried and never signs the user out; callers swallow the error.

  static final Options _passive = Options(
    extra: {ClerkAuthInterceptor.passiveExtra: true},
  );

  Future<void> sendHeartbeat({required String userId}) async {
    try {
      await _dio.post<dynamic>(
        ApiEndpoints.heartbeat(userId),
        options: _passive,
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  /// [conversationId] must be the id the conversations API returned.
  Future<void> sendTyping({
    required String userId,
    required String conversationId,
  }) async {
    try {
      await _dio.post<dynamic>(
        ApiEndpoints.typing(userId),
        data: {'conversationId': conversationId},
        options: _passive,
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  /// Presence of another user. `typing` is only meaningful when
  /// [conversationId] is given.
  Future<UserPresence> getPresence({
    required String userId,
    String? conversationId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.presence(userId),
        queryParameters: {'conversationId': ?conversationId},
        options: _passive,
      );

      return UserPresence.fromJson(
        _expectMap(response.data, context: 'loading presence'),
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  // ── Auth ────────────────────────────────────────────────────────────────

  /// `POST /api/auth/session`, no body. 201 on first call (a local profile was
  /// created), 200 afterwards; both are safe to repeat. The Bearer token is
  /// attached by the interceptor.
  ///
  /// This is the first call after the app starts or a sign-in, so it is the
  /// one that meets a hosted backend that went to sleep; waking takes longer
  /// than the default timeout.
  Future<AuthUser> provisionSession() async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.authSession,
        options: Options(receiveTimeout: const Duration(seconds: 90)),
      );
      return AuthUser.fromJson(
        _expectMap(response.data, context: 'provisioning your profile'),
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    } on FormatException catch (error) {
      throw ApiError(message: error.message);
    }
  }

  // ── Photos ──────────────────────────────────────────────────────────────

  /// Downloads an image. A URL on this backend goes out with the shared
  /// secret and a fresh Clerk token, like any API call; a URL on another host
  /// (legacy external photos) goes out with no auth headers at all.
  ///
  /// Failures are never retried and never sign the user out: the caller shows
  /// its fallback instead.
  Future<Uint8List> getPhotoBytes(String url) async {
    try {
      final response = await _dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          extra: {
            if (_isBackendUrl(url))
              ClerkAuthInterceptor.passiveExtra: true
            else
              ClerkAuthInterceptor.skipAuthExtra: true,
          },
        ),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw const ApiError(message: 'The image was empty.');
      }
      return bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  bool _isBackendUrl(String url) {
    final target = Uri.tryParse(url);
    final base = Uri.tryParse(_dio.options.baseUrl);
    if (target == null || base == null) {
      return false;
    }
    if (!target.hasScheme) {
      // Path-relative: Dio resolves it against the backend base URL.
      // Protocol-relative (`//host/...`) names another host.
      return !target.hasAuthority;
    }
    return target.scheme == base.scheme &&
        target.host == base.host &&
        target.port == base.port;
  }

  Future<PhotoListResponse> listUserPhotos({required String userId}) async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.userPhotos(userId));

      return PhotoListResponse.fromJson(
        _expectMap(response.data, context: 'listing photos'),
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  /// Uploads a photo. Caller supplies a `MultipartFile` (built from
  /// bytes or a file path) so the device-specific image picker can be
  /// wired in separately without touching the API layer.
  ///
  /// [onSendProgress] is an optional callback that receives (sent, total)
  /// bytes during upload, used to show progress in the UI.
  Future<PhotoUploadResponse> uploadPhoto({
    required String userId,
    required MultipartFile photo,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.userPhotos(userId),
        data: FormData.fromMap({'photo': photo}),
        onSendProgress: onSendProgress,
      );

      return PhotoUploadResponse.fromJson(
        _expectMap(response.data, context: 'uploading a photo'),
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<void> deleteUser({required String userId}) async {
    try {
      await _dio.delete<dynamic>(ApiEndpoints.deleteUser(userId));
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<PhotoListResponse> deletePhoto({
    required String userId,
    required String photoId,
  }) async {
    try {
      final response = await _dio.delete<dynamic>(
        ApiEndpoints.userPhoto(userId, photoId),
      );

      return PhotoListResponse.fromJson(
        _expectMap(response.data, context: 'deleting a photo'),
      );
    } on DioException catch (error) {
      throw _toApiError(error);
    }
  }

  Future<PhotoListResponse> reorderPhotos({
    required String userId,
    required List<String> photoIds,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        ApiEndpoints.userPhotosOrder(userId),
        data: {'photoIds': photoIds},
      );

      return PhotoListResponse.fromJson(
        _expectMap(response.data, context: 'reordering photos'),
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
