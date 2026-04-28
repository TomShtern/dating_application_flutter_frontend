import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_preferences.dart';
import '../../models/user_summary.dart';
import '../../shared/formatting/display_text.dart';
import '../../shared/widgets/developer_only_callout_card.dart';
import '../../shared/widgets/shell_hero.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../theme/app_theme.dart';
import '../auth/selected_user_provider.dart';
import '../notifications/notifications_screen.dart';
import '../safety/blocked_users_screen.dart';
import '../stats/achievements_screen.dart';
import '../stats/stats_screen.dart';
import '../verification/verification_screen.dart';
import 'app_preferences_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, required this.currentUser});

  final UserSummary currentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedThemeMode = ref.watch(currentThemeModePreferenceProvider);

    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ShellHero(
            compact: true,
            eyebrowLabel: 'Account',
            title: 'Settings',
            description: 'Profile, appearance, and quick access.',
          ),
          Expanded(
            child: ListView(
              padding: AppTheme.screenPadding(),
              children: [
                _SettingsSessionCard(
                  currentUser: currentUser,
                  onSwitchUser: () async {
                    await ref
                        .read(selectUserControllerProvider)
                        .clearSelection();
                  },
                ),
                SizedBox(height: AppTheme.sectionSpacing()),
                _SettingsSectionCard(
                  icon: Icons.query_stats_rounded,
                  title: 'Quick access',
                  subtitle: 'Open the essentials faster.',
                  child: Column(
                    children: [
                      _SettingsLinkTile(
                        icon: Icons.query_stats_rounded,
                        title: 'View stats',
                        subtitle:
                            'See matches, chats, and activity at a glance',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) =>
                                  StatsScreen(currentUser: currentUser),
                            ),
                          );
                        },
                      ),
                      _SettingsDivider(),
                      _SettingsLinkTile(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                        subtitle:
                            'Review recent activity and catch anything unread',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => const NotificationsScreen(),
                            ),
                          );
                        },
                      ),
                      _SettingsDivider(),
                      _SettingsLinkTile(
                        icon: Icons.verified_user_outlined,
                        title: 'Verification',
                        subtitle: 'Confirm your email or phone number',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => const VerificationScreen(),
                            ),
                          );
                        },
                      ),
                      _SettingsDivider(),
                      _SettingsLinkTile(
                        icon: Icons.block_outlined,
                        title: 'Blocked users',
                        subtitle:
                            'Review blocked profiles and make changes anytime',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => const BlockedUsersScreen(),
                            ),
                          );
                        },
                      ),
                      _SettingsDivider(),
                      _SettingsLinkTile(
                        icon: Icons.workspace_premium_outlined,
                        title: 'View achievements',
                        subtitle:
                            'Celebrate the milestones you have already unlocked',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) =>
                                  AchievementsScreen(currentUser: currentUser),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppTheme.sectionSpacing()),
                _SettingsSectionCard(
                  icon: Icons.palette_outlined,
                  title: 'Appearance',
                  subtitle: 'Choose how the app should look on this device.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SegmentedButton<AppThemeModePreference>(
                        segments: AppThemeModePreference.values
                            .map(
                              (themeMode) =>
                                  ButtonSegment<AppThemeModePreference>(
                                    value: themeMode,
                                    label: Text(_label(themeMode)),
                                  ),
                            )
                            .toList(growable: false),
                        selected: {selectedThemeMode},
                        onSelectionChanged: (selection) async {
                          final value = selection.first;
                          await ref
                              .read(appPreferencesControllerProvider)
                              .setThemeMode(value);
                        },
                        showSelectedIcon: false,
                      ),
                      const SizedBox(height: AppTheme.cardGap),
                      DecoratedBox(
                        decoration: AppTheme.surfaceDecoration(
                          context,
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.84),
                          borderRadius: AppTheme.panelRadius,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(AppTheme.cardPadding),
                          child: Text(_description(selectedThemeMode)),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppTheme.sectionSpacing(compact: true)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSessionCard extends StatelessWidget {
  const _SettingsSessionCard({
    required this.currentUser,
    required this.onSwitchUser,
  });

  final UserSummary currentUser;
  final VoidCallback onSwitchUser;

  @override
  Widget build(BuildContext context) {
    return DeveloperOnlyCalloutCard(
      title: 'Current dev session',
      description:
          'This quick switcher is temporary internal tooling for previewing the app with seeded profiles on this device.',
      actions: [
        OutlinedButton.icon(
          onPressed: onSwitchUser,
          icon: const Icon(Icons.switch_account_outlined),
          label: const Text('Switch profile'),
        ),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          UserAvatar(name: currentUser.name, radius: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentUser.name,
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatDisplayLabel(currentUser.state)} profile · Age ${currentUser.age}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionCard extends StatelessWidget {
  const _SettingsSectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: colorScheme.surface.withValues(alpha: 0.9),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(icon, color: colorScheme.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.cardGap),
            child,
          ],
        ),
      ),
    );
  }
}

class _SettingsLinkTile extends StatelessWidget {
  const _SettingsLinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppTheme.cardRadius,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.all(Radius.circular(14)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(9),
                    child: Icon(icon, color: colorScheme.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox.square(
                  dimension: 24,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant,
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

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: 0.4),
      ),
    );
  }
}

String _label(AppThemeModePreference themeMode) {
  return switch (themeMode) {
    AppThemeModePreference.system => 'Use system theme',
    AppThemeModePreference.light => 'Light',
    AppThemeModePreference.dark => 'Dark',
  };
}

String _description(AppThemeModePreference themeMode) {
  return switch (themeMode) {
    AppThemeModePreference.system =>
      'Follow your device setting automatically.',
    AppThemeModePreference.light => 'Always use the light appearance.',
    AppThemeModePreference.dark => 'Always use the dark appearance.',
  };
}
