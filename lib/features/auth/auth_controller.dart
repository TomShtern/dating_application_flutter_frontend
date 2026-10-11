import 'dart:async';

import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../api/api_error.dart';
import '../../models/auth_user.dart';
import '../../models/user_summary.dart';
import 'clerk_auth_provider.dart';
import 'selected_user_provider.dart';

sealed class AuthEvent {
  const AuthEvent();
}

class AuthSessionExpired extends AuthEvent {
  const AuthSessionExpired({this.message});
  final String? message;
}

final _authEventController = StreamController<AuthEvent>.broadcast();

final authEventProvider = StreamProvider<AuthEvent>((ref) {
  return _authEventController.stream;
});

sealed class AuthState {
  const AuthState();
}

/// Starting up, or provisioning the local profile after a Clerk sign-in.
class AuthUnknown extends AuthState {
  const AuthUnknown();
}

/// Not signed in to Clerk.
class Unauthenticated extends AuthState {
  const Unauthenticated({this.message});
  final String? message;
}

/// Signed in to Clerk but `POST /api/auth/session` failed (backend down,
/// network). The user can retry or sign out.
class AuthProvisionFailed extends AuthState {
  const AuthProvisionFailed(this.message);
  final String message;
}

/// Signed in to Clerk with a provisioned local profile.
class Authenticated extends AuthState {
  const Authenticated(this.user);
  final AuthUser user;
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// Bridges Clerk (who the user is) and the backend (their local profile).
///
/// Clerk owns sign-in, passwords and sessions. This controller only reacts to
/// Clerk's state: signed in -> provision the local profile and store its id in
/// `selectedUserProvider`; signed out -> clear that id.
class AuthController extends Notifier<AuthState> {
  late final ApiClient _api;
  late final ClerkAuthState _clerk;
  Future<AuthUser>? _inflightSession;

  @override
  AuthState build() {
    _api = ref.read(apiClientProvider);
    _clerk = ref.read(clerkAuthStateProvider);
    _clerk.addListener(_onClerkChanged);
    ref.onDispose(() => _clerk.removeListener(_onClerkChanged));
    return const AuthUnknown();
  }

  /// Startup: provision if Clerk restored a session, else show sign-in.
  Future<void> restoreSession() async {
    if (_clerk.isSignedIn) {
      await _provisionAfterSignIn();
    } else {
      state = const Unauthenticated();
    }
  }

  /// Re-provisions the local profile and updates the stored id. Used by the
  /// HTTP interceptor on 401 `NOT_PROVISIONED`; throws [ApiError] on failure
  /// so the interceptor can pass the original error on.
  Future<void> provision() async {
    final user = await (_inflightSession ??= _api
        .provisionSession()
        .whenComplete(() => _inflightSession = null));
    await _acceptUser(user);
  }

  Future<void> retryProvision() => _provisionAfterSignIn();

  /// Best-effort refresh of the profile-completion snapshot after edits.
  Future<void> refreshMe() async {
    if (state is! Authenticated) return;
    try {
      state = Authenticated(await _api.provisionSession());
    } catch (_) {
      // Best-effort — never sign out on a background refresh failure.
    }
  }

  Future<void> logout() async {
    await _signOutAndClear();
    state = const Unauthenticated();
  }

  /// Deletes the backend profile, then signs out of Clerk. The Clerk account
  /// itself is not deleted, so signing in again provisions a fresh profile.
  Future<void> deleteAccount() async {
    final selected = await ref.read(selectedUserProvider.future);
    try {
      if (selected != null) {
        await _api.deleteUser(userId: selected.id);
      }
    } on ApiError {
      // Best effort — local cleanup still runs so a deleted backend profile
      // cannot leave a stale session behind.
    } catch (_) {
      // Non-API errors (network, timeout) — proceed with local cleanup.
    }
    await _signOutAndClear();
    state = const Unauthenticated(message: 'Your account has been deleted.');
  }

  /// Called by the interceptor when a retried request is still 401.
  Future<void> expireSession() async {
    const message = 'Session expired. Please sign in again.';
    await _signOutAndClear();
    state = const Unauthenticated(message: message);
    _authEventController.add(const AuthSessionExpired(message: message));
  }

  void _onClerkChanged() {
    final current = state;
    if (_clerk.isSignedIn) {
      // A sign-in just completed (sign-in screen, quick sign-in, sign-up).
      if (current is Unauthenticated) {
        unawaited(_provisionAfterSignIn());
      }
    } else if (current is Authenticated || current is AuthProvisionFailed) {
      // Signed out elsewhere (Clerk UI, revoked session).
      unawaited(_clearLocal());
      state = const Unauthenticated();
    }
  }

  Future<void> _provisionAfterSignIn() async {
    state = const AuthUnknown();
    try {
      await provision();
    } on ApiError catch (error) {
      // A forced sign-out (expireSession) already set the final state.
      if (_clerk.isSignedIn) state = AuthProvisionFailed(error.message);
    } catch (error) {
      if (_clerk.isSignedIn) {
        state = const AuthProvisionFailed('Could not load your profile.');
      }
    }
    // Clerk signed out while provisioning was in flight and nothing else set
    // a final state: leave the startup spinner for the sign-in screen.
    if (!_clerk.isSignedIn && state is AuthUnknown) {
      state = const Unauthenticated();
    }
  }

  Future<void> _acceptUser(AuthUser user) async {
    UserSummary summary;
    try {
      final detail = await _api.getUserDetail(userId: user.id);
      summary = UserSummary(
        id: detail.id,
        name: detail.name.isNotEmpty
            ? detail.name
            : (user.displayName ?? 'New member'),
        age: detail.age,
        state: detail.state,
      );
    } on ApiError {
      // A just-provisioned profile may not be readable as a full detail yet.
      // Its state is not guessed: a fresh profile can start `UNDER_REVIEW`,
      // so an unread state stays unknown until the backend reports it.
      summary = UserSummary(
        id: user.id,
        name: user.displayName ?? 'New member',
        age: 0,
        state: 'UNKNOWN',
      );
    }
    // Signed out while the profile was loading: do not sign back in.
    if (!_clerk.isSignedIn) {
      return;
    }
    await ref.read(selectedUserStoreProvider).saveSelectedUser(summary);
    ref.invalidate(selectedUserProvider);
    state = Authenticated(user);
  }

  Future<void> _signOutAndClear() async {
    try {
      await _clerk.signOut();
    } catch (_) {
      // Already signed out, or offline — local cleanup still runs.
    }
    await _clearLocal();
  }

  Future<void> _clearLocal() async {
    await ref.read(selectedUserStoreProvider).clearSelectedUser();
    ref.invalidate(selectedUserProvider);
  }
}
