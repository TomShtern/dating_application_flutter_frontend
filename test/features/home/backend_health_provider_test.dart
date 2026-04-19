import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/features/home/backend_health_provider.dart';
import 'package:flutter_dating_application_1/models/health_status.dart';

void main() {
  test('loads backend health from the api client', () async {
    final apiClient = _FakeHealthApiClient([
      HealthStatus(status: 'ok', timestamp: DateTime(2026, 4, 19, 9)),
    ]);

    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(apiClient)],
    );
    addTearDown(container.dispose);

    final health = await container.read(backendHealthProvider.future);

    expect(health.status, 'ok');
    expect(health.isHealthy, isTrue);
    expect(apiClient.calls, 1);
  });

  test(
    'invalidating backend health provider triggers a fresh request',
    () async {
      final apiClient = _FakeHealthApiClient([
        HealthStatus(status: 'ok', timestamp: DateTime(2026, 4, 19, 9)),
        HealthStatus(status: 'degraded', timestamp: DateTime(2026, 4, 19, 10)),
      ]);

      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(apiClient)],
      );
      addTearDown(container.dispose);

      final initial = await container.read(backendHealthProvider.future);
      expect(initial.status, 'ok');

      container.invalidate(backendHealthProvider);
      final refreshed = await container.read(backendHealthProvider.future);

      expect(refreshed.status, 'degraded');
      expect(apiClient.calls, 2);
    },
  );
}

class _FakeHealthApiClient extends ApiClient {
  _FakeHealthApiClient(this.responses) : super(dio: Dio());

  final List<HealthStatus> responses;
  int calls = 0;

  @override
  Future<HealthStatus> getHealth() async {
    final index = calls < responses.length ? calls : responses.length - 1;
    calls++;
    return responses[index];
  }
}
