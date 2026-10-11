import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app-wide Clerk session object. Created once in `main()` and injected
/// via a `ProviderScope` override so the Dio interceptor (which has no
/// `BuildContext`) can ask Clerk for a fresh session token.
final clerkAuthStateProvider = Provider<ClerkAuthState>((ref) {
  throw StateError(
    'clerkAuthStateProvider must be overridden in main() with the '
    'ClerkAuthState created at startup.',
  );
});
