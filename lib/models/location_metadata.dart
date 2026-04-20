class LocationCountry {
  const LocationCountry({
    required this.code,
    required this.name,
    required this.flagEmoji,
    required this.available,
    required this.defaultSelection,
  });

  final String code;
  final String name;
  final String flagEmoji;
  final bool available;
  final bool defaultSelection;

  factory LocationCountry.fromJson(Map<String, dynamic> json) {
    return LocationCountry(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      flagEmoji: json['flagEmoji'] as String? ?? '',
      available: json['available'] as bool? ?? false,
      defaultSelection: json['defaultSelection'] as bool? ?? false,
    );
  }
}

class LocationCity {
  const LocationCity({
    required this.name,
    required this.district,
    required this.countryCode,
    required this.priority,
  });

  final String name;
  final String district;
  final String countryCode;
  final int priority;

  factory LocationCity.fromJson(Map<String, dynamic> json) {
    return LocationCity(
      name: json['name'] as String? ?? '',
      district: json['district'] as String? ?? '',
      countryCode: json['countryCode'] as String? ?? '',
      priority: (json['priority'] as num?)?.toInt() ?? 0,
    );
  }
}

class ResolvedLocation {
  const ResolvedLocation({
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.precision,
    required this.approximate,
    required this.message,
  });

  final String label;
  final double latitude;
  final double longitude;
  final String precision;
  final bool approximate;
  final String message;

  factory ResolvedLocation.fromJson(Map<String, dynamic> json) {
    return ResolvedLocation(
      label: json['label'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      precision: json['precision'] as String? ?? '',
      approximate: json['approximate'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }
}
