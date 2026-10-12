import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Where the browser sends the user back to after a social sign-in.
///
/// Keep equal to the `<data>` element of the sign-in intent-filter in
/// `android/app/src/main/AndroidManifest.xml`.
final Uri signInRedirectUri = Uri(
  scheme: 'datingapp',
  host: 'auth',
  path: '/callback',
);

/// Social sign-in runs in the phone's real browser on Android: Google refuses
/// passkeys and saved accounts inside an in-app WebView. Other platforms have
/// no handler registered for the link, so they keep Clerk's in-app WebView.
bool get _usesBrowserSignIn =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Clerk's `redirectionGenerator`: the link to come back on for strategies
/// that leave the app, or null to keep the step inside the app.
Uri? signInRedirectFor(BuildContext context, clerk.Strategy strategy) {
  if (_usesBrowserSignIn && strategy.isSSO) return signInRedirectUri;
  return null;
}

/// Whether [uri] is the browser returning from a social sign-in.
bool isSignInRedirect(Uri uri) =>
    uri.scheme == signInRedirectUri.scheme &&
    uri.host == signInRedirectUri.host &&
    uri.path == signInRedirectUri.path;

/// Clerk's `deepLinkStream`: the links that opened the app, including the one
/// that started it, narrowed to sign-in returns.
Stream<Uri>? signInRedirectLinks() {
  if (!_usesBrowserSignIn) return null;
  return AppLinks().uriLinkStream.where(isSignInRedirect);
}

const _rotatingTokenNonce = 'rotating_token_nonce';

/// Finishes a social sign-in after the browser hands the user back.
///
/// Clerk's own handler is not enough for a return link without a
/// `rotating_token_nonce`, which is what a person with no account yet comes
/// back on (an existing account returns with one and needs no help): it
/// refreshes the client, but the SDK drops a refreshed client whose
/// `updated_at` did not move, and a finished verification does not move it.
/// So the sign-in is fetched directly, and a person with no account yet (a
/// "transferable" sign-in) is turned into a sign-up, which neither path of the
/// SDK does on its own.
///
/// Every step is logged with names and states only, never token values;
/// `adb logcat -s flutter` shows the lines on a release build too.
void completeBrowserSignIns(ClerkAuthState auth) {
  final links = signInRedirectLinks();
  if (links == null) return;

  String describe() {
    final signIn = auth.signIn;
    final signUp = auth.signUp;
    return 'signIn=${signIn?.status} '
        'verification=${signIn?.verification?.status} '
        'strategy=${signIn?.verification?.strategy} '
        'signUp=${signUp?.status} missing=${signUp?.missingFields} '
        'signedIn=${auth.user != null}';
  }

  var lastLogged = '';
  var transferring = false;
  Future<void> transferIfNeeded() async {
    if (transferring || auth.signIn?.isTransferable != true) return;
    transferring = true;
    try {
      debugPrint('[sign-in] no account yet, switching to sign-up');
      await auth.transfer();
    } finally {
      transferring = false;
    }
  }

  auth.addListener(() {
    final state = describe();
    if (state != lastLogged) {
      lastLogged = state;
      debugPrint('[sign-in] $state');
    }
    unawaited(transferIfNeeded());
  });

  links.listen((uri) async {
    final hasNonce = uri.queryParameters.containsKey(_rotatingTokenNonce);
    debugPrint(
      '[sign-in] return link, parameters=${uri.queryParameters.keys.toList()}',
    );
    bool waitingForBrowser() {
      final verification = auth.signIn?.verification;
      return verification != null &&
          verification.strategy.isSSO &&
          verification.status == clerk.Status.unverified;
    }

    try {
      // Retried because a fetch that lands while the SDK is refreshing the
      // client is dropped by the same `updated_at` check.
      for (var attempt = 0; attempt < 5; attempt++) {
        if (hasNonce || !waitingForBrowser()) break;
        if (attempt > 0) await Future<void>.delayed(const Duration(seconds: 1));
        // An empty nonce is ignored by Clerk; the call returns the sign-in
        // as the server has it now.
        await auth.completeOAuthSignIn(token: '');
      }
      await transferIfNeeded();
    } on Exception catch (error) {
      debugPrint('[sign-in] could not finish the sign-in: $error');
    }
  });
}
