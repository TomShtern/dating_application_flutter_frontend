import 'api_endpoints.dart';

class ApiHeaders {
  const ApiHeaders._();

  static const String sharedSecretHeader = 'X-DatingApp-Shared-Secret';
  static const String authorizationHeader = 'Authorization';

  /// Static headers for [path]. The Clerk Bearer token is added separately by
  /// the Dio interceptor because it is fetched fresh on every request.
  static Map<String, String> build({
    required String path,
    required String sharedSecret,
  }) {
    final headers = <String, String>{};

    if (path != ApiEndpoints.health) {
      headers[sharedSecretHeader] = sharedSecret;
    }

    return headers;
  }

  /// The health probe is public; every other route is Clerk-authenticated.
  static bool needsBearer(String path) => path != ApiEndpoints.health;
}
