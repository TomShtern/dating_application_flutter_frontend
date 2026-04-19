class AchievementSummary {
  const AchievementSummary({
    required this.title,
    this.subtitle,
    this.progress,
    this.isUnlocked,
  });

  factory AchievementSummary.fromJson(Map<String, dynamic> json) {
    final title =
        _firstString(json, const [
          'title',
          'name',
          'achievementName',
          'label',
          'id',
        ]) ??
        'Achievement';
    final subtitle = _firstString(json, const [
      'description',
      'details',
      'subtitle',
      'category',
    ]);
    final progressValue = json['progress'] ?? json['progressText'];
    final progress = progressValue == null ? null : '$progressValue';
    final isUnlocked = _firstBool(json, const [
      'unlocked',
      'earned',
      'completed',
    ]);

    return AchievementSummary(
      title: title,
      subtitle: subtitle,
      progress: progress,
      isUnlocked: isUnlocked,
    );
  }

  final String title;
  final String? subtitle;
  final String? progress;
  final bool? isUnlocked;

  String get statusLabel {
    return switch (isUnlocked) {
      true => 'Unlocked',
      false => 'In progress',
      null => 'Status unavailable',
    };
  }
}

String? _firstString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }

  return null;
}

bool? _firstBool(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) {
      return value;
    }
  }

  return null;
}
