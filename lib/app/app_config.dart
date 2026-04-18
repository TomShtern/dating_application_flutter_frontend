import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'env.dart';

class AppConfig {
  const AppConfig({
    required this.baseUrl,
    required this.lanSharedSecret,
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 10),
    this.sendTimeout = const Duration(seconds: 10),
  });

  final String baseUrl;
  final String lanSharedSecret;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;
}

final appConfigProvider = Provider<AppConfig>((ref) {
  return const AppConfig(
    baseUrl: Env.apiBaseUrl,
    lanSharedSecret: Env.sharedSecret,
  );
});
