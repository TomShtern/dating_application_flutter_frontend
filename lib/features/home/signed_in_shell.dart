import 'package:flutter/material.dart';

import '../../models/user_summary.dart';
import '../../theme/app_theme.dart';
import '../browse/browse_screen.dart';
import '../chat/conversations_screen.dart';
import '../matches/matches_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

class _ShellDestination {
  const _ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.showBadge = false,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool showBadge;
}

const _destinations = [
  _ShellDestination(
    label: 'Discover',
    icon: Icons.explore_outlined,
    selectedIcon: Icons.explore,
  ),
  _ShellDestination(
    label: 'Matches',
    icon: Icons.favorite_border_rounded,
    selectedIcon: Icons.favorite_rounded,
    showBadge: true,
  ),
  _ShellDestination(
    label: 'Chats',
    icon: Icons.chat_bubble_outline_rounded,
    selectedIcon: Icons.chat_bubble_rounded,
  ),
  _ShellDestination(
    label: 'Profile',
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
  ),
  _ShellDestination(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
  ),
];

class SignedInShell extends StatefulWidget {
  const SignedInShell({super.key, required this.currentUser});

  final UserSummary currentUser;

  @override
  State<SignedInShell> createState() => _SignedInShellState();
}

class _SignedInShellState extends State<SignedInShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pages = [
      BrowseScreen(currentUser: widget.currentUser),
      MatchesScreen(currentUser: widget.currentUser),
      ConversationsScreen(currentUser: widget.currentUser),
      const ProfileScreen.currentUser(),
      SettingsScreen(currentUser: widget.currentUser),
    ];

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.surface.withValues(alpha: 0.96),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        child: DecoratedBox(
          decoration: AppTheme.surfaceDecoration(
            context,
            gradient: LinearGradient(
              colors: [
                colorScheme.surface.withValues(alpha: 0.94),
                colorScheme.surfaceContainerLow.withValues(alpha: 0.92),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppTheme.panelRadius,
            prominent: true,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: ClipRRect(
              borderRadius: AppTheme.panelRadius,
              child: NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                destinations: _destinations
                    .map(
                      (destination) => NavigationDestination(
                        icon: _NavIcon(
                          icon: destination.icon,
                          showBadge: destination.showBadge,
                        ),
                        selectedIcon: _NavIcon(
                          icon: destination.selectedIcon,
                          showBadge: destination.showBadge,
                        ),
                        label: destination.label,
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.icon, required this.showBadge});

  final IconData icon;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (showBadge)
          Positioned(
            right: -2,
            top: -2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.matchAccent(context),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 1.5,
                ),
              ),
              child: const SizedBox(width: 9, height: 9),
            ),
          ),
      ],
    );
  }
}
