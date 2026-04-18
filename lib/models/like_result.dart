class LikeResult {
  const LikeResult({
    required this.isMatch,
    required this.message,
    this.matchedUserName,
    this.matchedUserId,
    this.matchId,
  });

  final bool isMatch;
  final String message;
  final String? matchedUserName;
  final String? matchedUserId;
  final String? matchId;

  factory LikeResult.fromJson(Map<String, dynamic> json) {
    final matchJson = json['match'];
    final matchMap = matchJson is Map
        ? Map<String, dynamic>.from(matchJson)
        : null;

    return LikeResult(
      isMatch: json['isMatch'] as bool? ?? false,
      message: json['message'] as String? ?? 'Like recorded',
      matchedUserName: matchMap?['otherUserName'] as String?,
      matchedUserId: matchMap?['otherUserId'] as String?,
      matchId: matchMap?['matchId'] as String?,
    );
  }
}
