import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/app_async_state.dart';
import '../auth/auth_controller.dart';
import '../auth/login_screen.dart';
import '../auth/selected_user_provider.dart';
import '../location/location_completion_screen.dart';
import 'signed_in_shell.dart';

class AppHomeScreen extends ConsumerStatefulWidget {
  const AppHomeScreen({super.key});

  @override
  ConsumerState<AppHomeScreen> createState() => _AppHomeScreenState();
}

class _AppHomeScreenState extends ConsumerState<AppHomeScreen> {
  bool _bootstrapped = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    if (!_bootstrapped && authState is AuthUnknown) {
      _bootstrapped = true;
      // Schedule after the build to avoid mutating providers during build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(authControllerProvider.notifier).restoreSession();
      });
    }

    return switch (authState) {
      AuthUnknown() => const Scaffold(
          body: AppAsyncState.loading(message: 'Restoring your session…'),
        ),
      Unauthenticated(:final message) => LoginScreen(infoMessage: message),
      Authenticated(:final session) => _buildAuthenticated(session.user.id, session.user.profileCompletionState),
    };
  }

  Widget _buildAuthenticated(String userId, String completionState) {
    // Need the bridged UserSummary for SignedInShell. Watch it.
    final selectedUser = ref.watch(selectedUserProvider);

    // Routing by completion state. Only `needs_location` has a
    // dedicated screen today; everything else falls through to the
    // shell, where the user can edit their profile to fill gaps.
    if (completionState == 'needs_location') {
      return const LocationCompletionScreen();
    }

    return selectedUser.when(
      data: (user) {
        if (user == null) {
          // Should not normally happen — auth bridges into the store.
          // Surface a recoverable error instead of silently looping.
          return Scaffold(
            body: AppAsyncState.error(
              message: 'Could not load your profile.',
              onRetry: () => ref.invalidate(selectedUserProvider),
            ),
          );
        }
        return SignedInShell(currentUser: user);
      },
      loading: () => const Scaffold(
        body: AppAsyncState.loading(message: 'Loading your profile…'),
      ),
      error: (error, _) => Scaffold(
        body: AppAsyncState.error(
          message: 'Could not load your profile.',
          onRetry: () => ref.invalidate(selectedUserProvider),
        ),
      ),
    );
  }
}
