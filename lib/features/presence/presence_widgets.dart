import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_presence.dart';
import '../../theme/app_theme.dart';
import 'presence_provider.dart';

/// Rebuilds with the last known presence of [userId] and keeps it polled only
/// while this widget is really on screen: its tab is the selected one and its
/// route is on top. Presence is null whenever it is unknown or failed to load.
class PresenceObserver extends ConsumerStatefulWidget {
  const PresenceObserver({
    super.key,
    required this.userId,
    this.conversationId,
    required this.builder,
  });

  final String userId;

  /// Set by the open chat, using the id the conversations API returned. It
  /// switches on fast polling and the typing flag.
  final String? conversationId;
  final Widget Function(BuildContext context, UserPresence? presence) builder;

  @override
  ConsumerState<PresenceObserver> createState() => _PresenceObserverState();
}

class _PresenceObserverState extends ConsumerState<PresenceObserver> {
  PresenceController? _controller;
  PresenceWatch? _watch;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncWatch();
  }

  @override
  void didUpdateWidget(covariant PresenceObserver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.conversationId != widget.conversationId) {
      _stopWatching();
      _syncWatch();
    }
  }

  @override
  void dispose() {
    _stopWatching();
    super.dispose();
  }

  void _syncWatch() {
    final onScreen =
        Visibility.of(context) && (ModalRoute.isCurrentOf(context) ?? true);
    if (!onScreen) {
      _stopWatching();
      return;
    }
    if (_watch != null) {
      return;
    }

    final controller = ref.read(presenceControllerProvider.notifier);
    _controller = controller;
    _watch = controller.watch(
      widget.userId,
      conversationId: widget.conversationId,
    );
  }

  void _stopWatching() {
    final watch = _watch;
    if (watch != null) {
      _controller?.unwatch(watch);
    }
    _watch = null;
    _controller = null;
  }

  @override
  Widget build(BuildContext context) {
    final presence = ref.watch(
      presenceControllerProvider.select((all) => all[widget.userId]),
    );

    return widget.builder(context, _watch == null ? null : presence);
  }
}

/// Small "online" dot for an avatar in a list row. Draws nothing unless the
/// user is ONLINE.
class PresenceDot extends StatelessWidget {
  const PresenceDot({super.key, required this.userId, this.size = 10});

  final String userId;
  final double size;

  @override
  Widget build(BuildContext context) {
    return PresenceObserver(
      userId: userId,
      builder: (context, presence) {
        if (presence?.status != PresenceStatus.online) {
          return const SizedBox.shrink();
        }

        return Semantics(
          label: 'Online',
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.activeColor(context),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 2,
              ),
            ),
            child: SizedBox.square(dimension: size),
          ),
        );
      },
    );
  }
}

/// Three dots that pulse one after another, shown next to "typing".
class TypingDots extends StatefulWidget {
  const TypingDots({super.key, required this.color});

  final Color color;

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < 3; index++)
                Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Opacity(
                    opacity: _dotOpacity(index),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox.square(dimension: 4),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  double _dotOpacity(int index) {
    final phase = (_controller.value - index * 0.2) % 1.0;
    final wave = 1 - (2 * phase - 1).abs();
    return 0.3 + 0.7 * wave;
  }
}
