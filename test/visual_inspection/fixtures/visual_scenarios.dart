import 'package:flutter_riverpod/src/internals.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/browse/browse_provider.dart';
import 'package:flutter_dating_application_1/features/browse/pending_likers_provider.dart';
import 'package:flutter_dating_application_1/features/browse/standouts_provider.dart';
import 'package:flutter_dating_application_1/features/chat/conversation_thread_provider.dart';
import 'package:flutter_dating_application_1/features/chat/conversations_provider.dart';
import 'package:flutter_dating_application_1/features/home/backend_health_provider.dart';
import 'package:flutter_dating_application_1/features/location/location_provider.dart';
import 'package:flutter_dating_application_1/features/matches/matches_provider.dart';
import 'package:flutter_dating_application_1/features/notifications/notifications_provider.dart';
import 'package:flutter_dating_application_1/features/profile/profile_provider.dart';
import 'package:flutter_dating_application_1/features/safety/blocked_users_provider.dart';
import 'package:flutter_dating_application_1/features/stats/stats_provider.dart';
import 'package:flutter_dating_application_1/models/health_status.dart';
import 'package:flutter_dating_application_1/shared/persistence/shared_preferences_provider.dart';

export 'visual_fixture_catalog.dart';

import 'visual_fixture_catalog.dart';

final _healthStatus = HealthStatus(
  status: 'ok',
  timestamp: DateTime.parse('2026-04-23T12:00:00Z'),
);

final _healthOverride = backendHealthProvider.overrideWith(
  (ref) async => _healthStatus,
);

List<Override> devUserPickerOverrides(SharedPreferences preferences) => [
  sharedPreferencesProvider.overrideWithValue(preferences),
  _healthOverride,
  selectedUserProvider.overrideWith((ref) async => null),
  availableUsersProvider.overrideWith((ref) async => availableUsers),
];

List<Override> signedInShellOverrides(SharedPreferences preferences) => [
  sharedPreferencesProvider.overrideWithValue(preferences),
  _healthOverride,
  browseProvider.overrideWith((ref) async => browseResponse),
  matchesProvider.overrideWith((ref) async => matchesResponse),
  conversationsProvider.overrideWith((ref) async => conversations),
  profileProvider.overrideWith((ref) async => profileDetail),
  selectedUserProvider.overrideWith((ref) async => currentUser),
];

List<Override> get conversationThreadOverrides => [
  conversationThreadProvider(
    firstConversation.id,
  ).overrideWith((ref) async => conversationMessages),
];

List<Override> get standoutsOverrides => [
  standoutsProvider.overrideWith((ref) async => standoutsSnapshot),
];

List<Override> get pendingLikersOverrides => [
  pendingLikersProvider.overrideWith((ref) async => pendingLikers),
];

List<Override> get otherUserProfileOverrides => [
  otherUserProfileProvider(
    otherUserProfileDetail.id,
  ).overrideWith((ref) async => otherUserProfileDetail),
];

List<Override> get locationCompletionOverrides => [
  locationCountriesProvider.overrideWith((ref) async => locationCountries),
  locationCitySuggestionsProvider(
    const LocationCitySearchQuery(countryCode: 'IL', query: 'Tel'),
  ).overrideWith((ref) async => locationSuggestions),
];

List<Override> get statsOverrides => [
  statsProvider.overrideWith((ref) async => userStats),
];

List<Override> get achievementsOverrides => [
  achievementsProvider.overrideWith((ref) async => achievements),
];

List<Override> get blockedUsersOverrides => [
  blockedUsersProvider.overrideWith((ref) async => blockedUsers),
];

List<Override> get notificationsOverrides => [
  notificationsProvider.overrideWith((ref) async => notifications),
];

List<Override> baseSignedInOverrides(SharedPreferences preferences) => [
  sharedPreferencesProvider.overrideWithValue(preferences),
  selectedUserProvider.overrideWith((ref) async => currentUser),
];
