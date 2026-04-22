String formatDisplayLabel(String value, {String fallback = 'Not specified'}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return fallback;
  }

  final canonical = trimmed.toUpperCase();
  if (_labelOverrides case final overrides
      when overrides.containsKey(canonical)) {
    return overrides[canonical]!;
  }

  return trimmed
      .split(RegExp(r'[_\s]+'))
      .where((part) => part.isNotEmpty)
      .map(_capitalize)
      .join(' ');
}

String formatDisplayLabelList(
  List<String> values, {
  String fallback = 'Not specified',
}) {
  final nonEmpty = values.where((v) => v.trim().isNotEmpty).toList();
  if (nonEmpty.isEmpty) {
    return fallback;
  }

  return nonEmpty.map(formatDisplayLabel).join(', ');
}

String _capitalize(String value) {
  final lowercase = value.toLowerCase();
  return '${lowercase[0].toUpperCase()}${lowercase.substring(1)}';
}

const _labelOverrides = <String, String>{'NON_BINARY': 'Non-binary'};
