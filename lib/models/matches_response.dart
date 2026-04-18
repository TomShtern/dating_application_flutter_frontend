import 'match_summary.dart';

class MatchesResponse {
  const MatchesResponse({
    required this.matches,
    required this.totalCount,
    required this.offset,
    required this.limit,
    required this.hasMore,
  });

  final List<MatchSummary> matches;
  final int totalCount;
  final int offset;
  final int limit;
  final bool hasMore;

  factory MatchesResponse.fromJson(Map<String, dynamic> json) {
    final matchesJson = json['matches'] as List? ?? const [];

    return MatchesResponse(
      matches: matchesJson
          .map(
            (item) =>
                MatchSummary.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false),
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}
