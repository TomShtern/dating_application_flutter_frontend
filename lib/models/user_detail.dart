class UserDetail {
  const UserDetail({
    required this.id,
    required this.name,
    required this.age,
    required this.bio,
    required this.gender,
    required this.interestedIn,
    required this.approximateLocation,
    required this.maxDistanceKm,
    required this.photoUrls,
    required this.state,
  });

  final String id;
  final String name;
  final int age;
  final String bio;
  final String gender;
  final List<String> interestedIn;
  final String approximateLocation;
  final int maxDistanceKm;
  final List<String> photoUrls;
  final String state;

  factory UserDetail.fromJson(Map<String, dynamic> json) {
    return UserDetail(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown user',
      age: (json['age'] as num?)?.toInt() ?? 0,
      bio: json['bio'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      interestedIn: (json['interestedIn'] as List<dynamic>? ?? const [])
          .whereType<Object?>()
          .map((value) => value?.toString() ?? '')
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
      approximateLocation: json['approximateLocation'] as String? ?? '',
      maxDistanceKm: (json['maxDistanceKm'] as num?)?.toInt() ?? 0,
      photoUrls: (json['photoUrls'] as List<dynamic>? ?? const [])
          .whereType<Object?>()
          .map((value) => value?.toString() ?? '')
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
      state: json['state'] as String? ?? 'UNKNOWN',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is UserDetail &&
        other.id == id &&
        other.name == name &&
        other.age == age &&
        other.bio == bio &&
        other.gender == gender &&
        _listEquals(other.interestedIn, interestedIn) &&
        other.approximateLocation == approximateLocation &&
        other.maxDistanceKm == maxDistanceKm &&
        _listEquals(other.photoUrls, photoUrls) &&
        other.state == state;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    age,
    bio,
    gender,
    Object.hashAll(interestedIn),
    approximateLocation,
    maxDistanceKm,
    Object.hashAll(photoUrls),
    state,
  );
}

bool _listEquals(List<String> left, List<String> right) {
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
