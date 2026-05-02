import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/app_async_state.dart';
import '../auth/auth_controller.dart';
import '../auth/login_screen.dart';
import '../auth/selected_user_provider.dart';
import 'signed_in_shell.dart';

class AppHomeScreen extends ConsumerStatefulWidget {
  const AppHomeScreen({super.key});

  @override
  ConsumerState<AppHomeScreen> createState() => _AppHomeScreenState();
}

class _AppHomeScreenState extends ConsumerState<AppHomeScreen> {
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    // Listen for session-expired events dispatched after forced logout.
    ref.listen<AsyncValue<AuthEvent>>(authEventProvider, (_, next) {
      next.whenData((event) {
        if (event is AuthSessionExpired && mounted) {
          final message = event.message ?? 'Session expired.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      });
    });

    if (!_bootstrapped && authState is AuthUnknown) {
      _bootstrapped = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(authControllerProvider.notifier).restoreSession();
      });
    }

    return switch (authState) {
      AuthUnknown() => const Scaffold(
          body: AppAsyncState.loading(message: 'Restoring your session…'),
        ),
      Unauthenticated(:final message) => LoginScreen(infoMessage: message),
      Authenticated() => _buildAuthenticated(),
    };
  }

  Widget _buildAuthenticated() {
    final selectedUser = ref.watch(selectedUserProvider);

    return selectedUser.when(
      data: (user) {
        if (user == null) {
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