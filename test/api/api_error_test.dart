import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/api/api_error.dart';

void main() {
  test('formats emulator connection errors with the active base url', () {
    final exception = DioException(
      requestOptions: RequestOptions(path: '/api/health'),
      type: DioExceptionType.connectionError,
      error: const SocketException('Connection refused'),
    );

    final apiError = ApiError.fromDioException(
      exception,
      baseUrl: 'http://10.0.2.2:7070',
    );

    expect(
      apiError.message,
      'Could not connect to the backend at http://10.0.2.2:7070. '
      'This Android emulator URL points to your computer, so make sure '
      'the backend is running there on port 7070.',
    );
  });

  test('formats localhost connection errors with an emulator hint', () {
    final exception = DioException(
      requestOptions: RequestOptions(path: '/api/health'),
      type: DioExceptionType.connectionError,
      error: const SocketException('Connection refused'),
    );

    final apiError = ApiError.fromDioException(
      exception,
      baseUrl: 'http://127.0.0.1:7070',
    );

    expect(
      apiError.message,
      'Could not connect to the backend at http://127.0.0.1:7070. '
      'If you are using the Android emulator, use http://10.0.2.2:7070 instead. '
      'Also make sure the backend is running on port 7070.',
    );
  });

  test('keeps structured server errors intact', () {
    final exception = DioException(
      requestOptions: RequestOptions(path: '/api/users'),
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: '/api/users'),
        statusCode: 403,
        data: {'code': 'FORBIDDEN', 'message': 'Forbidden'},
      ),
      type: DioExceptionType.badResponse,
    );

    final apiError = ApiError.fromDioException(
      exception,
      baseUrl: 'http://10.0.2.2:7070',
    );

    expect(apiError.message, 'Forbidden');
    expect(apiError.code, 'FORBIDDEN');
    expect(apiError.statusCode, 403);
  });

  DioException tooManyRequests(
    Map<String, dynamic> body, {
    String? retryAfter,
  }) {
    final options = RequestOptions(path: '/api/users/u-1/like/u-2');
    return DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: options,
        statusCode: 429,
        data: body,
        headers: Headers.fromMap({
          'retry-after': ?retryAfter == null ? null : [retryAfter],
        }),
      ),
    );
  }

  test('a 429 without Retry-After is a daily limit and keeps the backend '
      'message', () {
    final apiError = ApiError.fromDioException(
      tooManyRequests({
        'code': 'RATE_LIMITED',
        'message': 'Daily like limit reached. Resets at 00:00 UTC.',
      }),
    );

    expect(apiError.statusCode, 429);
    expect(apiError.code, 'RATE_LIMITED');
    expect(apiError.isDailyLimit, isTrue);
    expect(apiError.message, 'Daily like limit reached. Resets at 00:00 UTC.');
  });

  test('a 429 with Retry-After is a burst limit, not a daily limit', () {
    final apiError = ApiError.fromDioException(
      tooManyRequests({
        'code': 'TOO_MANY_REQUESTS',
        'message': 'Too many requests.',
      }, retryAfter: '7'),
    );

    expect(apiError.isDailyLimit, isFalse);
    expect(apiError.retryAfterSeconds, 7);
    expect(apiError.message, 'Too many requests. Try again in 7 s.');
  });
}
