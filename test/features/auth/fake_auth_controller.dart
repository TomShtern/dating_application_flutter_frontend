import 'package:flutter_dating_application_1/features/auth/auth_controller.dart';

/// Test double that starts in a fixed [AuthState] and never touches Clerk or
/// the network. `ClerkAuthState` has a private constructor, so widget tests
/// override [authControllerProvider] instead of faking Clerk itself.
class FakeAuthController extends AuthController {
  FakeAuthController(this.initial);

  final AuthState initial;

  @override
  AuthState build() => initial;

  /// AppHomeScreen calls this while the state is [AuthUnknown]; the real one
  /// would touch Clerk.
  @override
  Future<void> restoreSession() async {}
}
