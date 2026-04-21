import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_preferences.dart';
import '../../models/user_summary.dart';
import '../../shared/formatting/display_text.dart';
import '../../shared/widgets/shell_hero.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppTheme.pagePadding,
            AppTheme.pagePadding,
            AppTheme.pagePadding,
            32,
          ),
          children: [
            _SettingsHeroCard(
              currentUser: currentUser,
              selectedThemeMode: selectedThemeMode,
              onSwitchUser: () async {
                await ref.read(selectUserControllerProvider).clearSelection();
              },
            ),
            SizedBox(height: AppTheme.sectionSpacing()),
            _SettingsSectionCard(
              icon: Icons.query_stats_rounded,
              title: 'Insights',
              subtitle:
                  'See how this profile is doing across matches and milestones.',
              child: Column(
                children: [
                  _SettingsLinkTile(
                    icon: Icons.query_stats_rounded,
                    title: 'View stats',
                    subtitle: 'See matches, chats, and activity at a glance',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              StatsScreen(currentUser: currentUser),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
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
                          (themeMode) => ButtonSegment<AppThemeModePreference>(
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
                  const SizedBox(height: 16),
                  DecoratedBox(
                    decoration: AppTheme.surfaceDecoration(
                      context,
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.84),
                      borderRadius: const BorderRadius.all(Radius.circular(24)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_description(selectedThemeMode)),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppTheme.sectionSpacing()),
            _SettingsSectionCard(
              icon: Icons.shield_outlined,
              title: 'Safety and activity',
              subtitle:
                  'Stay on top of alerts, verification, and the people you do not want to hear from.',
              child: Column(
                children: [
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
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 10),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsHeroCard extends StatelessWidget {
  const _SettingsHeroCard({
    required this.currentUser,
    required this.selectedThemeMode,
    required this.onSwitchUser,
  });

  final UserSummary currentUser;
  final AppThemeModePreference selectedThemeMode;
  final VoidCallback onSwitchUser;

  @override
  Widget build(BuildContext context) {
    return ShellHero(
      compact: true,
      eyebrowLabel: 'Current session',
      eyebrowIcon: Icons.tune_rounded,
      title: currentUser.name,
      description:
          'Adjust how the app looks on this device, review your progress, and switch to another saved profile whenever you need to.',
      badges: [
        ShellHeroPill(
          icon: Icons.verified_user_outlined,
          label: '${formatDisplayLabel(currentUser.state)} profile',
        ),
        ShellHeroPill(
          icon: Icons.cake_outlined,
          label: 'Age ${currentUser.age}',
        ),
        ShellHeroPill(
          icon: Icons.palette_outlined,
          label: _shortLabel(selectedThemeMode),
        ),
      ],
      footer: OutlinedButton.icon(
        onPressed: onSwitchUser,
        icon: const Icon(Icons.switch_account_outlined),
        label: const Text('Switch profile'),
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
        padding: const EdgeInsets.all(18),
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
            const SizedBox(height: 18),
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

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: colorScheme.surface.withValues(alpha: 0.84),
        borderRadius: const BorderRadius.all(Radius.circular(24)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(icon, color: colorScheme.primary),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
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
                    padding: EdgeInsets.all(8),
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

String _shortLabel(AppThemeModePreference themeMode) {
  return switch (themeMode) {
    AppThemeModePreference.system => 'System sync',
    AppThemeModePreference.light => 'Light mode',
    AppThemeModePreference.dark => 'Dark mode',
  };
}
