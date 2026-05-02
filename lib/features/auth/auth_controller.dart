import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../api/api_error.dart';
import '../../models/auth_session.dart';
import '../../models/user_summary.dart';
import '../../shared/persistence/shared_preferences_provider.dart';
import 'auth_token_store.dart';
import 'selected_user_provider.dart';

/// Top-level auth state.
///
/// `unknown` is the bootstrap state (we haven't decided yet whether
/// there is a stored session). The startup screen renders a splash for
/// this state to avoid flashing the login screen.
sealed class AuthState {
  const AuthState();
}

class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class Unauthenticated extends AuthState {
  const Unauthenticated({this.message});
  final String? message;
}

class Authenticated extends AuthState {
  const Authenticated(this.session);
  final AuthSession session;
}

final authTokenStoreProvider = Provider<AuthTokenStore>((ref) {
  return AuthTokenStore(ref.watch(sharedPreferencesProvider));
});

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  late final ApiClient _api;
  late final AuthTokenStore _store;

  @override
  AuthState build() {
    _api = ref.read(apiClientProvider);
    _store = ref.read(authTokenStoreProvider);

    final holder = ref.read(authTokenHolderProvider);
    holder.setRefreshCallback(_performRefresh);

    return const AuthUnknown();
  }

  /// Called from app startup. Reads any persisted session, primes the
  /// token holder, and calls `/me` to verify the access token still
  /// works. If the access token is expired we trigger refresh first.
  Future<void> restoreSession() async {
    final session = _store.readSession();
    if (session == null) {
      state = const Unauthenticated();
      return;
    }

    final holder = ref.read(authTokenHolderProvider);
    holder.setAccessToken(session.accessToken);
    state = Authenticated(session);

    final originalSession = session;
    // Best-effort validation. /me will trigger the 401 → refresh path
    // automatically if the access token has expired.
    try {
      final user = await _api.getMe();
      final synced = session.copyWith(user: user);
      await _store.saveSession(synced);
      state = Authenticated(synced);
      await _bridgeToSelectedUser(synced);
    } on ApiError catch (error) {
      if (error.statusCode == 401) {
        await _clearAuth();
        state = const Unauthenticated(message: 'Please sign in again.');
      } else {
        await _bridgeToSelectedUser(originalSession);
      }
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final session = await _api.login(email: email, password: password);
    await _acceptSession(session);
  }

  Future<void> signup({
    required String email,
    required String password,
    required String dateOfBirth,
  }) async {
    final session = await _api.signup(
      email: email,
      password: password,
      dateOfBirth: dateOfBirth,
    );
    await _acceptSession(session);
  }

  Future<void> logout() async {
    final current = state;
    if (current is Authenticated) {
      try {
        await _api.logout(refreshToken: current.session.refreshToken);
      } on ApiError {
        // Best effort — proceed with local cleanup even if the server
        // rejects the refresh token (e.g. already revoked).
      } catch (_) {
        // Non-API errors (network, timeout) — proceed with local cleanup.
      }
    }
    await _clearAuth();
    state = const Unauthenticated();
  }

  /// Wired into the token holder so the dio interceptor's 401 handler
  /// can drive a refresh without depending on this controller directly.
  Future<String?> _performRefresh() async {
    final current = state;
    final refreshToken = switch (current) {
      Authenticated(:final session) => session.refreshToken,
      _ => _store.readSession()?.refreshToken,
    };
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final session = await _api.refreshSession(refreshToken: refreshToken);
      await _acceptSession(session, bridgeUser: false);
      return session.accessToken;
    } on ApiError {
      await _clearAuth();
      state = const Unauthenticated(
        message: 'Session expired. Please sign in again.',
      );
      return null;
    }
  }

  Future<void> _acceptSession(
    AuthSession session, {
    bool bridgeUser = true,
  }) async {
    await _store.saveSession(session);
    ref.read(authTokenHolderProvider).setAccessToken(session.accessToken);
    state = Authenticated(session);
    if (bridgeUser) {
      await _bridgeToSelectedUser(session);
    }
  }

  /// Bridge: write the auth user into the legacy SelectedUserStore so
  /// existing feature providers (which still take a `userId` arg) keep
  /// working without a sweeping refactor. We try to enrich with the
  /// real UserDetail; on failure we fall back to a thin placeholder.
  Future<void> _bridgeToSelectedUser(AuthSession session) async {
    final store = ref.read(selectedUserStoreProvider);
    UserSummary summary;
    try {
      final detail = await _api.getUserDetail(userId: session.user.id);
      summary = UserSummary(
        id: detail.id,
        name: detail.name.isNotEmpty
            ? detail.name
            : (session.user.displayName ?? session.user.email),
        age: detail.age,
        state: detail.state,
      );
    } on ApiError {
      summary = UserSummary(
        id: session.user.id,
        name: session.user.displayName ?? session.user.email,
        age: 0,
        state: 'ACTIVE',
      );
    }
    await store.saveSelectedUser(summary);
    ref.invalidate(selectedUserProvider);
  }

  Future<void> _clearAuth() async {
    ref.read(authTokenHolderProvider).clear();
    await _store.clearSession();
    final selectedStore = ref.read(selectedUserStoreProvider);
    await selectedStore.clearSelectedUser();
    ref.invalidate(selectedUserProvider);
  }
}
