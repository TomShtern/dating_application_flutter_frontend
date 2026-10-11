/// Response of `POST /api/auth/session` (`AuthUserDto`).
///
/// [id] is the LOCAL user UUID, used in every `/api/users/{id}/...` path.
/// It is not the Clerk `user_...` id.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.profileCompletionState,
  });

  final String id;

  /// Null unless the Clerk token carries the optional `email` claim. Do not
  /// depend on it; read the email from Clerk's own user object instead.
  final String? email;
  final String? displayName;

  /// `complete`, or `needs_<first missing field>` (for example `needs_name`).
  /// A snapshot only; onboarding is driven by `missingProfileFields` from the
  /// profile update response.
  final String profileCompletionState;

  bool get isProfileComplete => profileCompletionState == 'complete';

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.trim().isEmpty) {
      throw const FormatException('AuthUser is missing a non-empty id.');
    }
    return AuthUser(
      id: id,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      profileCompletionState:
          json['profileCompletionState'] as String? ?? 'unknown',
    );
  }
}
