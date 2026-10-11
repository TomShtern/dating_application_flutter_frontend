import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

import '../../shared/persistence/shared_preferences_provider.dart';

const _lastSeenPatchKey = 'app_update.last_seen_patch';

final shorebirdUpdaterProvider = Provider<ShorebirdUpdater>(
  (ref) => ShorebirdUpdater(),
);

enum AppUpdatePhase {
  /// Debug builds and `flutter run` builds carry no Shorebird engine.
  unavailable,
  idle,
  checking,
  downloading,
  upToDate,

  /// A patch is downloaded; it takes effect the next time the app starts.
  restartRequired,
  failed,
}

class AppUpdateState {
  const AppUpdateState({
    this.phase = AppUpdatePhase.idle,
    this.currentPatch,
    this.justInstalledPatch,
  });

  final AppUpdatePhase phase;

  /// Patch number running right now; null when on the original release.
  final int? currentPatch;

  /// Set once per newly running patch so the UI can announce it, then cleared
  /// by [AppUpdateController.acknowledgeInstall].
  final int? justInstalledPatch;

  AppUpdateState copyWith({
    AppUpdatePhase? phase,
    int? currentPatch,
    int? justInstalledPatch,
    bool clearJustInstalled = false,
  }) {
    return AppUpdateState(
      phase: phase ?? this.phase,
      currentPatch: currentPatch ?? this.currentPatch,
      justInstalledPatch: clearJustInstalled
          ? null
          : (justInstalledPatch ?? this.justInstalledPatch),
    );
  }
}

final appUpdateControllerProvider =
    NotifierProvider<AppUpdateController, AppUpdateState>(
      AppUpdateController.new,
    );

class AppUpdateController extends Notifier<AppUpdateState> {
  late ShorebirdUpdater _updater;

  @override
  AppUpdateState build() {
    _updater = ref.watch(shorebirdUpdaterProvider);
    if (!_updater.isAvailable) {
      return const AppUpdateState(phase: AppUpdatePhase.unavailable);
    }
    Future<void>.microtask(_startup);
    return const AppUpdateState();
  }

  Future<void> _startup() async {
    await _announceRunningPatch();
    await checkNow();
  }

  /// Compares the running patch with the last one this device announced, so an
  /// update shows up once, on the launch where it actually took effect.
  Future<void> _announceRunningPatch() async {
    try {
      final patch = (await _updater.readCurrentPatch())?.number;
      final preferences = ref.read(sharedPreferencesProvider);
      final lastSeen = preferences.getInt(_lastSeenPatchKey) ?? 0;
      // `!=`, not `>`: patch numbers restart at 1 after each new release.
      state = state.copyWith(
        currentPatch: patch,
        justInstalledPatch: patch != null && patch != lastSeen ? patch : null,
      );
      await preferences.setInt(_lastSeenPatchKey, patch ?? 0);
    } on ReadPatchException {
      // Leave the patch unknown; the manual check still works.
    }
  }

  Future<void> checkNow() async {
    if (!_updater.isAvailable) return;
    final phase = state.phase;
    if (phase == AppUpdatePhase.checking ||
        phase == AppUpdatePhase.downloading) {
      return;
    }

    state = state.copyWith(phase: AppUpdatePhase.checking);
    try {
      final status = await _updater.checkForUpdate();
      if (status == UpdateStatus.outdated) {
        state = state.copyWith(phase: AppUpdatePhase.downloading);
        await _updater.update();
        // update() also returns normally while the engine's own startup
        // download is still running, so confirm a new patch is on disk.
        final (current, next) = await (
          _updater.readCurrentPatch(),
          _updater.readNextPatch(),
        ).wait;
        state = state.copyWith(
          phase: current?.number != next?.number
              ? AppUpdatePhase.restartRequired
              : AppUpdatePhase.upToDate,
        );
        return;
      }
      state = state.copyWith(
        phase: status == UpdateStatus.restartRequired
            ? AppUpdatePhase.restartRequired
            : AppUpdatePhase.upToDate,
      );
    } catch (_) {
      state = state.copyWith(phase: AppUpdatePhase.failed);
    }
  }

  void acknowledgeInstall() {
    state = state.copyWith(clearJustInstalled: true);
  }
}
