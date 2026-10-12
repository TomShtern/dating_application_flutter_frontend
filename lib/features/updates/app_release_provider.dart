import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ota_update/ota_update.dart';
import 'package:url_launcher/url_launcher.dart';

/// The build number and name Flutter stamps into the app from pubspec's
/// `x.y.z+N` (or `--build-name` / `--build-number`). Zero and empty under
/// tests and `flutter run` without them: no check runs.
const installedBuildNumber = int.fromEnvironment('FLUTTER_BUILD_NUMBER');
const installedBuildName = String.fromEnvironment('FLUTTER_BUILD_NAME');

/// Where `scripts/release.ps1` publishes each full build. Every installed
/// build keeps asking this address, so keep the two equal and never move it
/// without leaving a `latest.json` behind.
final latestReleaseManifestUrl = Uri.parse(
  'https://github.com/TomShtern/dating_application_flutter_frontend'
  '/releases/latest/download/latest.json',
);

/// A full build published as an APK: the channel for changes a Shorebird patch
/// cannot carry (native code, plugins, the manifest, assets).
class AppRelease {
  const AppRelease({
    required this.versionCode,
    required this.versionName,
    required this.apkUrl,
    required this.sha256,
    this.notes,
  });

  final int versionCode;
  final String versionName;
  final Uri apkUrl;

  /// The APK's SHA-256 in hex, checked after the download.
  final String sha256;
  final String? notes;

  /// Null when the file isn't a manifest this app understands, so a bad
  /// upload hides the banner instead of crashing the app.
  static AppRelease? tryParse(Object? json) {
    if (json is! Map) return null;
    final code = json['versionCode'];
    final name = json['versionName'];
    final url = json['apkUrl'];
    final hash = json['sha256'];
    if (code is! int || name is! String || url is! String) return null;
    // Without a checksum the installer would open on whatever the server
    // answered, so a manifest without one is not accepted.
    if (hash is! String || hash.isEmpty) return null;
    final apk = Uri.tryParse(url);
    // The file behind the link gets installed, so only a real https link is
    // allowed.
    if (apk == null || apk.scheme != 'https' || apk.host.isEmpty) return null;
    final notes = json['notes'];
    return AppRelease(
      versionCode: code,
      versionName: name,
      apkUrl: apk,
      sha256: hash,
      notes: notes is String && notes.isNotEmpty ? notes : null,
    );
  }
}

/// The published release if it is newer than [installedBuild], or null when
/// this build is current. Throws when the check itself fails (offline, no file
/// yet, malformed file), so "up to date" and "couldn't check" stay apart.
Future<AppRelease?> fetchNewerRelease(
  Dio dio,
  Uri manifest,
  int installedBuild,
) async {
  final response = await dio.getUri<String>(
    manifest,
    options: Options(responseType: ResponseType.plain),
  );
  final release = AppRelease.tryParse(jsonDecode(response.data ?? ''));
  if (release == null) throw const FormatException('latest.json is malformed');
  return release.versionCode > installedBuild ? release : null;
}

/// Whether this build can look for a full release at all. Android only: the
/// APK can't be installed anywhere else. Not in debug builds: they carry the
/// debug signature, so a release APK could not install over them.
bool get releaseCheckSupported =>
    !kDebugMode &&
    !kIsWeb &&
    defaultTargetPlatform == TargetPlatform.android &&
    installedBuildNumber != 0;

/// [releaseCheckSupported] for the UI; tests and screenshots override it.
final releaseCheckSupportedProvider = Provider<bool>(
  (ref) => releaseCheckSupported,
);

/// A newer build than the one running, or null. Fails when the check couldn't
/// be made. No automatic retry: Settings says so at once and the user can ask
/// again.
final availableReleaseProvider = FutureProvider<AppRelease?>((ref) async {
  if (!ref.watch(releaseCheckSupportedProvider)) return null;
  // A plain client: the manifest is public, and the backend's secret and
  // session token must never go to another host.
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  try {
    return await fetchNewerRelease(
      dio,
      // A fresh query string skips any cached copy of an older latest.json.
      latestReleaseManifestUrl.replace(
        queryParameters: {'t': '${DateTime.now().millisecondsSinceEpoch}'},
      ),
      installedBuildNumber,
    );
  } finally {
    dio.close();
  }
}, retry: (_, _) => null);

/// Set when the banner is closed, so it stays away until the next launch or
/// the next manual check.
final updateDismissedProvider = NotifierProvider<UpdateDismissed, bool>(
  UpdateDismissed.new,
);

class UpdateDismissed extends Notifier<bool> {
  @override
  bool build() => false;

  void dismiss() => state = true;

  void reset() => state = false;
}

/// Downloads the APK inside the app and opens Android's installer on it.
/// Emits the percent downloaded and ends once the installer is open; fails
/// when the download, the checksum or the hand-over fails.
Stream<int> installRelease(AppRelease release) async* {
  // A new OtaUpdate each time: it keeps its first stream, so a second
  // download on the same one would never start.
  final events = OtaUpdate().execute(
    release.apkUrl.toString(),
    destinationFilename: 'update.apk',
    sha256checksum: release.sha256,
  );
  await for (final event in events) {
    switch (event.status) {
      case OtaStatus.DOWNLOADING:
        yield int.tryParse(event.value ?? '') ?? 0;
      case OtaStatus.INSTALLING || OtaStatus.INSTALLATION_DONE:
        return;
      // The plugin numbers its error kinds differently on the two sides, so
      // which error it was can't be trusted; the message can.
      default:
        throw StateError('Update failed: ${event.value}');
    }
  }
  throw StateError('The download ended before the installer opened.');
}

/// How the UI downloads and installs a release; replaced in tests.
final releaseInstallerProvider = Provider<Stream<int> Function(AppRelease)>(
  (ref) => installRelease,
);

/// The percent downloaded while a release is on its way to the installer,
/// null when none is.
final releaseDownloadProvider = NotifierProvider<ReleaseDownload, int?>(
  ReleaseDownload.new,
);

class ReleaseDownload extends Notifier<int?> {
  @override
  int? build() => null;

  /// Downloads [release] and opens the installer. False when that failed; a
  /// second call while one is running does nothing.
  Future<bool> run(AppRelease release) async {
    if (state != null) return true;
    state = 0;
    try {
      await for (final percent in ref.read(releaseInstallerProvider)(release)) {
        state = percent;
      }
      return true;
    } catch (error) {
      debugPrint('Could not install the update: $error');
      return false;
    } finally {
      state = null;
    }
  }
}

/// The fallback when the in-app install fails: hands the APK link to the
/// browser, which downloads the file. False when nothing could open it.
Future<bool> openReleaseInBrowser(AppRelease release) async {
  try {
    return await launchUrl(
      release.apkUrl,
      mode: LaunchMode.externalApplication,
    );
  } catch (error) {
    debugPrint('Could not open the update link: $error');
    return false;
  }
}

/// How the UI opens the download in the browser; replaced in tests.
final releaseOpenerProvider = Provider<Future<bool> Function(AppRelease)>(
  (ref) => openReleaseInBrowser,
);
