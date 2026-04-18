import 'package:dio/dio.dart';

class ApiError implements Exception {
  const ApiError({required this.message, this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  factory ApiError.fromDioException(DioException exception, {String? baseUrl}) {
    final response = exception.response;
    final payload = response?.data;

    if (payload is Map) {
      return ApiError(
        message:
            payload['message'] as String? ??
            exception.message ??
            'Request failed.',
        code: payload['code'] as String?,
        statusCode: response?.statusCode,
      );
    }

    return ApiError(
      message: _messageFromException(exception, baseUrl: baseUrl),
      statusCode: response?.statusCode,
    );
  }

  static String _messageFromException(
    DioException exception, {
    String? baseUrl,
  }) {
    if (exception.type == DioExceptionType.connectionError) {
      return _connectionErrorMessage(baseUrl: baseUrl);
    }

    return exception.message ?? 'Request failed.';
  }

  static String _connectionErrorMessage({String? baseUrl}) {
    final normalizedBaseUrl = baseUrl?.trim();
    final targetLabel = normalizedBaseUrl == null || normalizedBaseUrl.isEmpty
        ? 'the configured backend'
        : 'the backend at $normalizedBaseUrl';

    if (_isLoopbackBaseUrl(normalizedBaseUrl)) {
      return 'Could not connect to $targetLabel. '
          'If you are using the Android emulator, use http://10.0.2.2:7070 instead. '
          'Also make sure the backend is running on port 7070.';
    }

    if (normalizedBaseUrl?.contains('10.0.2.2') ?? false) {
      return 'Could not connect to $targetLabel. '
          'This Android emulator URL points to your computer, so make sure '
          'the backend is running there on port 7070.';
    }

    return 'Could not connect to $targetLabel. '
        'Make sure the backend is running and reachable on port 7070.';
  }

  static bool _isLoopbackBaseUrl(String? baseUrl) {
    if (baseUrl == null || baseUrl.isEmpty) {
      return false;
    }

    return baseUrl.contains('127.0.0.1') || baseUrl.contains('localhost');
  }

  @override
  String toString() {
    if (code == null && statusCode == null) {
      return message;
    }

    return 'ApiError(code: $code, statusCode: $statusCode, message: $message)';
  }
}
