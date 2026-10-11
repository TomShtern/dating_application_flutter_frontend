class ReportResult {
  const ReportResult({
    required this.success,
    required this.autoFlagged,
    required this.blockedByReporter,
    this.errorMessage,
  });

  final bool success;

  /// This report took the target to the report threshold: the account is now
  /// under review. It is not banned.
  final bool autoFlagged;

  final bool blockedByReporter;
  final String? errorMessage;

  factory ReportResult.fromJson(Map<String, dynamic> json) {
    return ReportResult(
      success: json['success'] as bool? ?? true,
      // `autoBanned` is the deprecated alias older backends still send.
      autoFlagged:
          json['autoFlagged'] as bool? ?? json['autoBanned'] as bool? ?? false,
      blockedByReporter: json['blockedByReporter'] as bool? ?? false,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}
