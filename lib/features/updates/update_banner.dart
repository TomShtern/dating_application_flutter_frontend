import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import 'app_release_provider.dart';
import 'app_update_provider.dart';

/// Downloads the release inside the app and opens Android's installer. If
/// that fails, offers the browser instead. Used by the banner and Settings.
Future<void> startReleaseInstall(
  BuildContext context,
  WidgetRef ref,
  AppRelease release,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final opener = ref.read(releaseOpenerProvider);
  final installing = await ref
      .read(releaseDownloadProvider.notifier)
      .run(release);
  if (installing) return;
  messenger.showSnackBar(
    SnackBar(
      content: const Text('Couldn’t install the update.'),
      action: SnackBarAction(
        label: 'Use browser',
        onPressed: () async {
          if (await opener(release)) return;
          messenger.showSnackBar(
            const SnackBar(content: Text('Couldn’t open the download link.')),
          );
        },
      ),
    ),
  );
}

/// Restarts the app so a downloaded patch starts. If the restart can't be
/// started, says how to do it by hand: an Android app keeps running after
/// Back, so the patch only starts once the app is closed completely.
Future<void> restartForPatch(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  if (await ref.read(appRestarterProvider)()) return;
  messenger.showSnackBar(
    const SnackBar(
      content: Text(
        'Couldn’t restart. Close the app completely and open it again to '
        'finish.',
      ),
    ),
  );
}

/// What the banner and Settings say while a release downloads. The percent
/// stays at zero when the server doesn't say how big the file is.
String releaseDownloadSummary(int percent) =>
    percent == 0 ? 'Downloading…' : 'Downloading… $percent%';

/// Offers a newer build, or says a downloaded patch is waiting for a restart,
/// as a card above the navigation bar. A full build wins over a patch, since
/// installing it replaces the patch anyway. Takes no space when there is
/// nothing to offer, while the check runs, or after it's dismissed.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final release = ref.watch(availableReleaseProvider).value;
    final patchReady =
        ref.watch(appUpdateControllerProvider).phase ==
        AppUpdatePhase.restartRequired;
    final dismissed = ref.watch(updateDismissedProvider);

    final Widget child;
    if (dismissed || (release == null && !patchReady)) {
      child = const SizedBox(width: double.infinity);
    } else if (release != null) {
      final percent = ref.watch(releaseDownloadProvider);
      final version = 'Version ${release.versionName}';
      child = _UpdateBannerCard(
        icon: Icons.system_update_rounded,
        title: 'Update available',
        summary: percent != null
            ? releaseDownloadSummary(percent)
            : release.notes == null
            ? version
            : '$version · ${release.notes}',
        action: 'Update',
        // Off while a download is running.
        onAction: percent == null
            ? () => startReleaseInstall(context, ref, release)
            : null,
      );
    } else {
      child = _UpdateBannerCard(
        icon: Icons.restart_alt_rounded,
        title: 'Update ready',
        summary: 'Restart to finish the update.',
        action: 'Restart',
        onAction: () => restartForPatch(context, ref),
      );
    }

    return AnimatedSize(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: Alignment.bottomCenter,
      child: child,
    );
  }
}

/// Puts [UpdateBanner] under a screen that has no navigation bar to carry it
/// (sign-in, onboarding), so an update that fixes those screens can be taken
/// from them.
class UpdateBannerHost extends StatelessWidget {
  const UpdateBannerHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Expanded(
            // The banner row below keeps clear of the system bar instead.
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: child,
            ),
          ),
          const SafeArea(
            top: false,
            minimum: EdgeInsets.symmetric(horizontal: 10),
            child: UpdateBanner(),
          ),
        ],
      ),
    );
  }
}

class _UpdateBannerCard extends ConsumerWidget {
  const _UpdateBannerCard({
    required this.icon,
    required this.title,
    required this.summary,
    required this.action,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String summary;
  final String action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      container: true,
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: DecoratedBox(
          decoration: AppTheme.surfaceDecoration(
            context,
            color: colorScheme.surfaceContainerHigh,
            borderRadius: AppTheme.panelRadius,
            prominent: true,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
              child: Row(
                children: [
                  Icon(icon, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: theme.textTheme.titleSmall),
                        Text(
                          summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: onAction, child: Text(action)),
                  IconButton(
                    tooltip: 'Dismiss',
                    icon: const Icon(Icons.close_rounded),
                    color: colorScheme.onSurfaceVariant,
                    onPressed: ref
                        .read(updateDismissedProvider.notifier)
                        .dismiss,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
