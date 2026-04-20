class PendingLiker {
  const PendingLiker({
    required this.userId,
    required this.name,
    required this.age,
    required this.likedAt,
  });

  final String userId;
  final String name;
  final int age;
  final DateTime? likedAt;

  factory PendingLiker.fromJson(Map<String, dynamic> json) {
    return PendingLiker(
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown user',
      age: (json['age'] as num?)?.toInt() ?? 0,
      likedAt: DateTime.tryParse(json['likedAt'] as String? ?? ''),
    );
  }
}
