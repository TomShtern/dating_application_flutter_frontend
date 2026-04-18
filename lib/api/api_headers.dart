import 'api_endpoints.dart';

class ApiHeaders {
  const ApiHeaders._();

  static const String sharedSecretHeader = 'X-DatingApp-Shared-Secret';
  static const String userIdHeader = 'X-User-Id';

  static Map<String, String> build({
    required String path,
    required String sharedSecret,
    String? userId,
  }) {
    final headers = <String, String>{};

    if (path != ApiEndpoints.health) {
      headers[sharedSecretHeader] = sharedSecret;
    }

    if (_isUserScoped(path) && userId != null && userId.isNotEmpty) {
      headers[userIdHeader] = userId;
    }

    return headers;
  }

  static bool _isUserScoped(String path) {
    return path.startsWith('/api/users/') ||
        path.startsWith('/api/conversations/');
  }
}
