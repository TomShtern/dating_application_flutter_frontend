class LikeResult {
  const LikeResult({
    required this.isMatch,
    required this.message,
    this.matchedUserName,
  });

  final bool isMatch;
  final String message;
  final String? matchedUserName;

  factory LikeResult.fromJson(Map<String, dynamic> json) {
    final matchJson = json['match'];

    return LikeResult(
      isMatch: json['isMatch'] as bool? ?? false,
      message: json['message'] as String? ?? 'Like recorded',
      matchedUserName: matchJson is Map
          ? matchJson['otherUserName'] as String?
          : null,
    );
  }
}
