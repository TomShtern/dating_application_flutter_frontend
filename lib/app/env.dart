class Env {
  const Env._();

  static const String apiBaseUrl = String.fromEnvironment(
    'DATING_APP_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:7070',
  );

  static const String sharedSecret = String.fromEnvironment(
    'DATING_APP_SHARED_SECRET',
    defaultValue: 'lan-dev-secret',
  );
}
