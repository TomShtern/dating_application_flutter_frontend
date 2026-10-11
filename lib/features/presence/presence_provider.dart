import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../api/api_error.dart';
import '../../models/user_presence.dart';
import '../auth/selected_user_provider.dart';

/// How often the signed-in user's own heartbeat is sent, and how often the
/// presence of people in visible list rows is re-read.
const presenceHeartbeatInterval = Duration(seconds: 60);

/// How often the open chat re-reads the other person's presence and typing.
const chatPresencePollInterval = Duration(seconds: 5);

/// At most one "I am typing" call per this window.
const typingSendInterval = Duration(seconds: 5);

const _failurePause = Duration(seconds: 60);
const _rateLimitPause = Duration(seconds: 30);
const _maxRateLimitPause = Duration(minutes: 5);

/// Whether the app is in the foreground. Only `resumed` counts, matching the
/// chat thread's own refresh rule.
final appForegroundProvider = NotifierProvider<AppForegroundNotifier, bool>(
  AppForegroundNotifier.new,
);

class AppForegroundNotifier extends Notifier<bool> {
  @override
  bool build() {
    final listener = AppLifecycleListener(
      onStateChange: (lifecycle) =>
          state = lifecycle == AppLifecycleState.resumed,
    );
    ref.onDispose(listener.dispose);

    final lifecycle = WidgetsBinding.instance.lifecycleState;
    return lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }
}

/// Handle for one on-screen interest in a user's presence. A watch with a
/// [conversationId] is an open chat and is polled fast, with typing.
class PresenceWatch {
  PresenceWatch._(this.userId, this.conversationId);

  final String userId;
  final String? conversationId;
}

/// The one place presence lives: own heartbeat, typing calls, and the last
/// known presence of other users, keyed by their user id.
///
/// Presence is decoration. Every failure is swallowed here and simply removes
/// the user from the state, so screens show nothing instead of an error.
final presenceControllerProvider =
    NotifierProvider.autoDispose<PresenceController, Map<String, UserPresence>>(
      PresenceController.new,
    );

class PresenceController extends Notifier<Map<String, UserPresence>> {
  final Set<PresenceWatch> _watches = {};
  final Set<String> _inFlight = {};

  /// Users read since the last minute tick; a row scrolling back into view
  /// reuses the cached value instead of fetching again.
  final Set<String> _freshUsers = {};

  /// Users the backend refused with 403: presence is only readable for an
  /// active match. They are not asked about again until the next restart.
  final Set<String> _forbiddenUsers = {};

  String? _userId;
  bool _foreground = true;
  bool _running = false;

  /// Bumped on every stop so a response that arrives late is ignored.
  int _generation = 0;
  int _heartbeatsToSkip = 0;
  Duration _nextRateLimitPause = _rateLimitPause;

  Timer? _minuteTimer;
  Timer? _chatTimer;
  Timer? _pauseTimer;
  Timer? _typingTimer;

  @override
  Map<String, UserPresence> build() {
    final userIdProvider = selectedUserProvider.select(
      (user) => user.value?.id,
    );
    ref.listen(userIdProvider, (previous, userId) {
      _userId = userId;
      _restart();
    });
    ref.listen(appForegroundProvider, (previous, foreground) {
      _foreground = foreground;
      _restart();
    });
    ref.onDispose(() {
      _stop();
      _pauseTimer?.cancel();
    });

    _userId = ref.read(userIdProvider);
    _foreground = ref.read(appForegroundProvider);
    if (_userId != null && _foreground) {
      _start();
    }
    return const {};
  }

  /// Starts following [userId] while a widget showing them is on screen.
  PresenceWatch watch(String userId, {String? conversationId}) {
    final watch = PresenceWatch._(userId, conversationId);
    _watches.add(watch);

    if (conversationId != null) {
      _syncChatTimer();
      unawaited(_fetch(userId, conversationId: conversationId));
    } else if (!_freshUsers.contains(userId) && !_hasChatWatch(userId)) {
      unawaited(_fetch(userId));
    }
    return watch;
  }

  void unwatch(PresenceWatch watch) {
    _watches.remove(watch);
    if (watch.conversationId != null) {
      _syncChatTimer();
    }
  }

  /// Tells the backend the signed-in user is typing in [conversationId].
  /// Call it on every non-empty text change; it sends at most one request per
  /// [typingSendInterval].
  void notifyTyping(String conversationId) {
    final userId = _userId;
    if (!_running ||
        userId == null ||
        conversationId.isEmpty ||
        (_typingTimer?.isActive ?? false)) {
      return;
    }

    _typingTimer = Timer(typingSendInterval, () {});
    unawaited(_sendTyping(userId, conversationId));
  }

  void _restart() {
    _stop();
    state = const {};
    if (_userId != null && _foreground) {
      _start();
    }
  }

