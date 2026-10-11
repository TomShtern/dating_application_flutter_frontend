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

  /// Clerk publishable key (`pk_...`). Public by design; never put a Clerk
  /// secret key (`sk_...`) in the app.
  static const String clerkPublishableKey = String.fromEnvironment(
    'CLERK_PUBLISHABLE_KEY',
  );

  /// Debug-only quick sign-in accounts, `label|email|password` entries
  /// separated by `;`. Ignored outside debug builds. See
  /// `quick_sign_in_accounts.dart`.
  static const String clerkTestAccounts = String.fromEnvironment(
    'CLERK_TEST_ACCOUNTS',
  );
}
