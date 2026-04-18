import 'package:dio/dio.dart';

class ApiError implements Exception {
  const ApiError({required this.message, this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  factory ApiError.fromDioException(DioException exception) {
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
      message: exception.message ?? 'Request failed.',
      statusCode: response?.statusCode,
    );
  }

  @override
  String toString() {
    if (code == null && statusCode == null) {
      return message;
    }

    return 'ApiError(code: $code, statusCode: $statusCode, message: $message)';
  }
}
