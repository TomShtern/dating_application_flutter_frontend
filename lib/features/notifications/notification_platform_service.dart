import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NotificationPermissionStatus { granted, denied, unsupported }

class NotificationChannelDefinition {
  const NotificationChannelDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.importance,
  });

  final String id;
  final String name;
  final String description;
  final Importance importance;
}

const notificationChannelDefinitions = <NotificationChannelDefinition>[
  NotificationChannelDefinition(
    id: 'messages',
    name: 'Messages',
    description: 'Conversation replies and new messages.',
    importance: Importance.high,
  ),
  NotificationChannelDefinition(
    id: 'matches_activity',
    name: 'Matches & activity',
    description: 'New matches, activity updates, and social momentum.',
    importance: Importance.high,
  ),
  NotificationChannelDefinition(
    id: 'safety_account',
    name: 'Safety & account',
    description: 'Safety, moderation, verification, and account updates.',
    importance: Importance.max,
  ),
  NotificationChannelDefinition(
    id: 'marketing_product',
    name: 'Marketing & product',
    description: 'Promotions, feature launches, and product announcements.',
    importance: Importance.defaultImportance,
  ),
];

abstract class NotificationPlatformService {
  Future<void> ensureInitialized();

  Future<NotificationPermissionStatus> getPermissionStatus();

  Future<NotificationPermissionStatus> requestPermission();
}

final notificationPlatformServiceProvider =
    Provider<NotificationPlatformService>((ref) {
      return FlutterNotificationPlatformService();
    });

final notificationPermissionStatusProvider =
    FutureProvider<NotificationPermissionStatus>((ref) async {
      final service = ref.watch(notificationPlatformServiceProvider);
      await service.ensureInitialized();
      return service.getPermissionStatus();
    });

final notificationPlatformControllerProvider =
    Provider<NotificationPlatformController>((ref) {
      return NotificationPlatformController(ref);
    });

class NotificationPlatformController {
  NotificationPlatformController(this._ref);

  final Ref _ref;

  Future<NotificationPermissionStatus> requestPermission() async {
    final service = _ref.read(notificationPlatformServiceProvider);
    await service.ensureInitialized();
    final status = await service.requestPermission();
    _ref.invalidate(notificationPermissionStatusProvider);
    return status;
  }
}

class FlutterNotificationPlatformService
    implements NotificationPlatformService {
  FlutterNotificationPlatformService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  bool _initialized = false;

  bool get _supportsAndroidNotifications {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  @override
  Future<void> ensureInitialized() async {
    if (_initialized || !_supportsAndroidNotifications) {
      return;
    }

    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _plugin.initialize(settings: settings);
      final androidPlugin = _androidPlugin;
      if (androidPlugin != null) {
        for (final definition in notificationChannelDefinitions) {
          await androidPlugin.createNotificationChannel(
            AndroidNotificationChannel(
              definition.id,
              definition.name,
              description: definition.description,
              importance: definition.importance,
            ),
          );
        }
      }
      _initialized = true;
    } on MissingPluginException {
      _initialized = false;
    } on PlatformException {
      _initialized = false;
    }
  }

  @override
  Future<NotificationPermissionStatus> getPermissionStatus() async {
    if (!_supportsAndroidNotifications) {
      return NotificationPermissionStatus.unsupported;
    }

    try {
      final enabled = await _androidPlugin?.areNotificationsEnabled();
      return enabled == true
          ? NotificationPermissionStatus.granted
          : NotificationPermissionStatus.denied;
    } on MissingPluginException {
      return NotificationPermissionStatus.unsupported;
    } on PlatformException {
      return NotificationPermissionStatus.unsupported;
    }
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    if (!_supportsAndroidNotifications) {
      return NotificationPermissionStatus.unsupported;
    }

    try {
      final granted = await _androidPlugin?.requestNotificationsPermission();
      if (granted == null) {
        return getPermissionStatus();
      }

      return granted
          ? NotificationPermissionStatus.granted
          : NotificationPermissionStatus.denied;
    } on MissingPluginException {
      return NotificationPermissionStatus.unsupported;
    } on PlatformException {
      return NotificationPermissionStatus.unsupported;
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _androidPlugin {
    return _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
  }
}
