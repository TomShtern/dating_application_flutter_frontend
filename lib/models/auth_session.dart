import 'auth_user.dart';

/// The token bundle + user we received from a successful auth call.
///
/// `expiresAt` is computed from `expiresInSeconds` at receive time so
/// the client can decide locally whether the access token is stale
/// without parsing the JWT.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final AuthUser user;

  bool isExpired({Duration skew = const Duration(seconds: 30)}) {
    return DateTime.now().toUtc().isAfter(expiresAt.subtract(skew));
  }

  /// Parse the auth response shape:
  /// `{ accessToken, refreshToken, expiresInSeconds, user: {...} }`.
  factory AuthSession.fromAuthResponse(
    Map<String, dynamic> json, {
    DateTime? receivedAt,
  }) {
    final received = (receivedAt ?? DateTime.now()).toUtc();
    final accessToken = _requiredNonBlankString(
      json['accessToken'],
      'accessToken',
    );
    final refreshToken = _requiredNonBlankString(
      json['refreshToken'],
      'refreshToken',
    );
    final expiresInSeconds = _requiredPositiveInt(
      json['expiresInSeconds'],
      'expiresInSeconds',
    );
    final userJson = json['user'];
    if (userJson is! Map) {
      throw const FormatException('Auth response is missing the user payload.');
    }

    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: received.add(Duration(seconds: expiresInSeconds)),
      user: AuthUser.fromJson(Map<String, dynamic>.from(userJson)),
    );
  }

  /// Persistence shape (NOT the wire shape — wire uses expiresInSeconds).
  factory AuthSession.fromStorageJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    if (userJson is! Map) {
      throw const FormatException('Stored session is missing the user.');
    }

    return AuthSession(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      expiresAt:
          DateTime.tryParse(json['expiresAt'] as String? ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      user: AuthUser.fromJson(Map<String, dynamic>.from(userJson)),
    );
  }

  Map<String, dynamic> toStorageJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt.toUtc().toIso8601String(),
      'user': user.toJson(),
    };
  }

  AuthSession copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    AuthUser? user,
  }) {
    return AuthSession(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      user: user ?? this.user,
    );
  }

  static String _requiredNonBlankString(dynamic value, String fieldName) {
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Auth response is missing $fieldName.');
    }
    return value;
  }

  static int _requiredPositiveInt(dynamic value, String fieldName) {
    if (value is! num || !value.isFinite) {
      throw FormatException('Auth response is missing $fieldName.');
    }
    final intValue = value.toInt();
    if (intValue <= 0 || intValue != value) {
      throw FormatException('Auth response has invalid $fieldName.');
    }
    return intValue;
  }
}
