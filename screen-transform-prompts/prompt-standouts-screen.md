Target file: lib/features/browse/standouts_screen.dart

Design reference: docs/design-language.md (browse/social screen archetype, §6 ShellHero, PersonMediaThumbnail spec)

Screen archetype: Browse/social screen. The ShellHero must live outside the scroll area at Column level — identical to how browse and matches screens are structured.

Change 1 — Fix the structural layout bug (ShellHero inside padded scroll)
The entire body is currently wrapped in Padding(AppTheme.screenPadding()), which insets the ShellHero 18 px on each side. The _StandoutsHero widget (which renders a ShellHero) also lives inside the ListView. Both are wrong.

Remove the outer Padding(AppTheme.screenPadding()) from the body. The data branch of standoutsState.when(...) must be restructured as a Column:


body: SafeArea(
  child: standoutsState.when(
    data: (snapshot) => LayoutBuilder(
      builder: (context, constraints) {
        final viewMode = _resolveViewMode(constraints.maxWidth);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StandoutsHero(           // ← full-width, outside scroll
              snapshot: snapshot,
              viewMode: viewMode,
              onViewModeChanged: (next) => setState(() => _viewModeOverride = next),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppTheme.screenPadding(),   // ← padding moves here
                  children: [
                    SizedBox(height: AppTheme.sectionSpacing(compact: true)),
                    if (snapshot.standouts.isEmpty)
                      AppAsyncState.empty(
                        message: 'No standouts are ready right now. Check back soon.',
                        onRefresh: controller.refresh,
                      )
                    else if (viewMode == _StandoutsViewMode.grid)
                      _StandoutsGrid(standouts: snapshot.standouts)
                    else
                      _StandoutsList(standouts: snapshot.standouts),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
    loading: () => const AppAsyncState.loading(message: 'Loading standouts…'),
    error: (error, _) => AppAsyncState.error(
      message: error is ApiError ? error.message : 'Unable to load standouts right now.',
      onRetry: controller.refresh,
    ),
  ),
),
The loading and error branches do not need Padding — AppAsyncState handles its own centering.

Change 2 — Add eyebrowLabel and replace Chip badges with ShellHeroPill in _StandoutsHero
The ShellHero currently has no eyebrowLabel, and the badges: list uses Chip(avatar: Icon(...), label: Text(...)). Fix both:


ShellHero(
  key: const ValueKey('standouts-summary'),
  eyebrowLabel: 'Browse',
  eyebrowIcon: Icons.auto_awesome_rounded,
  title: 'Standouts',
  description: _humanizeStandoutsIntro(snapshot.message),
  compact: true,
  badges: [
    ShellHeroPill(
      icon: Icons.auto_awesome_rounded,
      label: snapshot.totalCandidates == 1
          ? '1 standout ready'
          : '${snapshot.totalCandidates} standouts ready',
    ),
    ShellHeroPill(
      icon: snapshot.fromCache ? Icons.cloud_outlined : Icons.bolt_rounded,
      label: snapshot.fromCache ? 'Cached results' : 'Fresh picks',
    ),
  ],
  footer: Column(...),  // ← keep existing footer unchanged
)
ShellHeroPill is already exported from shell_hero.dart which is already imported.

Change 3 — Replace Card with the design system's tappable surface pattern
_StandoutCard currently uses Card(clipBehavior: Clip.antiAlias) → InkWell. The design system uses DecoratedBox + Material(color: Colors.transparent) + InkWell:


@override
Widget build(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return DecoratedBox(
    key: ValueKey('standout-card-${standout.id}'),
    decoration: AppTheme.surfaceDecoration(
      context,
      color: colorScheme.surface.withValues(alpha: 0.94),
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppTheme.panelRadius,
        onTap: () => _openProfile(context),
        child: Padding(
          padding: mode == _StandoutCardMode.grid
              ? const EdgeInsets.all(12)
              : AppTheme.sectionPadding(compact: true),
          child: mode == _StandoutCardMode.grid
              ? _StandoutGridContent(standout: standout, onOpenProfile: () => _openProfile(context))
              : _StandoutListContent(standout: standout, onOpenProfile: () => _openProfile(context)),
        ),
      ),
    ),
  );
}
Change 4 — Fix PersonMediaThumbnail in list mode (circular → rectangular portrait)
In _StandoutListContent, the thumbnail is PersonMediaThumbnail(width: 64, height: 64, borderRadius: BorderRadius.all(Radius.circular(32))) — a circle. PersonMediaThumbnail is a rectangular photo widget. Apply a proper portrait size:


PersonMediaThumbnail(
  key: ValueKey('standout-media-${standout.id}'),
  name: standout.standoutUserName,
  photoUrl: _primaryPhotoUrl(standout.primaryPhotoUrl, standout.photoUrls),
  width: 80,
  height: 104,
  borderRadius: AppTheme.cardRadius,
),
Change 5 — Fix PersonMediaThumbnail in grid mode (circular → portrait)
In _StandoutGridContent, the thumbnail is PersonMediaThumbnail(width: 56, height: 56, borderRadius: BorderRadius.all(Radius.circular(28))). Replace:


Center(
  child: PersonMediaThumbnail(
    key: ValueKey('standout-media-${standout.id}'),
    name: standout.standoutUserName,
    photoUrl: _primaryPhotoUrl(standout.primaryPhotoUrl, standout.photoUrls),
    width: 80,
    height: 100,
    borderRadius: AppTheme.cardRadius,
  ),
),
Change 6 — Premium treatment for rank-#1 standout badge
In _StandoutRankBadge, all badges currently use primaryContainer. Top-ranked standouts (rank == 1) get the accent gradient:


decoration: BoxDecoration(
  gradient: standout.rank == 1 ? AppTheme.accentGradient(context) : null,
  color: standout.rank == 1 ? null : colorScheme.primaryContainer,
  borderRadius: AppTheme.chipRadius,
),
child: Padding(
  padding: EdgeInsets.symmetric(
    horizontal: compact ? 8 : 10,
    vertical: compact ? 6 : 7,
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        Icons.auto_awesome_rounded,
        size: compact ? 14 : 16,
        color: standout.rank == 1
            ? colorScheme.onPrimary
            : colorScheme.onPrimaryContainer,
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: standout.rank == 1
              ? colorScheme.onPrimary
              : colorScheme.onPrimaryContainer,
        ),
      ),
    ],
  ),
),
Change 7 — Strengthen "Open profile" CTA in list mode
FilledButton.tonalIcon is muted. Use the full filled variant:


FilledButton.icon(
  onPressed: onOpenProfile,
  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
  label: const Text('Open profile'),
),
What to preserve unchanged
_StandoutsViewMode enum and _resolveViewMode logic
_StandoutsGrid GridView.builder layout math (crossAxisCount, mainAxisExtent)
_humanizeStandoutsIntro, _humanizeStandoutReason, _standoutFreshness, _rankLabel, _standoutDisplayName helpers
standoutsProvider / standoutsControllerProvider
The ShellHero footer view-toggle content inside _StandoutsHero — only the eyebrowLabel and badges: change
Grid card layout order (rank badge → thumbnail → name → location → reason → button) — do not reorder, only resize the thumbnail