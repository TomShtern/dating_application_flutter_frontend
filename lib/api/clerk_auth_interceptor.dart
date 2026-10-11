import 'package:dio/dio.dart';

import 'api_endpoints.dart';
import 'api_headers.dart';

const String _retriedFlag = '_authRetried';
const String _rateLimitRetriedFlag = '_rateLimitRetried';
const int _defaultRetryAfterSeconds = 2;
const int _maxRetryAfterSeconds = 5;

Future<void> _sleep(Duration duration) => Future<void>.delayed(duration);

/// The single place HTTP auth happens.
///
/// - Every request gets the shared secret and a fresh Clerk session token as
///   `Authorization: Bearer`. Clerk tokens live 60 s, so the token is asked
///   for on every request and never cached, stored or refreshed on a timer
///   here.
/// - 401 `NOT_PROVISIONED`: provision the local profile, then retry once.
/// - Any other 401: retry once with a fresh token; a second 401 means the
///   session is no longer valid, so [onSessionInvalid] signs the user out.
/// - 429: wait `Retry-After` (capped at 5 s) and retry a GET once.
/// - 403 is a client bug (wrong id in the path) and is never retried.
/// - A request marked [passiveExtra] (photos, presence) gets the same headers
///   but its failures pass straight through: no retry, no provisioning, no
///   sign-out.
/// - A request marked [skipAuthExtra] (a URL that is not this backend) gets no
///   auth headers at all, so the token never leaves for another host.
///
/// The collaborators are callbacks so `lib/api/` does not depend on the auth
/// feature.
class ClerkAuthInterceptor extends Interceptor {
  /// `extra` key: authenticate, but never retry or sign out on failure.
  static const String passiveExtra = 'passiveRequest';

  /// `extra` key: send no shared secret and no Bearer token.
  static const String skipAuthExtra = 'skipAuth';

  ClerkAuthInterceptor({
    required Dio dio,
    required this.sharedSecret,
    required this.getToken,
    required this.provision,
    required this.onSessionInvalid,
    this.delay = _sleep,
  }) : _dio = dio;

  final Dio _dio;
  final String sharedSecret;

  /// Returns a fresh Clerk session JWT, or null when signed out.
  final Future<String?> Function() getToken;

  /// Calls `POST /api/auth/session`.
  final Future<void> Function() provision;

  /// Signs the user out after a retried 401.
  final Future<void> Function() onSessionInvalid;

  /// Waits before a 429 retry; replaced in tests.
  final Future<void> Function(Duration) delay;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipAuthExtra] == true) {
      return handler.next(options);
    }

    options.headers.addAll(
      ApiHeaders.build(path: options.path, sharedSecret: sharedSecret),
    );

    if (ApiHeaders.needsBearer(options.path)) {
      // When signed out there is no token: send the request without one and
      // let the server answer 401, so the caller sees a normal auth failure.
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        options.headers[ApiHeaders.authorizationHeader] = 'Bearer $token';
      } else {
        options.headers.remove(ApiHeaders.authorizationHeader);
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final extra = err.requestOptions.extra;
    if (extra[passiveExtra] == true || extra[skipAuthExtra] == true) {
      return handler.next(err);
    }

    final status = err.response?.statusCode;
    if (status == 429) {
      return _backOff(err, handler);
    }
    if (status != 401) {
      return handler.next(err);
    }

    final options = err.requestOptions;
    final alreadyRetried = options.extra[_retriedFlag] == true;
    final data = err.response?.data;
    final code = data is Map ? data['code'] as String? : null;

    if (code == 'NOT_PROVISIONED') {
      // The session call itself never returns NOT_PROVISIONED; guard anyway
      // so a server quirk cannot recurse.
      if (alreadyRetried || options.path == ApiEndpoints.authSession) {
        return handler.next(err);
      }
      try {
        await provision();
      } catch (_) {
        return handler.next(err);
      }
      return _retry(err, handler);
    }

    // UNAUTHORIZED: missing, invalid, expired or tampered token, or banned.
    if (alreadyRetried) {
      await onSessionInvalid();
      return handler.next(err);
    }

    final token = await getToken();
    if (token == null || token.isEmpty) {
      // Signed out already; nothing to retry with.
      return handler.next(err);
    }
    return _retry(err, handler);
  }

  /// 429: wait for `Retry-After` (capped) and retry a GET once. Anything that
  /// is not a GET passes through, so a write is never repeated behind the
  /// caller's back; the caller sees the 429 and can back off itself.
  Future<void> _backOff(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (options.method != 'GET' ||
        options.extra[_rateLimitRetriedFlag] == true) {
      return handler.next(err);
    }
    final seconds = int.tryParse(
      err.response?.headers.value('retry-after') ?? '',
    );
    final wait = Duration(
      seconds: (seconds ?? _defaultRetryAfterSeconds).clamp(
        0,
        _maxRetryAfterSeconds,
      ),
    );
    await delay(wait);
    options.extra[_rateLimitRetriedFlag] = true;
    return _fetchAgain(options, err, handler);
  }

  Future<void> _retry(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    options.extra[_retriedFlag] = true;
    return _fetchAgain(options, err, handler);
  }

  Future<void> _fetchAgain(
    RequestOptions options,
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // A FormData body can be sent only once; a retry needs a fresh copy.
    final body = options.data;
    if (body is FormData) {
      options.data = body.clone();
    }
    try {
      // Goes back through onRequest, which attaches a fresh token.
      final response = await _dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    } catch (_) {
      handler.next(err);
    }
  }
}
