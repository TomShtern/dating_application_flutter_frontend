import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../home/backend_health_banner.dart';
import '../../models/user_summary.dart';
import '../../shared/widgets/app_async_state.dart';
import 'selected_user_provider.dart';

class DevUserPickerScreen extends ConsumerWidget {
  const DevUserPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableUsers = ref.watch(availableUsersProvider);
    final selectedUser = ref.watch(selectedUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Choose a dev user')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pick an existing backend user profile to act as while real authentication is still out of scope.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            const BackendHealthBanner(),
            const SizedBox(height: 16),
            selectedUser.when(
              data: (user) => _CurrentUserCard(user: user),
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (error, stackTrace) => const _CurrentUserCard(user: null),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: availableUsers.when(
                data: (users) {
                  if (users.isEmpty) {
                    return const AppAsyncState.empty(
                      message: 'No dev users are available yet.',
                    );
                  }

                  return ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _UserCard(
                        user: user,
                        onSelect: () => _handleUserSelected(context, ref, user),
                      );
                    },
                  );
                },
                loading: () =>
                    const AppAsyncState.loading(message: 'Loading dev users…'),
                error: (error, _) => AppAsyncState.error(
                  message: _errorMessage(error),
                  onRetry: () => ref.invalidate(availableUsersProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUserSelected(
    BuildContext context,
    WidgetRef ref,
    UserSummary user,
  ) async {
    await ref.read(selectUserControllerProvider).selectUser(user);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Current user updated to ${user.name}.')),
    );
  }

  String _errorMessage(Object error) {
    if (error is ApiError) {
      return error.message;
    }

    return 'Unable to load dev users right now.';
  }
}

class _CurrentUserCard extends StatelessWidget {
  const _CurrentUserCard({required this.user});

  final UserSummary? user;

  @override
  Widget build(BuildContext context) {
    final currentUserLabel = user == null
        ? 'Current user: none selected'
        : 'Current user: ${user!.name}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentUserLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              user == null
                  ? 'Select one of the backend users below to start the core mobile loop.'
                  : 'Persisted selection: ${user!.id}',
            ),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.onSelect});

  final UserSummary user;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(child: Text(user.name.characters.first.toUpperCase())),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text('Age ${user.age} • ${user.state}'),
                ],
              ),
            ),
            FilledButton(
              onPressed: onSelect,
              child: Text('Continue as ${user.name}'),
            ),
          ],
        ),
      ),
    );
  }
}
