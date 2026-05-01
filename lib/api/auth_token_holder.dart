import 'dart:async';

/// Mutable, app-wide accessor used by the Dio interceptor to inject the
/// current Bearer token and to drive single-flight token refresh.
///
/// We keep this in the api/ layer (not the auth feature) so the api/
/// layer doesn't depend on the auth feature. The auth controller writes
/// to it; the api layer reads from it.
class AuthTokenHolder {
  AuthTokenHolder();

  String? _accessToken;

  /// Refresh callback supplied by the auth controller. Returns the new
  /// access token, or null/throws if refresh failed (caller will treat
  /// the original 401 as terminal and clear auth state).
  Future<String?> Function()? _refreshCallback;

  /// Single-flight: any concurrent 401s share the same in-flight
  /// refresh future instead of all calling the refresh endpoint.
  Future<String?>? _inflightRefresh;
  int _refreshGeneration = 0;

  String? get accessToken => _accessToken;

  void setAccessToken(String? token) {
    _accessToken = token;
  }

  void setRefreshCallback(Future<String?> Function()? callback) {
    _refreshCallback = callback;
  }

  void clear() {
    _accessToken = null;
    _refreshGeneration++;
    _inflightRefresh = null;
  }

  /// Drives token refresh. The first caller starts the refresh; any
  /// caller that arrives while it's still in flight awaits the same
  /// future. Returns the new access token or null.
  Future<String?> refresh() {
    final existing = _inflightRefresh;
    if (existing != null) return existing;

    final callback = _refreshCallback;
    if (callback == null) {
      return Future<String?>.value(null);
    }

    final generation = _refreshGeneration;
    final future = () async {
      try {
        final token = await callback();
        return token;
      } finally {
        if (generation == _refreshGeneration) {
          _inflightRefresh = null;
        }
      }
    }();

    _inflightRefresh = future;
    return future;
  }
}
