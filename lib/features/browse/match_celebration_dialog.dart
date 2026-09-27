import 'package:flutter/material.dart';

import '../../shared/widgets/user_avatar.dart';

/// Mutual-match celebration shown after a like creates a match.
/// Keeps the existing snackbar "Message now" path while adding the emotional
/// peak moment called for in the UX gaps doc (§2.1, FE-only).
class MatchCelebrationDialog extends StatelessWidget {
  const MatchCelebrationDialog({
    super.key,
    required this.matchedUserName,
    required this.currentUserName,
    this.onMessageNow,
  });

  final String matchedUserName;
  final String currentUserName;
  final VoidCallback? onMessageNow;

  static Future<void> show(
    BuildContext context, {
    required String matchedUserName,
    required String currentUserName,
    VoidCallback? onMessageNow,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => MatchCelebrationDialog(
        matchedUserName: matchedUserName,
        currentUserName: currentUserName,
        onMessageNow: onMessageNow == null
            ? null
            : () {
                Navigator.of(dialogContext).pop();
                onMessageNow();
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text("It's a Match!"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              UserAvatar(name: currentUserName, radius: 28),
              const SizedBox(width: 12),
              Icon(
                Icons.favorite_rounded,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              UserAvatar(name: matchedUserName, radius: 28),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'You and $matchedUserName liked each other. Say something — '
            'great conversations start with a simple hello.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Keep browsing'),
        ),
        FilledButton.icon(
          onPressed: () {
            if (onMessageNow != null) {
              Navigator.of(context).pop();
              onMessageNow!();
            } else {
              Navigator.of(context).pop();
            }
          },
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          label: const Text('Message now'),
        ),
      ],
    );
  }
}
