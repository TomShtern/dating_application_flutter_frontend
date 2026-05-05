import 'profile_edit_snapshot.dart';
import 'profile_update_request.dart';

/// Discovery preferences surfaced as a dedicated mobile feature.
///
/// This model is logically separate from the general profile edit surface,
/// but it is persisted through the existing profile update endpoint because
/// the backend does not yet expose a dedicated discovery-preferences resource.
class DiscoveryPreferences {
  const DiscoveryPreferences({
    this.minAge,
    this.maxAge,
    this.maxDistanceKm,
    this.interestedIn = const <String>[],
    this.dealbreakers = const ProfileEditDealbreakers(
      acceptableSmoking: <String>[],
      acceptableDrinking: <String>[],
      acceptableKidsStance: <String>[],
      acceptableLookingFor: <String>[],
      acceptableEducation: <String>[],
    ),
  });

  final int? minAge;
  final int? maxAge;
  final int? maxDistanceKm;
  final List<String> interestedIn;
  final ProfileEditDealbreakers dealbreakers;

  factory DiscoveryPreferences.fromProfileEditSnapshot(
    ProfileEditSnapshot snapshot,
  ) {
    final editable = snapshot.editable;
    return DiscoveryPreferences(
      minAge: editable.minAge,
      maxAge: editable.maxAge,
      maxDistanceKm: editable.maxDistanceKm,
      interestedIn: List<String>.of(editable.interestedIn),
      dealbreakers: editable.dealbreakers,
    );
  }

  ProfileUpdateRequest toProfileUpdateRequest() {
    return ProfileUpdateRequest(
      minAge: minAge,
      maxAge: maxAge,
      maxDistanceKm: maxDistanceKm,
      interestedIn: interestedIn.isEmpty ? null : List<String>.of(interestedIn),
      dealbreakers: dealbreakers,
    );
  }

  DiscoveryPreferences copyWith({
    int? minAge,
    int? maxAge,
    int? maxDistanceKm,
    List<String>? interestedIn,
    ProfileEditDealbreakers? dealbreakers,
  }) {
    return DiscoveryPreferences(
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      interestedIn: interestedIn ?? this.interestedIn,
      dealbreakers: dealbreakers ?? this.dealbreakers,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is DiscoveryPreferences &&
        other.minAge == minAge &&
        other.maxAge == maxAge &&
        other.maxDistanceKm == maxDistanceKm &&
        _listEquals(other.interestedIn, interestedIn) &&
        other.dealbreakers == dealbreakers;
  }

  @override
  int get hashCode => Object.hash(
    minAge,
    maxAge,
    maxDistanceKm,
    Object.hashAll(interestedIn),
    dealbreakers,
  );
}

bool _listEquals(List<String> left, List<String> right) {
  if (identical(left, right)) {
    return true;
  }

  if (left.length != right.length) {
    return false;
  }

  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }

  return true;
}
