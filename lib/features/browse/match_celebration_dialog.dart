import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/widgets/person_media_thumbnail.dart';
import '../../theme/app_theme.dart';

/// Mutual-match celebration shown after a like creates a match.
///
/// The emotional peak of the product: photos of both people, a soft entrance
/// animation, confetti and haptics, and two clear next steps. The existing
/// "Message now" navigation path is preserved.
class MatchCelebrationDialog extends StatefulWidget {
  const MatchCelebrationDialog({
    super.key,
    required this.matchedUserName,
    required this.currentUserName,
    this.matchedUserPhotoUrl,
    this.currentUserPhotoUrl,
    this.onMessageNow,
  });

  final String matchedUserName;
  final String currentUserName;
  final String? matchedUserPhotoUrl;
  final String? currentUserPhotoUrl;
  final VoidCallback? onMessageNow;

  static Future<void> show(
    BuildContext context, {
    required String matchedUserName,
    required String currentUserName,
    String? matchedUserPhotoUrl,
    String? currentUserPhotoUrl,
    VoidCallback? onMessageNow,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => MatchCelebrationDialog(
        matchedUserName: matchedUserName,
        currentUserName: currentUserName,
        matchedUserPhotoUrl: matchedUserPhotoUrl,
        currentUserPhotoUrl: currentUserPhotoUrl,
        // The button closes the dialog itself before calling this.
        onMessageNow: onMessageNow,
      ),
    );
  }

  @override
  State<MatchCelebrationDialog> createState() => _MatchCelebrationDialogState();
}

class _MatchCelebrationDialogState extends State<MatchCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _scale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.72, curve: Curves.easeOutBack),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.45, curve: Curves.easeOut),
    );
    _controller.forward();
    HapticFeedback.mediumImpact();
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      HapticFeedback.lightImpact();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: DecoratedBox(
            decoration: AppTheme.surfaceDecoration(
              context,
              gradient: LinearGradient(
                colors: [
                  Color.alphaBlend(
                    AppTheme.loveRose.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.24 : 0.10,
                    ),
                    colorScheme.surface,
                  ),
                  Color.alphaBlend(
                    AppTheme.loveViolet.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.18 : 0.07,
                    ),
                    colorScheme.surface,
                  ),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              prominent: true,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _ConfettiPainter(_controller)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CelebrationBadge(theme: theme),
                      const SizedBox(height: 14),
                      Text(
                        "It's a Match!",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _CelebrationPhoto(
                            name: widget.currentUserName,
                            photoUrl: widget.currentUserPhotoUrl,
                            color: AppTheme.infoSky,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: ScaleTransition(
                              scale: _scale,
                              child: DecoratedBox(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.loveRose,
                                      AppTheme.loveViolet,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(9),
                                  child: Icon(
                                    Icons.favorite_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _CelebrationPhoto(
                            name: widget.matchedUserName,
                            photoUrl: widget.matchedUserPhotoUrl,
                            color: AppTheme.loveRose,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'You and ${widget.matchedUserName} liked each other. '
                        'Say something — great conversations start with a simple hello.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).pop();
                          widget.onMessageNow?.call();
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: const Text('Message now'),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Keep browsing'),
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

class _CelebrationBadge extends StatelessWidget {
  const _CelebrationBadge({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.loveRose.withValues(alpha: 0.14),
        borderRadius: AppTheme.chipRadius,
        border: Border.all(color: AppTheme.loveRose.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_rounded,
              size: 14,
              color: AppTheme.loveRose,
            ),
            const SizedBox(width: 6),
            Text(
              'New match',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppTheme.loveRose,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CelebrationPhoto extends StatelessWidget {
  const _CelebrationPhoto({
    required this.name,
    required this.photoUrl,
    required this.color,
  });

  final String name;
  final String? photoUrl;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, AppTheme.loveViolet],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: PersonMediaThumbnail(
          name: name,
          photoUrl: photoUrl,
          width: 84,
          height: 104,
          borderRadius: const BorderRadius.all(Radius.circular(19)),
        ),
      ),
    );
  }
}

/// Lightweight built-in confetti. Deterministic per run, no package needed.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.progress) : super(repaint: progress);

  final Animation<double> progress;

  static const List<Color> _colors = [
    AppTheme.loveRose,
    AppTheme.loveViolet,
    AppTheme.warmAmber,
    AppTheme.trustGreen,
    AppTheme.infoSky,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0) {
      return;
    }
    final eased = Curves.easeOut.transform(t.clamp(0.0, 1.0));
    final paint = Paint()..style = PaintingStyle.fill;

    for (var index = 0; index < 18; index++) {
      final angle = (index / 18) * math.pi * 2;
      final radius = size.shortestSide * (0.22 + 0.32 * eased);
      final dx = size.width / 2 + math.cos(angle) * radius * 1.15;
      final dy = size.height * 0.32 + math.sin(angle) * radius * 0.85;
      final opacity = (1 - eased).clamp(0.0, 1.0);
      paint.color = _colors[index % _colors.length].withValues(
        alpha: opacity * 0.75,
      );
      canvas.drawCircle(Offset(dx, dy), 2.6 + (index % 3) * 1.1, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => false;
}
