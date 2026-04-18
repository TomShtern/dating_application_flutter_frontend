import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../models/health_status.dart';

final backendHealthProvider = FutureProvider<HealthStatus>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getHealth();
});
