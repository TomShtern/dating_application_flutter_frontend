import 'browse_candidate.dart';
import 'daily_pick.dart';

class BrowseResponse {
  const BrowseResponse({
    required this.candidates,
    required this.dailyPick,
    required this.dailyPickViewed,
    required this.locationMissing,
  });

  final List<BrowseCandidate> candidates;
  final DailyPick? dailyPick;
  final bool dailyPickViewed;
  final bool locationMissing;

  factory BrowseResponse.fromJson(Map<String, dynamic> json) {
    final candidatesJson = json['candidates'] as List? ?? const [];
    final dailyPickJson = json['dailyPick'];

    return BrowseResponse(
      candidates: candidatesJson
          .map(
            (item) => BrowseCandidate.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
      dailyPick: dailyPickJson is Map
          ? DailyPick.fromJson(Map<String, dynamic>.from(dailyPickJson))
          : null,
      dailyPickViewed: json['dailyPickViewed'] as bool? ?? false,
      locationMissing: json['locationMissing'] as bool? ?? false,
    );
  }
}
