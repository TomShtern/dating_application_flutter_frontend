import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/user_summary.dart';
import '../../shared/formatting/display_text.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/developer_only_callout_card.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../theme/app_theme.dart';
import '../home/backend_health_banner.dart';
import 'selected_user_provider.dart';

const _pickerLavender = Color(0xFF7C4DFF);
const _pickerSky = Color(0xFF188DC8);
const _pickerMint = Color(0xFF16A871);

class DevUserPickerScreen extends ConsumerWidget {
  const DevUserPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableUsers = ref.watch(availableUsersProvider);
    final selectedUser = ref.watch(selectedUserProvider);
    final selectedUserId = selectedUser.asData?.value?.id;
    final availableCount = availableUsers.asData?.value.length;

    final availableUserWidgets = switch (availableUsers) {
      AsyncData(:final value) when value.isEmpty => <Widget>[
        _AvailableUsersEmptyState(
          onRefresh: () => ref.invalidate(availableUsersProvider),
        ),
      ],
      AsyncData(:final value) => <Widget>[
        for (var index = 0; index < value.length; index++) ...[
          _UserCard(
            user: value[index],
            isSelected: selectedUserId == value[index].id,
            onSelect: () => _handleUserSelected(context, ref, value[index]),
          ),
          if (index != value.length - 1)
            SizedBox(height: AppTheme.listSpacing()),
        ],
      ],
      AsyncLoading() => const <Widget>[
        AppAsyncState.loading(message: 'Loading dev users…'),
      ],
      AsyncError(:final error) => <Widget>[
        AppAsyncState.error(
          message: _errorMessage(error),
          onRetry: () => ref.invalidate(availableUsersProvider),
        ),
      ],
    };

    final currentUserWidget = switch (selectedUser) {
      AsyncData(:final value) => _CurrentUserCard(user: value),
      AsyncLoading() => const _CurrentUserCard.loading(),
      AsyncError() => const _CurrentUserCard(),
    };

    return Scaffold(
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppTheme.screenPadding(),
          children: [
            _DeveloperIntroCard(
              selectedUser: selectedUser.asData?.value,
              selectedUserLoading: selectedUser.isLoading,
              availableCount: availableCount,
            ),
            const SizedBox(height: AppTheme.cardGap),
            const BackendHealthBanner(),
            const SizedBox(height: AppTheme.cardGap),
            currentUserWidget,
            SizedBox(height: AppTheme.sectionSpacing(compact: true)),
            _PickerSectionLabel(
              title: 'Available profiles',
              accentColor: _pickerLavender,
              countText: availableCount == null ? null : '$availableCount',
            ),
            SizedBox(height: AppTheme.listSpacing(compact: true)),
            ...availableUserWidgets,
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

  static String _errorMessage(Object error) {
    if (error is ApiError) {
      return error.message;
    }

    return 'Unable to load dev users right now.';
  }
}

class _DeveloperIntroCard extends StatelessWidget {
  const _DeveloperIntroCard({
    required this.selectedUser,
    required this.selectedUserLoading,
    required this.availableCount,
  });

  final UserSummary? selectedUser;
  final bool selectedUserLoading;
  final int? availableCount;

  @override
  Widget build(BuildContext context) {
    final selectedLabel = switch ((selectedUserLoading, selectedUser)) {
      (true, _) => 'Restoring saved profile',
      (false, null) => 'Choose a profile below',
      (false, final user?) => 'Active: ${user.name}',
    };

    return DeveloperOnlyCalloutCard(
      title: 'Development sign-in',
      description:
          'Pick a seeded profile to preview the app with. This device remembers the active dev profile between launches until you switch it again.',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _DeveloperStatusPill(
            icon: selectedUserLoading
                ? Icons.sync_rounded
                : Icons.person_outline_rounded,
            label: selectedLabel,
          ),
          if (availableCount != null)
            _DeveloperStatusPill(
              icon: Icons.group_outlined,
              label: availableCount == 1
                  ? '1 seeded profile'
                  : '$availableCount seeded profiles',
            ),
        ],
      ),
    );
  }
}

