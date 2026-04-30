import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_preferences.dart';
import '../../models/user_summary.dart';
import '../../shared/formatting/display_text.dart';
import '../../shared/widgets/app_group_label.dart';
import '../../shared/widgets/developer_only_callout_card.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../theme/app_theme.dart';
import '../auth/selected_user_provider.dart';
import '../notifications/notifications_screen.dart';
import '../safety/blocked_users_screen.dart';
import '../stats/achievements_screen.dart';
import '../stats/stats_screen.dart';
import '../verification/verification_screen.dart';
import 'app_preferences_provider.dart';

const _settingsRose = Color(0xFFD95F84);
const _settingsViolet = Color(0xFF8E6DE8);
const _settingsMint = Color(0xFF16A871);
const _settingsSky = Color(0xFF188DC8);
const _settingsSlate = Color(0xFF667085);

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
          Padding(
            padding: AppTheme.screenPadding(compact: true),
            child: _SettingsIntroCard(
              currentUser: currentUser,
              selectedThemeMode: selectedThemeMode,
            ),
          ),
          Expanded(
            child: ListView(
              padding: AppTheme.shellScrollPadding(),
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
                const AppGroupLabel(
                  title: 'Quick access',
                  accentColor: _settingsSky,
                ),
                const SizedBox(height: AppTheme.cardGap),
                DecoratedBox(
                  decoration: AppTheme.surfaceDecoration(
                    context,
                    color: _settingsSurfaceColor(context, _settingsSky),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Open the essentials faster.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppTheme.cardGap),
                        Column(
                          children: [
                            _SettingsLinkTile(
                              icon: Icons.query_stats_rounded,
                              accentColor: _settingsSky,
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
                              accentColor: _settingsViolet,
                              title: 'Notifications',
                              subtitle:
                                  'Review recent activity and catch anything unread',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (context) =>
                                        const NotificationsScreen(),
                                  ),
                                );
                              },
                            ),
                            _SettingsDivider(),
                            _SettingsLinkTile(
                              icon: Icons.verified_user_outlined,
                              accentColor: _settingsMint,
                              title: 'Verification',
                              subtitle: 'Confirm your email or phone number',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (context) =>
                                        const VerificationScreen(),
                                  ),
                                );
                              },
                            ),
                            _SettingsDivider(),
                            _SettingsLinkTile(
                              icon: Icons.block_outlined,
                              accentColor: _settingsSlate,
                              title: 'Blocked users',
                              subtitle:
                                  'Review blocked profiles and make changes anytime',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (context) =>
                                        const BlockedUsersScreen(),
                                  ),
                                );
                              },
                            ),
                            _SettingsDivider(),
                            _SettingsLinkTile(
                              icon: Icons.workspace_premium_outlined,
                              accentColor: _settingsRose,
                              title: 'View achievements',
                              subtitle:
                                  'Celebrate the milestones you have already unlocked',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (context) => AchievementsScreen(
                                      currentUser: currentUser,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: AppTheme.sectionSpacing()),
                _SettingsSectionCard(
                  icon: Icons.palette_outlined,
                  accentColor: _settingsSky,
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
                          color: Color.alphaBlend(
                            _settingsSky.withValues(
                              alpha:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? 0.12
                                  : 0.05,
                            ),
                            Theme.of(context).colorScheme.surface,
                          ),
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

class _SettingsIntroCard extends StatelessWidget {
  const _SettingsIntroCard({
    required this.currentUser,
    required this.selectedThemeMode,
  });

  final UserSummary currentUser;
  final AppThemeModePreference selectedThemeMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: Color.alphaBlend(
          _settingsMint.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark
                ? 0.08
                : 0.025,
          ),
          _settingsSurfaceColor(context, _settingsSky, prominent: true),
        ),
        prominent: true,
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(compact: true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SettingsIntroPill(
                  icon: Icons.person_outline_rounded,
                  label: currentUser.name,
                  color: _settingsRose,
                ),
                _SettingsIntroPill(
                  icon: Icons.verified_user_outlined,
                  label: '${formatDisplayLabel(currentUser.state)} profile',
                  color: _settingsMint,
                ),
                _SettingsIntroPill(
                  icon: Icons.palette_outlined,
                  label: _shortThemeLabel(selectedThemeMode),
                  color: _settingsSky,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsIntroPill extends StatelessWidget {
  const _SettingsIntroPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: AppTheme.chipRadius,
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
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
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: onSwitchUser,
            icon: const Icon(Icons.switch_account_outlined, size: 18),
            label: const Text('Switch'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: _settingsSurfaceColor(context, accentColor),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SettingsIconChip(icon: icon, color: accentColor),
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
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color accentColor;
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
                _SettingsIconChip(icon: icon, color: accentColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                    color: accentColor.withValues(alpha: 0.8),
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

class _SettingsIconChip extends StatelessWidget {
  const _SettingsIconChip({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.10,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(14)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Icon(icon, color: color),
      ),
    );
  }
}

String _label(AppThemeModePreference themeMode) {
  return switch (themeMode) {
    AppThemeModePreference.system => 'System',
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

String _shortThemeLabel(AppThemeModePreference themeMode) {
  return switch (themeMode) {
    AppThemeModePreference.system => 'System theme',
    AppThemeModePreference.light => 'Light theme',
    AppThemeModePreference.dark => 'Dark theme',
  };
}

Color _settingsSurfaceColor(
  BuildContext context,
  Color accent, {
  bool prominent = false,
}) {
  final theme = Theme.of(context);
  final alpha = prominent
      ? (theme.brightness == Brightness.dark ? 0.18 : 0.06)
      : (theme.brightness == Brightness.dark ? 0.12 : 0.04);

  return Color.alphaBlend(
    accent.withValues(alpha: alpha),
    theme.colorScheme.surface,
  );
}
