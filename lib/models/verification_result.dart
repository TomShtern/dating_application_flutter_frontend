class VerificationStartResult {
  const VerificationStartResult({
    required this.userId,
    required this.method,
    required this.contact,
    required this.devVerificationCode,
  });

  final String userId;
  final String method;
  final String contact;
  final String devVerificationCode;

  factory VerificationStartResult.fromJson(Map<String, dynamic> json) {
    return VerificationStartResult(
      userId: json['userId'] as String? ?? '',
      method: json['method'] as String? ?? 'EMAIL',
      contact: json['contact'] as String? ?? '',
      devVerificationCode: json['devVerificationCode'] as String? ?? '',
    );
  }
}

class VerificationConfirmationResult {
  const VerificationConfirmationResult({
    required this.verified,
    required this.verifiedAt,
  });

  final bool verified;
  final DateTime? verifiedAt;

  factory VerificationConfirmationResult.fromJson(Map<String, dynamic> json) {
    return VerificationConfirmationResult(
      verified: json['verified'] as bool? ?? false,
      verifiedAt: DateTime.tryParse(json['verifiedAt'] as String? ?? ''),
    );
  }
}
