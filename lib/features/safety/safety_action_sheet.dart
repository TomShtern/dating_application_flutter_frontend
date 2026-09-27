import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../api/report_reason.dart';
import '../../shared/widgets/app_overflow_menu_button.dart';
import '../auth/selected_user_provider.dart';
import 'safety_provider.dart';

enum SafetyAction { block, unblock, report, unmatch, gracefulExit }

enum _SafetyMenuAction { open }

class SafetyActionOutcome {
  const SafetyActionOutcome({required this.action, required this.message});

  final SafetyAction action;
  final String message;

  bool get removesRelationship =>
      action == SafetyAction.block ||
      action == SafetyAction.unmatch ||
      action == SafetyAction.gracefulExit;
}

class SafetyActionsButton extends ConsumerWidget {
  const SafetyActionsButton({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    this.canUnmatch = false,
    this.tooltip = 'Safety actions',
    this.onCompleted,
  });

  final String targetUserId;
  final String targetUserName;
  final bool canUnmatch;
  final String tooltip;
  final void Function(BuildContext context, SafetyActionOutcome outcome)?
  onCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedUserState = ref.watch(selectedUserProvider);

    return selectedUserState.when(
      data: (currentUser) {
        if (currentUser == null || currentUser.id == targetUserId) {
          return const SizedBox.shrink();
        }

        return AppOverflowMenuButton<_SafetyMenuAction>(
          tooltip: tooltip,
          items: const [
            PopupMenuItem<_SafetyMenuAction>(
              value: _SafetyMenuAction.open,
              child: Text('Safety actions'),
            ),
          ],
          onSelected: (value) async {
            if (value != _SafetyMenuAction.open) {
              return;
            }

            final outcome = await showModalBottomSheet<SafetyActionOutcome>(
              context: context,
              showDragHandle: true,
              builder: (sheetContext) => SafetyActionSheet(
                targetUserId: targetUserId,
                targetUserName: targetUserName,
                canUnmatch: canUnmatch,
              ),
            );

            if (!context.mounted || outcome == null) {
              return;
            }

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(outcome.message)));
            onCompleted?.call(context, outcome);
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class SafetyActionSheet extends ConsumerStatefulWidget {
  const SafetyActionSheet({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    this.canUnmatch = false,
  });

  final String targetUserId;
  final String targetUserName;
  final bool canUnmatch;

  @override
  ConsumerState<SafetyActionSheet> createState() => _SafetyActionSheetState();
}

class _SafetyActionSheetState extends ConsumerState<SafetyActionSheet> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final selectedUserState = ref.watch(selectedUserProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return selectedUserState.when(
      data: (currentUser) {
        final isSelfTarget = currentUser?.id == widget.targetUserId;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Safety actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  isSelfTarget
                      ? 'Safety actions are unavailable for your own profile.'
                      : 'Manage your interaction with ${widget.targetUserName}.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (!isSelfTarget) ...[
                  const SizedBox(height: 16),
                  if (widget.canUnmatch) ...[
                    _ActionTile(
                      enabled: !_isSubmitting,
                      icon: Icons.waving_hand_outlined,
                      title: 'End gracefully',
                      subtitle:
                          'Close this connection kindly — they get a gentle goodbye.',
                      color: colorScheme.tertiary,
                      onTap: () => _handleAction(SafetyAction.gracefulExit),
                    ),
                    _ActionTile(
                      enabled: !_isSubmitting,
                      icon: Icons.heart_broken_outlined,
                      title: 'Unmatch',
                      subtitle:
                          'Remove the match and stop this conversation flow.',
                      color: colorScheme.error,
                      onTap: () => _handleAction(SafetyAction.unmatch),
                    ),
                  ],
                  _ActionTile(
                    enabled: !_isSubmitting,
                    icon: Icons.block_outlined,
                    title: 'Block user',
                    subtitle:
                        'Hide each other across discovery and social surfaces.',
                    color: colorScheme.error,
                    onTap: () => _handleAction(SafetyAction.block),
                  ),
                  _ActionTile(
                    enabled: !_isSubmitting,
                    icon: Icons.flag_outlined,
                    title: 'Report user',
                    subtitle: 'Send a trust and safety report to the backend.',
                    color: colorScheme.primary,
                    onTap: () => _handleAction(SafetyAction.report),
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(isSelfTarget ? 'Close' : 'Cancel'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, _) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Safety actions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Safety actions are unavailable right now.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction(SafetyAction action) async {
    if (_isSubmitting) {
      return;
    }

    if (action == SafetyAction.report) {
      await _handleReport();
      return;
    }

    final confirmed = await _confirmAction(action);
    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final controller = ref.read(safetyControllerProvider);
      final message = switch (action) {
        SafetyAction.block => await controller.blockUser(widget.targetUserId),
        SafetyAction.unblock => await controller.unblockUser(
          widget.targetUserId,
        ),
        SafetyAction.report => throw StateError('unreachable'),
        SafetyAction.unmatch => await controller.unmatchUser(
          widget.targetUserId,
        ),
        SafetyAction.gracefulExit => await controller.gracefulExit(
          widget.targetUserId,
        ),
      };

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pop(SafetyActionOutcome(action: action, message: message));
    } on ApiError catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to complete that safety action.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _handleReport() async {
    final request = await showModalBottomSheet<ReportUserRequest>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _ReportReasonSheet(
        targetUserName: widget.targetUserName,
      ),
    );

    if (request == null || !mounted) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final message = await ref
          .read(safetyControllerProvider)
          .reportUser(widget.targetUserId, request);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(
        SafetyActionOutcome(
          action: request.blockUser
              ? SafetyAction.block
              : SafetyAction.report,
          message: message,
        ),
      );
    } on ApiError catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to report that profile.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<bool> _confirmAction(SafetyAction action) async {
    final title = switch (action) {
      SafetyAction.block => 'Block ${widget.targetUserName}?',
      SafetyAction.unmatch => 'Unmatch ${widget.targetUserName}?',
      SafetyAction.unblock => 'Unblock ${widget.targetUserName}?',
      SafetyAction.report => 'Report ${widget.targetUserName}?',
      SafetyAction.gracefulExit => 'End things with ${widget.targetUserName}?',
    };
    final description = switch (action) {
      SafetyAction.block =>
        'You will stop seeing each other across the app after blocking.',
      SafetyAction.unmatch =>
        'This removes the current match and conversation access.',
      SafetyAction.unblock => 'This lets the user appear again in the app.',
      SafetyAction.report => 'A backend report will be created for review.',
      SafetyAction.gracefulExit =>
        'The connection closes kindly for both of you. This cannot be undone.',
    };

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }
}

class _ReportReasonSheet extends StatefulWidget {
  const _ReportReasonSheet({required this.targetUserName});

  final String targetUserName;

  @override
  State<_ReportReasonSheet> createState() => _ReportReasonSheetState();
}

class _ReportReasonSheetState extends State<_ReportReasonSheet> {
  ReportReason _reason = ReportReason.harassment;
  bool _blockUser = true;
  final TextEditingController _detailsController = TextEditingController();

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Report ${widget.targetUserName}?',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose a reason so moderation can review this profile. '
                'Reports are reviewed and repeated violations can lead to a ban.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text('Reason', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              RadioGroup<ReportReason>(
                groupValue: _reason,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _reason = value);
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final reason in ReportReason.values)
                      RadioListTile<ReportReason>(
                        value: reason,
                        title: Text(reason.label),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _detailsController,
                decoration: const InputDecoration(
                  labelText: 'Details (optional)',
                  hintText: 'Add anything reviewers should know',
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 4,
                maxLength: 500,
              ),
              SwitchListTile(
                value: _blockUser,
                onChanged: (value) => setState(() => _blockUser = value),
                title: Text(
                  'Also block ${widget.targetUserName}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Blocking stops contact and hides both profiles immediately.',
                ),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop(
                          ReportUserRequest(
                            reason: _reason,
                            description: _detailsController.text.trim().isEmpty
                                ? null
                                : _detailsController.text.trim(),
                            blockUser: _blockUser,
                          ),
                        );
                      },
                      child: const Text('Submit report'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.enabled,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final bool enabled;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: enabled,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: enabled ? onTap : null,
    );
  }
}
