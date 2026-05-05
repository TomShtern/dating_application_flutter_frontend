import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/discovery_preferences.dart';
import '../../models/profile_update_response.dart';
import '../profile/profile_provider.dart';
import 'browse_provider.dart';
import 'pending_likers_provider.dart';
import 'standouts_provider.dart';

final discoveryPreferencesProvider = FutureProvider<DiscoveryPreferences>((
  ref,
) async {
  final snapshot = await ref.watch(profileEditSnapshotProvider.future);
  return DiscoveryPreferences.fromProfileEditSnapshot(snapshot);
});

final discoveryPreferencesControllerProvider =
    Provider<DiscoveryPreferencesController>((ref) {
      return DiscoveryPreferencesController(ref);
    });

class DiscoveryPreferencesController {
  DiscoveryPreferencesController(this._ref);

  final Ref _ref;

  Future<ProfileUpdateResponse> save(DiscoveryPreferences preferences) async {
    final response = await _ref
        .read(profileControllerProvider)
        .updateProfile(preferences.toProfileUpdateRequest());

    _ref.invalidate(browseProvider);
    _ref.invalidate(standoutsProvider);
    _ref.invalidate(pendingLikersProvider);
    _ref.invalidate(discoveryPreferencesProvider);

    return response;
  }

  void refresh() {
    _ref.invalidate(discoveryPreferencesProvider);
  }
}
