import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_summary.dart';
import '../../theme/app_theme.dart';
import '../browse/browse_screen.dart';
import '../chat/conversations_provider.dart';
import '../chat/conversations_screen.dart';
import '../matches/matches_provider.dart';
import '../matches/matches_screen.dart';
import '../notifications/notifications_provider.dart';
import '../presence/presence_provider.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import '../browse/pending_likers_provider.dart';
import '../updates/app_update_provider.dart';
import '../updates/update_banner.dart';

class _ShellDestination {
  const _ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.showBadge = false,
    this.badgeCount = 0,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool showBadge;
  final int badgeCount;
}

class SignedInShell extends ConsumerStatefulWidget {
  const SignedInShell({super.key, required this.currentUser});

  final UserSummary currentUser;

  @override
  ConsumerState<SignedInShell> createState() => _SignedInShellState();
}

class _SignedInShellState extends ConsumerState<SignedInShell> {
  int _selectedIndex = 0;

  bool _hasFreshMatch() {
    final matches = ref.watch(matchesProvider).value;
    if (matches == null) {
      return false;
    }

    final now = DateTime.now();
    return matches.matches.any(
      (match) => now.difference(match.createdAt) < const Duration(hours: 24),
    );
  }

  int _unreadChatCount() {
    final conversations = ref.watch(conversationsProvider).value;
    if (conversations == null) {
      return 0;
    }

    // An archived chat stays archived when a message arrives, so it must not
    // light the badge either.
    return conversations
        .where((conversation) => !conversation.archived)
        .fold<int>(
          0,
          (total, conversation) => total + conversation.unreadCount,
        );
  }

  int _pendingLikerCount() {
    return ref.watch(pendingLikersProvider).value?.length ?? 0;
  }

  int _unreadNotificationCount() {
    return ref.watch(notificationsUnreadCountProvider).value ?? 0;
  }

  /// A downloaded patch is offered by [UpdateBanner]; this only confirms the
  /// one that just started running.
  void _announceUpdate(AppUpdateState? previous, AppUpdateState next) {
    final installed = next.justInstalledPatch;
    if (installed == null) {
      return;
    }
    ref.read(appUpdateControllerProvider.notifier).acknowledgeInstall();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('App updated. Now running update $installed.'),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appUpdateControllerProvider, _announceUpdate);
    // Keeps the one app-wide presence heartbeat alive while signed in.
    ref.listen(presenceControllerProvider, (previous, next) {});

    final colorScheme = Theme.of(context).colorScheme;
    final pages = [
      BrowseScreen(currentUser: widget.currentUser),
      MatchesScreen(currentUser: widget.currentUser),
      ConversationsScreen(currentUser: widget.currentUser),
      const ProfileScreen.currentUser(),
      SettingsScreen(currentUser: widget.currentUser),
    ];

    final unreadChats = _unreadChatCount();
    final likerCount = _pendingLikerCount();
    final unreadNotifications = _unreadNotificationCount();
    final destinations = [
      _ShellDestination(
        label: 'Discover',
        icon: Icons.explore_outlined,
        selectedIcon: Icons.explore,
        showBadge: likerCount > 0,
        badgeCount: likerCount,
      ),
      _ShellDestination(
        label: 'Matches',
        icon: Icons.favorite_border_rounded,
        selectedIcon: Icons.favorite_rounded,
        showBadge: _hasFreshMatch(),
      ),
      _ShellDestination(
        label: 'Chats',
        icon: Icons.chat_bubble_outline_rounded,
        selectedIcon: Icons.chat_bubble_rounded,
        showBadge: unreadChats > 0,
        badgeCount: unreadChats,
      ),
      const _ShellDestination(
        label: 'Profile',
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
      ),
      _ShellDestination(
        label: 'Settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        showBadge: unreadNotifications > 0,
        badgeCount: unreadNotifications,
      ),
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
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppTheme.contentMaxWidth(
                MediaQuery.sizeOf(context).width,
              ),
            ),
            child: IndexedStack(index: _selectedIndex, children: pages),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        child: Align(
          alignment: Alignment.bottomCenter,
          // Without this the Align fills the whole screen height and the
          // Scaffold body collapses to zero.
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppTheme.contentMaxWidth(
                MediaQuery.sizeOf(context).width,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const UpdateBanner(),
                _navigationBar(colorScheme, destinations),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navigationBar(
    ColorScheme colorScheme,
    List<_ShellDestination> destinations,
  ) {
    return DecoratedBox(
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
            destinations: destinations
                .map(
                  (destination) => NavigationDestination(
                    icon: _NavIcon(
                      icon: destination.icon,
                      showBadge: destination.showBadge,
                      badgeCount: destination.badgeCount,
                    ),
                    selectedIcon: _NavIcon(
                      icon: destination.selectedIcon,
                      showBadge: destination.showBadge,
                      badgeCount: destination.badgeCount,
                    ),
                    label: destination.label,
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.showBadge,
    this.badgeCount = 0,
  });

  final IconData icon;
  final bool showBadge;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (showBadge && badgeCount > 0)
          Positioned(
            right: -8,
            top: -5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.matchAccent(context),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          )
        else if (showBadge)
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
