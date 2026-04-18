class HealthStatus {
  HealthStatus({required this.status, required this.timestamp});

  final String status;
  final DateTime timestamp;

  bool get isHealthy => status.toLowerCase() == 'ok';

  factory HealthStatus.fromJson(Map<String, dynamic> json) {
    return HealthStatus(
      status: json['status'] as String? ?? 'unknown',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['timestamp'] as num?)?.toInt() ?? 0,
      ),
    );
  }
}