  void _start() {
    _running = true;
    _heartbeatsToSkip = 0;
    unawaited(_sendHeartbeat());
    _minuteTimer = Timer.periodic(presenceHeartbeatInterval, (_) {
      if (_heartbeatsToSkip > 0) {
        _heartbeatsToSkip -= 1;
      } else {
        unawaited(_sendHeartbeat());
      }
      _forgetUnwatchedUsers();
      _fetchWatchedUsers();
    });
    _syncChatTimer();
    // No state access here: this also runs from build().
    _fetchWatchedUsers();
  }

  void _stop() {
    _running = false;
    _generation += 1;
    _minuteTimer?.cancel();
    _chatTimer?.cancel();
    _typingTimer?.cancel();
    _minuteTimer = null;
    _chatTimer = null;
    _typingTimer = null;
    _inFlight.clear();
    _freshUsers.clear();
    _forbiddenUsers.clear();
  }

  void _syncChatTimer() {
    final hasChat = _watches.any((watch) => watch.conversationId != null);
    if (!_running || !hasChat) {
      _chatTimer?.cancel();
      _chatTimer = null;
      return;
    }

    _chatTimer ??= Timer.periodic(chatPresencePollInterval, (_) {
      for (final watch in _watches.toList()) {
        if (watch.conversationId != null) {
          unawaited(_fetch(watch.userId, conversationId: watch.conversationId));
        }
      }
    });
  }

  /// Drops everyone who is no longer on screen, so a stale status can never
  /// be shown later.
  void _forgetUnwatchedUsers() {
    final watched = {for (final watch in _watches) watch.userId};
    if (state.keys.any((userId) => !watched.contains(userId))) {
      state = {
        for (final entry in state.entries)
          if (watched.contains(entry.key)) entry.key: entry.value,
      };
    }
  }

  void _fetchWatchedUsers() {
    _freshUsers.clear();
    for (final watch in _watches.toList()) {
      if (watch.conversationId != null) {
        unawaited(_fetch(watch.userId, conversationId: watch.conversationId));
      } else if (!_hasChatWatch(watch.userId)) {
        unawaited(_fetch(watch.userId));
      }
    }
  }

  bool _hasChatWatch(String userId) {
    return _watches.any(
      (watch) => watch.userId == userId && watch.conversationId != null,
    );
  }

  bool get _paused => _pauseTimer?.isActive ?? false;

  Future<void> _fetch(String userId, {String? conversationId}) async {
    if (!_running ||
        _paused ||
        userId.isEmpty ||
        _forbiddenUsers.contains(userId) ||
        !_inFlight.add(userId)) {
      return;
    }

    final generation = _generation;
    try {
      final presence = await ref
          .read(apiClientProvider)
          .getPresence(userId: userId, conversationId: conversationId);
      if (generation != _generation) {
        return;
      }
      _inFlight.remove(userId);
      _nextRateLimitPause = _rateLimitPause;
      _freshUsers.add(userId);
      state = {...state, userId: presence};
    } on ApiError catch (error) {
      if (generation != _generation) {
        return;
      }
      _inFlight.remove(userId);
      _handleFetchFailure(userId, error);
    }
  }

  /// Hides what could not be read. A 403 is about that one user, so only they
  /// are dropped. Anything else stops all asking for a while: longer and
  /// longer after a 429, a fixed minute otherwise (401/404, network).
  void _handleFetchFailure(String userId, ApiError error) {
    if (error.statusCode == 403) {
      _forbiddenUsers.add(userId);
      if (state.containsKey(userId)) {
        state = {...state}..remove(userId);
      }
      return;
    }

    final Duration pause;
    if (error.statusCode == 429) {
      pause = _nextRateLimitPause;
      final doubled = _nextRateLimitPause * 2;
      _nextRateLimitPause = doubled > _maxRateLimitPause
          ? _maxRateLimitPause
          : doubled;
      state = const {};
    } else {
      pause = _failurePause;
      if (state.containsKey(userId)) {
        state = {...state}..remove(userId);
      }
    }

    _pauseTimer?.cancel();
    _pauseTimer = Timer(pause, () {});
  }

  Future<void> _sendHeartbeat() async {
    final userId = _userId;
    if (userId == null) {
      return;
    }

    final generation = _generation;
    try {
      await ref.read(apiClientProvider).sendHeartbeat(userId: userId);
    } on ApiError catch (error) {
      if (error.statusCode == 429 && generation == _generation) {
        _heartbeatsToSkip = 2;
      }
    }
  }

  Future<void> _sendTyping(String userId, String conversationId) async {
    final generation = _generation;
    try {
      await ref
          .read(apiClientProvider)
          .sendTyping(userId: userId, conversationId: conversationId);
    } on ApiError catch (error) {
      if (error.statusCode == 429 && generation == _generation) {
        _typingTimer?.cancel();
        _typingTimer = Timer(_rateLimitPause, () {});
      }
    }
  }
}
