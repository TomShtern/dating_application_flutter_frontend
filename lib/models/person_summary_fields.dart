List<String> parseStringList(Object? raw) {
  return (raw as List<dynamic>? ?? const [])
      .whereType<Object?>()
      .map((value) => value?.toString() ?? '')
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
}

String? parseNullableString(Object? raw) {
  if (raw == null) {
    return null;
  }

  final value = raw.toString();
  return value.isEmpty ? null : value;
}
