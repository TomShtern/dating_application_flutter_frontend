import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/api/api_endpoints.dart';
import 'package:flutter_dating_application_1/api/api_error.dart';
import 'package:flutter_dating_application_1/api/api_headers.dart';
import 'package:flutter_dating_application_1/api/clerk_auth_interceptor.dart';

/// Answers each request with the next scripted (status, body) pair and records
/// the headers it was sent.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this._script);

  final List<(int, Map<String, dynamic>)> _script;
  final List<Map<String, dynamic>> sentHeaders = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    sentHeaders.add(Map<String, dynamic>.from(options.headers));
    final (status, body) = _script.removeAt(0);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        if (body['retryAfter'] != null)
          'retry-after': ['${body['retryAfter']}'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  const unauthorized = {'code': 'UNAUTHORIZED', 'message': 'nope'};
  const notProvisioned = {'code': 'NOT_PROVISIONED', 'message': 'no profile'};
  const ok = {'ok': true};

  late _ScriptedAdapter adapter;
  late Dio dio;
  late int tokenCalls;
  late int provisionCalls;
  late int invalidCalls;
  late List<Duration> delays;
  String? signedOutToken;
  var signedOut = false;

  void build(List<(int, Map<String, dynamic>)> script) {
    adapter = _ScriptedAdapter(script);
    tokenCalls = 0;
    provisionCalls = 0;
    invalidCalls = 0;
    delays = [];
    signedOut = false;
    signedOutToken = null;
    dio = Dio(BaseOptions(baseUrl: 'http://test'))..httpClientAdapter = adapter;
    dio.interceptors.add(
      ClerkAuthInterceptor(
        dio: dio,
        sharedSecret: 'secret',
        getToken: () async {
          tokenCalls++;
          return signedOut ? signedOutToken : 'token-$tokenCalls';
        },
        provision: () async => provisionCalls++,
        onSessionInvalid: () async => invalidCalls++,
        delay: (duration) async => delays.add(duration),
      ),
    );
  }

  test(
    'asks for a fresh token on every request and sends the secret',
    () async {
      build([(200, ok), (200, ok)]);

      await dio.get<dynamic>(ApiEndpoints.userDetail('u-1'));
      await dio.get<dynamic>(ApiEndpoints.userDetail('u-1'));

      expect(
        adapter.sentHeaders[0][ApiHeaders.authorizationHeader],
        'Bearer token-1',
      );
      expect(
        adapter.sentHeaders[1][ApiHeaders.authorizationHeader],
        'Bearer token-2',
      );
      expect(adapter.sentHeaders[0][ApiHeaders.sharedSecretHeader], 'secret');
      expect(tokenCalls, 2);
    },
  );

  test('health probe gets neither secret nor token', () async {
    build([(200, ok)]);

    await dio.get<dynamic>(ApiEndpoints.health);

    expect(
      adapter.sentHeaders.single.containsKey(ApiHeaders.authorizationHeader),
      isFalse,
    );
    expect(
      adapter.sentHeaders.single.containsKey(ApiHeaders.sharedSecretHeader),
      isFalse,
    );
    expect(tokenCalls, 0);
  });

  test('NOT_PROVISIONED provisions once, then retries and succeeds', () async {
    build([(401, notProvisioned), (200, ok)]);

    final response = await dio.get<dynamic>(ApiEndpoints.userDetail('u-1'));

    expect(response.statusCode, 200);
    expect(provisionCalls, 1);
    expect(adapter.sentHeaders, hasLength(2));
    expect(
      adapter.sentHeaders[1][ApiHeaders.authorizationHeader],
      isNot('Bearer token-1'),
    );
    expect(invalidCalls, 0);
  });

  test('NOT_PROVISIONED on the retry does not provision again', () async {
    build([(401, notProvisioned), (401, notProvisioned)]);

    await expectLater(
      dio.get<dynamic>(ApiEndpoints.userDetail('u-1')),
      throwsA(isA<DioException>()),
    );

    expect(provisionCalls, 1);
  });

  test('UNAUTHORIZED retries once with a fresh token', () async {
    build([(401, unauthorized), (200, ok)]);

    final response = await dio.get<dynamic>(ApiEndpoints.userDetail('u-1'));

    expect(response.statusCode, 200);
    expect(adapter.sentHeaders, hasLength(2));
    expect(
      adapter.sentHeaders[0][ApiHeaders.authorizationHeader],
      'Bearer token-1',
    );
    expect(
      adapter.sentHeaders[1][ApiHeaders.authorizationHeader],
      'Bearer token-3',
    );
    expect(invalidCalls, 0);
  });

  test(
    'a second UNAUTHORIZED signs the session out and surfaces the 401',
    () async {
      build([(401, unauthorized), (401, unauthorized)]);

      await expectLater(
        dio.get<dynamic>(ApiEndpoints.userDetail('u-1')),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            401,
          ),
        ),
      );

      expect(adapter.sentHeaders, hasLength(2));
      expect(invalidCalls, 1);
    },
  );

  test('signed out: no Authorization header and no retry', () async {
    build([(401, unauthorized)]);
    signedOut = true;

    await expectLater(
      dio.get<dynamic>(ApiEndpoints.userDetail('u-1')),
      throwsA(isA<DioException>()),
    );

    expect(adapter.sentHeaders, hasLength(1));
    expect(
      adapter.sentHeaders.single.containsKey(ApiHeaders.authorizationHeader),
      isFalse,
    );
    expect(invalidCalls, 0);
  });

  test('403 is never retried', () async {
    build([
      (403, {'code': 'FORBIDDEN', 'message': 'wrong id'}),
    ]);

    await expectLater(
      dio.get<dynamic>(ApiEndpoints.userDetail('u-1')),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          403,
        ),
      ),
    );

    expect(adapter.sentHeaders, hasLength(1));
    expect(provisionCalls, 0);
    expect(invalidCalls, 0);
  });

  const rateLimited = {'code': 'RATE_LIMITED', 'message': 'slow down'};

  test('429 on a GET waits Retry-After and retries once', () async {
    build([
      (429, {...rateLimited, 'retryAfter': 3}),
      (200, ok),
    ]);

    final response = await dio.get<dynamic>(ApiEndpoints.userDetail('u-1'));

    expect(response.statusCode, 200);
    expect(delays, [const Duration(seconds: 3)]);
    expect(adapter.sentHeaders, hasLength(2));
  });

  test(
    '429 wait is capped, and a missing Retry-After uses a default',
    () async {
      build([
        (429, {...rateLimited, 'retryAfter': 120}),
        (200, ok),
        (429, rateLimited),
        (200, ok),
      ]);

      await dio.get<dynamic>(ApiEndpoints.userDetail('u-1'));
      await dio.get<dynamic>(ApiEndpoints.userDetail('u-1'));

      expect(delays, [const Duration(seconds: 5), const Duration(seconds: 2)]);
    },
  );

  test('a second 429 is surfaced, not retried again', () async {
    build([(429, rateLimited), (429, rateLimited)]);

    await expectLater(
      dio.get<dynamic>(ApiEndpoints.userDetail('u-1')),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          429,
        ),
      ),
    );

    expect(adapter.sentHeaders, hasLength(2));
  });

  test('429 on a write is not retried', () async {
    build([(429, rateLimited)]);

    await expectLater(
      dio.post<dynamic>(ApiEndpoints.userDetail('u-1'), data: {'a': 1}),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          429,
        ),
      ),
    );

    expect(adapter.sentHeaders, hasLength(1));
    expect(delays, isEmpty);
  });

  test('a multipart upload survives a 401 retry', () async {
    build([(401, unauthorized), (200, ok)]);

    final response = await dio.post<dynamic>(
      ApiEndpoints.userPhotos('u-1'),
      data: FormData.fromMap({
        'photo': MultipartFile.fromBytes([1, 2, 3], filename: 'a.jpg'),
      }),
    );

    expect(response.statusCode, 200);
    expect(adapter.sentHeaders, hasLength(2));
  });

  test('a backend photo is requested with the secret and a fresh token '
      'each time', () async {
    build([(200, ok), (200, ok)]);
    final client = ApiClient(dio: dio);

    await client.getPhotoBytes('http://test/photos/u-1/a.jpg');
    await client.getPhotoBytes('/photos/u-1/b.jpg');

    expect(
      adapter.sentHeaders[0][ApiHeaders.authorizationHeader],
      'Bearer token-1',
    );
    expect(
      adapter.sentHeaders[1][ApiHeaders.authorizationHeader],
      'Bearer token-2',
    );
    expect(adapter.sentHeaders[0][ApiHeaders.sharedSecretHeader], 'secret');
    expect(adapter.sentHeaders[1][ApiHeaders.sharedSecretHeader], 'secret');
    expect(tokenCalls, 2);
  });

  test('an image on another host gets neither secret nor token', () async {
    build([(200, ok)]);

    await ApiClient(dio: dio).getPhotoBytes('https://cdn.example.com/a.jpg');

    expect(
      adapter.sentHeaders.single.containsKey(ApiHeaders.authorizationHeader),
      isFalse,
    );
    expect(
      adapter.sentHeaders.single.containsKey(ApiHeaders.sharedSecretHeader),
      isFalse,
    );
    expect(tokenCalls, 0);
  });

  test('a protocol-relative image URL counts as another host', () async {
    build([(200, ok)]);

    await ApiClient(dio: dio).getPhotoBytes('//cdn.example.com/a.jpg');

    expect(
      adapter.sentHeaders.single.containsKey(ApiHeaders.authorizationHeader),
      isFalse,
    );
    expect(
      adapter.sentHeaders.single.containsKey(ApiHeaders.sharedSecretHeader),
      isFalse,
    );
    expect(tokenCalls, 0);
  });

  for (final status in [401, 403, 404, 429]) {
    test('a $status on a photo fails once: no retry, no sign-out', () async {
      build([(status, unauthorized)]);

      await expectLater(
        ApiClient(dio: dio).getPhotoBytes('/photos/u-1/a.jpg'),
        throwsA(
          isA<ApiError>().having((e) => e.statusCode, 'statusCode', status),
        ),
      );

      expect(adapter.sentHeaders, hasLength(1));
      expect(provisionCalls, 0);
      expect(invalidCalls, 0);
      expect(delays, isEmpty);
    });
  }
}
