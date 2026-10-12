import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/env.dart';
import 'features/auth/clerk_auth_provider.dart';
import 'features/auth/sign_in_redirect.dart';
import 'shared/persistence/shared_preferences_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();

  assert(
    Env.clerkPublishableKey.isNotEmpty,
    'Pass --dart-define=CLERK_PUBLISHABLE_KEY=pk_... '
    '(or --dart-define-from-file=.env).',
  );
  final clerkAuthState = await ClerkAuthState.create(
    config: ClerkAuthConfig(
      publishableKey: Env.clerkPublishableKey,
      redirectionGenerator: signInRedirectFor,
      deepLinkStream: signInRedirectLinks(),
    ),
  );

  completeBrowserSignIns(clerkAuthState);

  // Clerk's prebuilt widgets need a ClerkAuth ancestor; it sits above
  // MaterialApp as in Clerk's own setup. The same state is shared with
  // Riverpod so the Dio interceptor can read tokens without a BuildContext.
  runApp(
    ClerkAuth(
      authState: clerkAuthState,
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          clerkAuthStateProvider.overrideWithValue(clerkAuthState),
        ],
        child: const DatingApp(),
      ),
    ),
  );
}
