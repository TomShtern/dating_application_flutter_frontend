class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.profileCompletionState,
  });

  final String id;
  final String email;
  final String? displayName;
  final String profileCompletionState;

  bool get isProfileComplete => profileCompletionState == 'complete';

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.trim().isEmpty) {
      throw const FormatException('AuthUser is missing a non-empty id.');
    }
    final email = json['email'];
    if (email is! String || email.trim().isEmpty) {
      throw const FormatException('AuthUser is missing a non-empty email.');
    }
    return AuthUser(
      id: id,
      email: email,
      displayName: json['displayName'] as String?,
      profileCompletionState:
          json['profileCompletionState'] as String? ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'profileCompletionState': profileCompletionState,
    };
  }

  AuthUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? profileCompletionState,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      profileCompletionState:
          profileCompletionState ?? this.profileCompletionState,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthUser &&
        other.id == id &&
        other.email == email &&
        other.displayName == displayName &&
        other.profileCompletionState == profileCompletionState;
  }

  @override
  int get hashCode =>
      Object.hash(id, email, displayName, profileCompletionState);
}