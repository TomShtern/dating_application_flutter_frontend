class UndoSwipeResult {
  const UndoSwipeResult({
    required this.success,
    required this.message,
    required this.matchDeleted,
  });

  factory UndoSwipeResult.fromJson(Map<String, dynamic> json) {
    return UndoSwipeResult(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? 'Last swipe undone.',
      matchDeleted: json['matchDeleted'] as bool? ?? false,
    );
  }

  final bool success;
  final String message;
  final bool matchDeleted;
}
