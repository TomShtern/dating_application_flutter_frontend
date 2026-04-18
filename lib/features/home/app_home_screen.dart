import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/app_async_state.dart';
import '../auth/dev_user_picker_screen.dart';
import '../auth/selected_user_provider.dart';
import 'signed_in_shell.dart';

class AppHomeScreen extends ConsumerWidget {
  const AppHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedUser = ref.watch(selectedUserProvider);

    return selectedUser.when(
      data: (user) {
        if (user == null) {
          return const DevUserPickerScreen();
        }

        return SignedInShell(currentUser: user);
      },
      loading: () => const Scaffold(
        body: AppAsyncState.loading(message: 'Restoring your selected user…'),
      ),
      error: (error, stackTrace) => Scaffold(
        body: AppAsyncState.error(
          message: 'Unable to restore the selected dev user.',
          onRetry: () => ref.invalidate(selectedUserProvider),
        ),
      ),
    );
  }
}
