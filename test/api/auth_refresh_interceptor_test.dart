import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/api/api_endpoints.dart';
import 'package:flutter_dating_application_1/api/api_headers.dart';
import 'package:flutter_dating_application_1/app/app_config.dart';
import 'package:flutter_dating_application_1/shared/persistence/shared_preferences_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// Builds a ProviderContainer with the real `dioProvider`
  /// (so we exercise the real interceptor) but injects a synthetic
  /// transport adapter that we can script per test.
  Future<ProviderContainer> buildContainer({
    required _MockHttpAdapter adapter,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        appConfigProvider.overrideWithValue(
          const AppConfig(
            baseUrl: 'http://localhost:7070',
            lanSharedSecret: 'secret',
          ),
        ),
      ],
    );
    final dio = container.read(dioProvider);
    dio.httpClientAdapter = adapter;
    return container;
  }

  test(
    'attaches Bearer token from holder on protected requests',
    () async {
      final adapter = _MockHttpAdapter()
        ..plan(_MockResponse(statusCode: 200, body: <String, dynamic>{}));
      final container = await buildContainer(adapter: adapter);
      final holder = container.read(authTokenHolderProvider);
      holder.setAccessToken('token-1');

      final dio = container.read(dioProvider);
      await dio.get<dynamic>(ApiEndpoints.userDetail('u-1'));

      expect(adapter.requests.single.headers[ApiHeaders.authorizationHeader],
          'Bearer token-1');
      container.dispose();
    },
  );

  test(
    'on 401 it calls the refresh callback exactly once and retries the request',
    () async {
      final adapter = _MockHttpAdapter()
        ..plan(_MockResponse(statusCode: 401, body: {'message': 'expired'}))
        ..plan(_MockResponse(statusCode: 200, body: {'ok': true}));

      final container = await buildContainer(adapter: adapter);
      final holder = container.read(authTokenHolderProvider);
      holder.setAccessToken('stale');

      var refreshCalls = 0;
      holder.setRefreshCallback(() async {
        refreshCalls++;
        holder.setAccessToken('fresh');
        return 'fresh';
      });

      final dio = container.read(dioProvider);
      final response = await dio.get<dynamic>(ApiEndpoints.userDetail('u-1'));

      expect(response.statusCode, 200);
      expect(refreshCalls, 1);
      expect(adapter.requests, hasLength(2));
      expect(adapter.requests[0].headers[ApiHeaders.authorizationHeader],
          'Bearer stale');
      expect(adapter.requests[1].headers[ApiHeaders.authorizationHeader],
          'Bearer fresh');
      container.dispose();
    },
  );

  test(
    'two concurrent 401s share a single in-flight refresh (single-flight)',
    () async {
      final adapter = _MockHttpAdapter()
        ..plan(_MockResponse(statusCode: 401, body: {'message': 'expired'}))
        ..plan(_MockResponse(statusCode: 401, body: {'message': 'expired'}))
        ..plan(_MockResponse(statusCode: 200, body: {'a': 1}))
        ..plan(_MockResponse(statusCode: 200, body: {'b': 2}));

      final container = await buildContainer(adapter: adapter);
      final holder = container.read(authTokenHolderProvider);
      holder.setAccessToken('stale');

      var refreshCalls = 0;
      final refreshGate = Completer<void>();
      holder.setRefreshCallback(() async {
        refreshCalls++;
        await refreshGate.future;
        holder.setAccessToken('fresh');
        return 'fresh';
      });

      final dio = container.read(dioProvider);
      final futureA = dio.get<dynamic>(ApiEndpoints.userDetail('u-1'));
      final futureB = dio.get<dynamic>(ApiEndpoints.userDetail('u-2'));

      // Allow the first 401s to be observed and refresh to be requested.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      refreshGate.complete();

      final results = await Future.wait([futureA, futureB]);

      expect(refreshCalls, 1, reason: 'refresh must be single-flight');
      expect(results.every((r) => r.statusCode == 200), isTrue);
      container.dispose();
    },
  );

  test(
    'when refresh fails, the original 401 propagates and is not retried again',
    () async {
      final adapter = _MockHttpAdapter()
        ..plan(_MockResponse(statusCode: 401, body: {'message': 'expired'}));

      final container = await buildContainer(adapter: adapter);
      final holder = container.read(authTokenHolderProvider);
      holder.setAccessToken('stale');

      var refreshCalls = 0;
      holder.setRefreshCallback(() async {
        refreshCalls++;
        return null; // refresh failure
      });

      final dio = container.read(dioProvider);
      await expectLater(
        () => dio.get<dynamic>(ApiEndpoints.userDetail('u-1')),
        throwsA(isA<DioException>()),
      );

      expect(refreshCalls, 1);
      expect(adapter.requests, hasLength(1));
      container.dispose();
    },
  );

  test('does not attempt refresh when the failing request is the refresh endpoint',
      () async {
    final adapter = _MockHttpAdapter()
      ..plan(_MockResponse(statusCode: 401, body: {'message': 'bad token'}));

    final container = await buildContainer(adapter: adapter);
    final holder = container.read(authTokenHolderProvider);
    var refreshCalls = 0;
    holder.setRefreshCallback(() async {
      refreshCalls++;
      return 'should-not-be-called';
    });

    final dio = container.read(dioProvider);
    await expectLater(
      () => dio.post<dynamic>(
        ApiEndpoints.authRefresh,
        data: {'refreshToken': 'r'},
      ),
      throwsA(isA<DioException>()),
    );
    expect(refreshCalls, 0);
    container.dispose();
  });
}

// ── Test infra ────────────────────────────────────────────────────────────

class _MockResponse {
  _MockResponse({required this.statusCode, required this.body});
  final int statusCode;
  final dynamic body;
}

class _RecordedRequest {
  _RecordedRequest({required this.path, required this.headers});
  final String path;
  final Map<String, dynamic> headers;
}

class _MockHttpAdapter implements HttpClientAdapter {
  final List<_MockResponse> _planned = [];
  final List<_RecordedRequest> requests = [];

  void plan(_MockResponse response) => _planned.add(response);

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    requests.add(
      _RecordedRequest(
        path: options.path,
        headers: Map<String, dynamic>.from(options.headers),
      ),
    );
    if (_planned.isEmpty) {
      return ResponseBody.fromString('{}', 200, headers: {
        Headers.contentTypeHeader: ['application/json'],
      });
    }
    final next = _planned.removeAt(0);
    final body = next.body == null ? '{}' : _encode(next.body);
    return ResponseBody.fromString(
      body,
      next.statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  static String _encode(dynamic body) {
    if (body is String) return body;
    return _toJson(body);
  }

  static String _toJson(dynamic value) {
    // tiny inlined JSON encoder for primitives/maps/lists used in tests
    if (value == null) return 'null';
    if (value is num || value is bool) return value.toString();
    if (value is String) return '"${value.replaceAll('"', '\\"')}"';
    if (value is List) return '[${value.map(_toJson).join(',')}]';
    if (value is Map) {
      final entries = value.entries.map(
        (e) => '"${e.key}":${_toJson(e.value)}',
      );
      return '{${entries.join(',')}}';
    }
    throw StateError('Cannot encode ${value.runtimeType}');
  }
}
