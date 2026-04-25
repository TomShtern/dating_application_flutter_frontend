import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/match_quality.dart';
import '../../models/match_summary.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/compact_context_strip.dart';
import '../../shared/widgets/compact_summary_header.dart';
import '../../shared/widgets/compatibility_meter.dart';
import '../../shared/widgets/highlight_tag_row.dart';
import '../../shared/widgets/person_photo_card.dart';
import '../../theme/app_theme.dart';
import 'matches_provider.dart';

class MatchFactorsSheet extends ConsumerWidget {
  const MatchFactorsSheet({super.key, required this.match});

  final MatchSummary match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchQualityState = ref.watch(matchQualityProvider(match.matchId));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: matchQualityState.when(
          data: (matchQuality) =>
              _MatchFactorsContent(match: match, matchQuality: matchQuality),
          loading: () => const SizedBox(
            height: 280,
            child: AppAsyncState.loading(
              message: 'Loading live match-quality details…',
            ),
          ),
          error: (error, stackTrace) => SizedBox(
            height: 280,
            child: AppAsyncState.error(
              message: error is ApiError
                  ? error.message
                  : 'Unable to load match-quality details right now.',
              onRetry: () =>
                  ref.invalidate(matchQualityProvider(match.matchId)),
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchFactorsContent extends StatelessWidget {
  const _MatchFactorsContent({required this.match, required this.matchQuality});

  final MatchSummary match;
  final MatchQuality matchQuality;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const CompactSummaryHeader(
            title: 'Why we match',
            subtitle: 'Live compatibility details from the backend.',
          ),
          const SizedBox(height: 16),
          PersonPhotoCard(name: match.otherUserName, compact: true),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: AppTheme.surfaceDecoration(context),
            child: Padding(
              padding: AppTheme.sectionPadding(compact: true),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CompatibilityMeter(
                    score: matchQuality.compatibilityScore,
                    label: matchQuality.compatibilityLabel,
                    starDisplay: matchQuality.starDisplay,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      CompactContextStrip(
                        leadingIcon: Icons.sync_alt_rounded,
                        label: matchQuality.paceSyncLevel,
                      ),
                      CompactContextStrip(
                        leadingIcon: Icons.place_outlined,
                        label: _distanceLabel(matchQuality.distanceKm),
                      ),
                      CompactContextStrip(
                        leadingIcon: Icons.cake_outlined,
                        label: _ageDifferenceLabel(matchQuality.ageDifference),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (matchQuality.highlights.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Highlights', style: textTheme.titleMedium),
            const SizedBox(height: 10),
            HighlightTagRow(tags: matchQuality.highlights),
          ],
        ],
      ),
    );
  }

  String _distanceLabel(double distanceKm) {
    if (distanceKm < 0) {
      return 'Distance unavailable';
    }

    return distanceKm == distanceKm.roundToDouble()
        ? '${distanceKm.toInt()} km apart'
        : '${distanceKm.toStringAsFixed(1)} km apart';
  }

  String _ageDifferenceLabel(int ageDifference) {
    if (ageDifference == 0) {
      return 'Same age range';
    }

    final years = ageDifference.abs();
    return years == 1 ? '1 year apart' : '$years years apart';
  }
}
