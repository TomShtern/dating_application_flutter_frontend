import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../models/location_metadata.dart';
import '../../models/profile_update_request.dart';
import '../../shared/providers/selected_user_guard.dart' as user_guard;
import '../browse/browse_provider.dart';
import '../profile/profile_provider.dart';

final locationCountriesProvider = FutureProvider<List<LocationCountry>>((
  ref,
) async {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getLocationCountries();
});

final locationCitySuggestionsProvider =
    FutureProvider.family<List<LocationCity>, LocationCitySearchQuery>((
      ref,
      query,
    ) async {
      if (query.countryCode.isEmpty || query.query.trim().length < 2) {
        return const <LocationCity>[];
      }

      final apiClient = ref.watch(apiClientProvider);
      return apiClient.getLocationCities(
        countryCode: query.countryCode,
        query: query.query.trim(),
        limit: 8,
      );
    });

final locationControllerProvider = Provider<LocationController>((ref) {
  return LocationController(ref);
});

class LocationController {
  LocationController(this._ref);

  final Ref _ref;

  Future<ResolvedLocation> resolveAndSaveProfileLocation({
    required String countryCode,
    required String cityName,
    String? zipCode,
    required bool allowApproximate,
  }) async {
    final currentUser = await user_guard.requireSelectedUser(_ref);
    final apiClient = _ref.read(apiClientProvider);

    final resolved = await apiClient.resolveLocation(
      countryCode: countryCode,
      cityName: cityName,
      zipCode: zipCode,
      allowApproximate: allowApproximate,
    );

    await apiClient.updateProfile(
      userId: currentUser.id,
      request: ProfileUpdateRequest(
        location: ProfileLocationRequest(
          countryCode: countryCode,
          cityName: cityName,
          zipCode: zipCode,
          allowApproximate: allowApproximate,
        ),
      ),
    );

    _ref.invalidate(profileProvider);
    _ref.invalidate(otherUserProfileProvider(currentUser.id));
    _ref.invalidate(browseProvider);
    return resolved;
  }
}

class LocationCitySearchQuery {
  const LocationCitySearchQuery({
    required this.countryCode,
    required this.query,
  });

  final String countryCode;
  final String query;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is LocationCitySearchQuery &&
        other.countryCode == countryCode &&
        other.query == query;
  }

  @override
  int get hashCode => Object.hash(countryCode, query);
}
