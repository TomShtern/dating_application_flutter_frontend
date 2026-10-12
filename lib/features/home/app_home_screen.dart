import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/app_async_state.dart';
import '../auth/auth_controller.dart';
import '../auth/selected_user_provider.dart';
import '../auth/sign_in_screen.dart';
import '../onboarding/onboarding_gate.dart';
import '../updates/app_release_provider.dart';
import '../updates/app_update_provider.dart';
import '../updates/update_banner.dart';
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

    // Update checks start here, not in the signed-in shell: a fix for a
    // sign-in or onboarding bug has to reach people that bug keeps out.
    ref.listen(appUpdateControllerProvider, (previous, next) {});
    ref.listen(availableReleaseProvider, (previous, next) {});

    // Listen for session-expired events dispatched after forced logout.
    ref.listen<AsyncValue<AuthEvent>>(authEventProvider, (_, next) {
      next.whenData((event) {
        if (event is AuthSessionExpired && mounted) {
          final message = event.message ?? 'Session expired.';
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
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
      Unauthenticated(:final message) => UpdateBannerHost(
        child: SignInScreen(infoMessage: message),
      ),
      AuthProvisionFailed(:final message) => UpdateBannerHost(
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: AppAsyncState.error(
                    message: message,
                    onRetry: () => ref
                        .read(authControllerProvider.notifier)
                        .retryProvision(),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).logout(),
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
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
        return OnboardingGate(child: SignedInShell(currentUser: user));
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
