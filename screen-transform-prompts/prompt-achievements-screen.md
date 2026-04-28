Target file: lib/features/stats/achievements_screen.dart

Design reference: docs/design-language.md (data screen archetype, §7.1 section label pattern, animation principles)

Screen archetype: Data screen. The _AchievementsOverviewCard already plays the role of the hero anchor — no structural layout changes needed. Improvements are inside the list: section grouping, in-progress progress bars, status badge icon, and count-up animation.

Change 1 — Split the flat list into two grouped sections
In AchievementsScreen.build, inside the data: callback after computing unlockedCount and inProgressCount, split the list:


final unlocked = achievements.where((a) => a.isUnlocked == true).toList();
final inProgress = achievements.where((a) => a.isUnlocked == false).toList();
Replace the existing for loop with:


if (unlocked.isNotEmpty) ...[
  SizedBox(height: AppTheme.sectionSpacing(compact: true)),
  const _AchievementSectionLabel(title: 'Unlocked'),
  SizedBox(height: AppTheme.listSpacing()),
  for (var i = 0; i < unlocked.length; i++) ...[
    _AchievementCard(achievement: unlocked[i]),
    if (i != unlocked.length - 1) SizedBox(height: AppTheme.listSpacing()),
  ],
],
if (inProgress.isNotEmpty) ...[
  SizedBox(height: AppTheme.sectionSpacing()),
  const _AchievementSectionLabel(title: 'Still building'),
  SizedBox(height: AppTheme.listSpacing()),
  for (var i = 0; i < inProgress.length; i++) ...[
    _AchievementCard(achievement: inProgress[i]),
    if (i != inProgress.length - 1) SizedBox(height: AppTheme.listSpacing()),
  ],
],
Change 2 — Add _AchievementSectionLabel widget (§7.1 section label pattern)
3 px vertical accent bar + bold titleMedium w800 + fading outlineVariant horizontal rule. Add this private widget at the bottom of the file:


class _AchievementSectionLabel extends StatelessWidget {
  const _AchievementSectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.85),
            borderRadius: AppTheme.chipRadius,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.outlineVariant.withValues(alpha: 0.6),
                  colorScheme.outlineVariant.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
Change 3 — Add progress bar to _AchievementCard (in-progress only)
The achievement.progress field is a String? such as "7 / 10", "87%", or "3 / 3". Progress text should show for all achievements (unlocked and in-progress). The visual progress bar only appears for in-progress ones.

Add this top-level helper function (outside any class):


double? _parseAchievementProgressValue(String? progress) {
  if (progress == null) return null;
  final slashMatch = RegExp(r'^(\d+(?:\.\d+)?)\s*/\s*(\d+(?:\.\d+)?)$')
      .firstMatch(progress.trim());
  if (slashMatch != null) {
    final numerator = double.tryParse(slashMatch.group(1) ?? '');
    final denominator = double.tryParse(slashMatch.group(2) ?? '');
    if (numerator != null && denominator != null && denominator > 0) {
      return (numerator / denominator).clamp(0.0, 1.0);
    }
  }
  final percentMatch = RegExp(r'^(\d+(?:\.\d+)?)%$').firstMatch(progress.trim());
  if (percentMatch != null) {
    final pct = double.tryParse(percentMatch.group(1) ?? '');
    if (pct != null) return (pct / 100.0).clamp(0.0, 1.0);
  }
  return null;
}
In _AchievementCard.build, replace the existing if (achievement.progress case final progress?) ... block with:


if (achievement.progress case final progressText?) ...[
  const SizedBox(height: 8),
  Text(
    progressText,
    style: theme.textTheme.labelLarge?.copyWith(
      color: colorScheme.onSurfaceVariant,
    ),
  ),
  if (!unlocked)
    if (_parseAchievementProgressValue(progressText) case final progressValue?) ...[
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        child: LinearProgressIndicator(
          value: progressValue,
          minHeight: 6,
          backgroundColor: colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
        ),
      ),
    ],
],
The text renders for both unlocked ("3 / 3") and in-progress ("7 / 10"). The bar only appears when !unlocked.

Change 4 — Add checkmark icon to _AchievementStatusBadge for unlocked
Find _AchievementStatusBadge and update its Padding child:


child: Padding(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (unlocked) ...[
        Icon(Icons.check_rounded, size: 14, color: colorScheme.onPrimary),
        const SizedBox(width: 6),
      ],
      Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: unlocked ? colorScheme.onPrimary : colorScheme.onSurface,
        ),
      ),
    ],
  ),
),
Change 5 — Animate the overview progress percentage with TweenAnimationBuilder
In _AchievementsOverviewCard, find the static Text('${(progress * 100).round()}% complete', ...) and replace it with an animated count-up:


TweenAnimationBuilder<int>(
  tween: IntTween(begin: 0, end: (progress * 100).round()),
  duration: const Duration(milliseconds: 620),
  curve: Curves.easeOutCubic,
  builder: (context, value, _) => Text(
    '$value% complete',
    style: theme.textTheme.labelLarge?.copyWith(
      color: colorScheme.primary,
    ),
  ),
),
TweenAnimationBuilder manages its own animation lifecycle — no StatefulWidget conversion needed.

What to preserve unchanged
_AchievementsOverviewCard layout, gradient, icon, pill widgets, and the existing LinearProgressIndicator
_AchievementSummaryPill
achievementsProvider and the ref.invalidate refresh mechanism
Any achievement_detail_sheet.dart tap behaviour
AchievementSummary model