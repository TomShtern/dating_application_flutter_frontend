class UserSummary {
  const UserSummary({
    required this.id,
    required this.name,
    required this.age,
    required this.state,
  });

  final String id;
  final String name;
  final int age;
  final String state;

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown user',
      age: (json['age'] as num?)?.toInt() ?? 0,
      state: json['state'] as String? ?? 'UNKNOWN',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'age': age, 'state': state};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is UserSummary &&
        other.id == id &&
        other.name == name &&
        other.age == age &&
        other.state == state;
  }

  @override
  int get hashCode => Object.hash(id, name, age, state);
}
