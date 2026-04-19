class UserStats {
  const UserStats({required this.items});

  factory UserStats.fromJson(Map<String, dynamic> json) {
    final items = <UserStatItem>[];

    void collect(String keyPath, dynamic value) {
      if (value == null) {
        return;
      }

      if (value is Map) {
        final map = Map<String, dynamic>.from(value);
        for (final entry in map.entries) {
          collect(
            keyPath.isEmpty ? entry.key : '$keyPath.${entry.key}',
            entry.value,
          );
        }
        return;
      }

      if (value is List) {
        if (value.isEmpty) {
          return;
        }

        items.add(
          UserStatItem(label: _humanizeKey(keyPath), value: _stringify(value)),
        );
        return;
      }

      items.add(
        UserStatItem(label: _humanizeKey(keyPath), value: _stringify(value)),
      );
    }

    for (final entry in json.entries) {
      collect(entry.key, entry.value);
    }

    return UserStats(items: List.unmodifiable(items));
  }

  final List<UserStatItem> items;
}

class UserStatItem {
  const UserStatItem({required this.label, required this.value});

  final String label;
  final String value;
}

String _humanizeKey(String key) {
  final dotted = key.replaceAll('.', ' ');
  final spaced = dotted.replaceAllMapped(
    RegExp(r'([a-z0-9])([A-Z])'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );
  final normalized = spaced.replaceAll('_', ' ').trim();
  if (normalized.isEmpty) {
    return 'Value';
  }

  return normalized
      .split(RegExp(r'\s+'))
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

String _stringify(dynamic value) {
  if (value is bool) {
    return value ? 'Yes' : 'No';
  }

  if (value is List) {
    return value.map(_stringify).join(', ');
  }

  return '$value';
}
