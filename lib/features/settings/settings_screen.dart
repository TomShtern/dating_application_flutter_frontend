import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_preferences.dart';
import '../../models/user_summary.dart';
import '../stats/achievements_screen.dart';
import '../stats/stats_screen.dart';
import '../auth/selected_user_provider.dart';
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
          padding: const EdgeInsets.all(24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current dev user',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currentUser.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text('Age ${currentUser.age} • ${currentUser.state}'),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () async {
                        await ref
                            .read(selectUserControllerProvider)
                            .clearSelection();
                      },
                      icon: const Icon(Icons.switch_account_outlined),
                      label: const Text('Switch user'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Insights',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Check stats and achievements that the backend already tracks for this user.',
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: const Icon(Icons.query_stats_rounded),
                      title: const Text('View stats'),
                      subtitle: const Text(
                        'Read-only progress and engagement metrics',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) =>
                                StatsScreen(currentUser: currentUser),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.workspace_premium_outlined),
                      title: const Text('View achievements'),
                      subtitle: const Text('Read-only milestone progress'),
                      trailing: const Icon(Icons.chevron_right_rounded),
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
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Appearance',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Choose how the app should look on this device.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SegmentedButton<AppThemeModePreference>(
                        segments: AppThemeModePreference.values
                            .map(
                              (themeMode) =>
                                  ButtonSegment<AppThemeModePreference>(
                                    value: themeMode,
                                    label: Text(_label(themeMode)),
                                  ),
                            )
                            .toList(),
                        selected: {selectedThemeMode},
                        onSelectionChanged: (selection) async {
                          final value = selection.first;
                          await ref
                              .read(appPreferencesControllerProvider)
                              .setThemeMode(value);
                        },
                        showSelectedIcon: false,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(_description(selectedThemeMode)),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
