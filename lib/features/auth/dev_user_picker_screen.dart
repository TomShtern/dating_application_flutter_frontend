import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../home/backend_health_banner.dart';
import '../../models/user_summary.dart';
import '../../shared/formatting/display_text.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/shell_hero.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../theme/app_theme.dart';
import 'selected_user_provider.dart';

class DevUserPickerScreen extends ConsumerWidget {
  const DevUserPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableUsers = ref.watch(availableUsersProvider);
    final selectedUser = ref.watch(selectedUserProvider);
    final selectedUserId = selectedUser.asData?.value?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Choose a dev user')),
      body: Padding(
        padding: AppTheme.screenPadding(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pick a profile to preview the app with. Your choice stays saved on this device between launches.',
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
                        isSelected: selectedUserId == user.id,
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
    final title = user == null
        ? 'Current user: none selected'
        : 'Current profile';
    final summary = user == null
        ? 'Choose one below to jump straight into the app. Your selection stays saved on this device.'
        : '${user!.name} • Age ${user!.age} • ${formatDisplayLabel(user!.state)} profile';
    final supportingCopy = user == null
        ? 'You can switch profiles again anytime from Settings.'
        : 'You can switch profiles again anytime from Settings.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user != null) ...[
              UserAvatar(name: user!.name, radius: 24),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(summary),
                  const SizedBox(height: 6),
                  Text(
                    supportingCopy,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.onSelect,
    required this.isSelected,
  });

  final UserSummary user;
  final VoidCallback onSelect;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSelect,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserAvatar(name: user.name, radius: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (isSelected)
                            const ShellHeroPill(
                              icon: Icons.check_circle_rounded,
                              label: 'Current',
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Age ${user.age} • ${formatDisplayLabel(user.state)} profile',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isSelected
                            ? 'Saved on this device right now.'
                            : 'Tap anywhere to continue as ${user.name}.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Continue as ${user.name}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.chevron_right_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
