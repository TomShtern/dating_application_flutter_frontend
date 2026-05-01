import 'api_endpoints.dart';

class ApiHeaders {
  const ApiHeaders._();

  static const String sharedSecretHeader = 'X-DatingApp-Shared-Secret';
  static const String userIdHeader = 'X-User-Id';
  static const String authorizationHeader = 'Authorization';

  static Map<String, String> build({
    required String path,
    required String sharedSecret,
    String? userId,
    String? accessToken,
  }) {
    final headers = <String, String>{};

    if (path != ApiEndpoints.health) {
      headers[sharedSecretHeader] = sharedSecret;
    }

    if (_isUserScoped(path) && userId != null && userId.isNotEmpty) {
      headers[userIdHeader] = userId;
    }

    if (_acceptsBearer(path) &&
        accessToken != null &&
        accessToken.isNotEmpty) {
      headers[authorizationHeader] = 'Bearer $accessToken';
    }

    return headers;
  }

  static bool _isUserScoped(String path) {
    return path.startsWith('/api/users/') ||
        path.startsWith('/api/conversations/');
  }

  /// Bearer token is attached to every protected route. We exclude the
  /// unauthenticated auth endpoints (signup/login/refresh/logout receive
  /// their tokens in the body) and the health probe.
  static bool _acceptsBearer(String path) {
    if (path == ApiEndpoints.health) return false;
    if (path == ApiEndpoints.authSignup) return false;
    if (path == ApiEndpoints.authLogin) return false;
    if (path == ApiEndpoints.authRefresh) return false;
    if (path == ApiEndpoints.authLogout) return false;
    return true;
  }
}