class _DeveloperStatusPill extends StatelessWidget {
  const _DeveloperStatusPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.68),
        borderRadius: AppTheme.chipRadius,
        border: Border.all(
          color: const Color(0xFFE7C35C).withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF946200)),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: const Color(0xFF6E4E0D),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerSectionLabel extends StatelessWidget {
  const _PickerSectionLabel({
    required this.title,
    required this.accentColor,
    this.countText,
  });

  final String title;
  final Color accentColor;
  final String? countText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 3,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.85),
              borderRadius: const BorderRadius.all(Radius.circular(999)),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (countText != null) ...[
            const SizedBox(width: 8),
            Align(
              alignment: Alignment.center,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: accentColor.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.18 : 0.08,
                  ),
                  borderRadius: AppTheme.chipRadius,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  child: Text(
                    countText!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                height: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailableUsersEmptyState extends StatelessWidget {
  const _AvailableUsersEmptyState({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: Color.alphaBlend(
          _pickerSky.withValues(alpha: isDark ? 0.08 : 0.03),
          Color.alphaBlend(
            _pickerLavender.withValues(alpha: isDark ? 0.12 : 0.05),
            colorScheme.surfaceContainerLow,
          ),
        ),
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(compact: true),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: _pickerLavender.withValues(alpha: isDark ? 0.22 : 0.12),
                borderRadius: const BorderRadius.all(Radius.circular(14)),
              ),
              child: SizedBox.square(
                dimension: 44,
                child: Icon(
                  Icons.group_off_rounded,
                  color: isDark ? const Color(0xFFD8CCFF) : _pickerLavender,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No seeded dev users found',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Confirm the seed task ran or check the backend health banner above, then refresh the list.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh dev users'),
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

class _CurrentUserCard extends StatelessWidget {
  const _CurrentUserCard({this.user}) : loading = false;

  const _CurrentUserCard.loading() : user = null, loading = true;

  final UserSummary? user;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final hasUser = user != null;
    final accentColor = loading
        ? _pickerSky
        : hasUser
        ? _pickerMint
        : _pickerLavender;
    final surfaceColor = Color.alphaBlend(
      accentColor.withValues(alpha: isDark ? 0.14 : 0.06),
      colorScheme.surfaceContainerLow,
    );
    final title = loading
        ? 'Restoring selected profile'
        : hasUser
        ? user!.name
        : 'No profile selected';
    final summary = loading
        ? 'Checking for the saved dev profile on this device.'
        : hasUser
        ? 'Age ${user!.age} • ${formatDisplayLabel(user!.state)} profile'
        : 'Choose one below to jump straight into the app. Your selection stays saved on this device.';

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(context, color: surfaceColor),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 62,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.82),
                borderRadius: const BorderRadius.all(Radius.circular(999)),
              ),
            ),
            const SizedBox(width: 12),
            if (loading)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.all(Radius.circular(14)),
                ),
                child: SizedBox.square(
                  dimension: 48,
                  child: Center(
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                  ),
                ),
              )
            else if (hasUser)
              UserAvatar(name: user!.name, radius: 24)
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.all(Radius.circular(14)),
                ),
                child: SizedBox.square(
                  dimension: 48,
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: accentColor,
                    size: 24,
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      _SelectionPill(
                        label: hasUser
                            ? 'Current'
                            : (loading ? 'Loading' : 'No selection'),
                        color: accentColor,
                        icon: hasUser
                            ? Icons.check_circle_rounded
                            : (loading
                                  ? Icons.sync_rounded
                                  : Icons.radio_button_unchecked_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    summary,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: hasUser || loading
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (hasUser) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Used for the next app launch until you switch again.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionPill extends StatelessWidget {
  const _SelectionPill({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppTheme.chipRadius,
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = isSelected ? _pickerMint : _pickerLavender;
    final stateColor = user.state.toLowerCase() == 'active'
        ? AppTheme.activeColor(context)
        : _pickerSky;
    final surfaceColor = Color.alphaBlend(
      accentColor.withValues(alpha: isDark ? 0.12 : 0.045),
      colorScheme.surfaceContainerLow,
    );

    return Material(
      color: Colors.transparent,
      borderRadius: AppTheme.cardRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onSelect,
        borderRadius: AppTheme.cardRadius,
        child: Ink(
          decoration: AppTheme.surfaceDecoration(context, color: surfaceColor),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 62,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(
                      alpha: isSelected ? 0.82 : 0.5,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(999)),
                  ),
                ),
                const SizedBox(width: 12),
                UserAvatar(name: user.name, radius: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isSelected)
                            const _SelectionPill(
                              label: 'Current',
                              color: _pickerMint,
                              icon: Icons.check_circle_rounded,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Age ${user.age} • ${formatDisplayLabel(user.state)} profile',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _SelectionPill(
                            label: formatDisplayLabel(user.state),
                            color: stateColor,
                            icon: Icons.person_outline_rounded,
                          ),
                          const Spacer(),
                          Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.chevron_right_rounded,
                            size: isSelected ? 18 : 20,
                            color: isSelected
                                ? accentColor
                                : colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ],
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
