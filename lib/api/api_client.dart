import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_config.dart';
import '../models/browse_response.dart';
import '../models/conversation_summary.dart';
import '../models/health_status.dart';
import '../models/like_result.dart';
import '../models/message_dto.dart';
import '../models/matches_response.dart';
import '../models/user_summary.dart';
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
}
