class BrowseCandidate {
  const BrowseCandidate({
    required this.id,
    required this.name,
    required this.age,
    required this.state,
  });

  final String id;
  final String name;
  final int age;
  final String state;

  factory BrowseCandidate.fromJson(Map<String, dynamic> json) {
    return BrowseCandidate(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown user',
      age: (json['age'] as num?)?.toInt() ?? 0,
      state: json['state'] as String? ?? 'UNKNOWN',
    );
  }
}
