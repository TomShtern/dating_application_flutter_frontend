import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'app_network_image.dart';

/// Fullscreen photo viewer with pinch-to-zoom. Used for profile and browse
/// photos so users can inspect images before deciding.
class PhotoViewerScreen extends StatelessWidget {
  const PhotoViewerScreen({
    super.key,
    required this.photoUrls,
    required this.heroTagPrefix,
    this.initialIndex = 0,
    this.title,
  });

  final List<String> photoUrls;
  final String heroTagPrefix;
  final int initialIndex;
  final String? title;

  static Future<void> show(
    BuildContext context, {
    required List<String> photoUrls,
    required String heroTagPrefix,
    int initialIndex = 0,
    String? title,
  }) {
    final safeIndex = photoUrls.isEmpty
        ? 0
        : initialIndex.clamp(0, photoUrls.length - 1);
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => PhotoViewerScreen(
          photoUrls: photoUrls,
          heroTagPrefix: heroTagPrefix,
          initialIndex: safeIndex,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title ?? 'Photos'),
      ),
      body: photoUrls.isEmpty
          ? const Center(
              child: Text(
                'No photos to preview yet.',
                style: TextStyle(color: Colors.white),
              ),
            )
          : PageView.builder(
              itemCount: photoUrls.length,
              controller: PageController(initialPage: initialIndex),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 3.5,
                  child: Center(
                    child: Hero(
                      tag: '$heroTagPrefix-$index',
                      child: AppNetworkImage(
                        url: photoUrls[index],
                        fit: BoxFit.contain,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// Skeleton placeholder row shown while person lists load. Keeps first paint
/// structured instead of jumping from a spinner to dense content.
class SkeletonPersonRow extends StatelessWidget {
  const SkeletonPersonRow({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(context),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.cardPadding),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 150,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 210,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.7,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
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
