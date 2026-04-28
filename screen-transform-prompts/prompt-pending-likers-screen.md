You are a Flutter frontend engineer. Your task is to fully redesign the
PendingLikersScreen in lib/features/browse/pending_likers_screen.dart
to match the app's design language. Do not change providers, models,
navigation, or safety action logic. Only the visual/structural layer changes.

─── DESIGN LANGUAGE RULES (required reading) ────────────────────────────
• Design doc: docs/design-language.md — read it fully before writing code.
• Shared widgets: lib/shared/widgets/ — use them, never reinvent them.
• Browse/social screen archetype (§14):
    Scaffold → SafeArea → Column
      ├── ShellHero(...)                  ← outside scroll, full width
      └── Expanded → RefreshIndicator → ListView(padding: screenPadding)
• UserAvatar: circular avatar with gradient ring + monogram fallback.
  Use for person rows in lists (radius: 28 for standard list items).
• CompactContextStrip: the canonical widget for icon + label metadata rows.
  Never build a custom Row([Icon, SizedBox, Text]) for metadata.
• AppTheme.listSpacing(compact: true) between list cards.
• All spacing from AppTheme tokens. No magic numbers.
• Every tappable: Material + InkWell (clip to panelRadius). No GestureDetector.

─── WHAT IS WRONG NOW ────────────────────────────────────────────────────
1. STRUCTURAL BUG: The entire body is wrapped in
   Padding(AppTheme.screenPadding()) and then the ShellHero is the first
   child of the ListView inside that padding. This means:
   (a) The ShellHero is inset by 18px on both sides — it does not span
       the full screen width as the design language requires.
   (b) There is empty space at the very top before the hero card renders.
   Fix: The ShellHero must be outside the scroll area, at Column level.

2. PersonMediaThumbnail is used as a 72×72 circle (chipRadius = 999px
   border radius) — this is wrong. The design language says
   PersonMediaThumbnail is a rectangular thumbnail (96×128, radius 24).
   For a person list row, the correct widget is UserAvatar (circular,
   with ring and monogram fallback). Use UserAvatar(radius: 28) instead.

3. _PendingLikerMetaText is a custom widget that re-implements
   CompactContextStrip exactly. Delete it and use CompactContextStrip.

4. The "Open profile" affordance at the bottom of each card is plain
   text + chevron in a Row — no ripple, not a proper interactive element.
   Replace with TextButton.icon.

5. The summary strip (_PendingLikersSummaryStrip) shows the count as a
   plain Text string — no animation. The count should animate in with a
   count-up (TweenAnimationBuilder<int>) matching the animation system.

6. The ShellHero has no count badge in the badges list — the user cannot
   tell at a glance how many people liked them until they scroll.

─── REQUIRED CHANGES ─────────────────────────────────────────────────────

1. FIX THE SCREEN STRUCTURE.
   Remove the outer Padding(AppTheme.screenPadding()) from the body.
   Change the body to:
     body: SafeArea(
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.stretch,
         children: [
           // Hero — full width, NOT inside ListView
           _buildHero(likers, controller),
           // List — scrollable, with its own padding
           Expanded(
             child: RefreshIndicator(
               onRefresh: controller.refresh,
               child: ListView(
                 padding: AppTheme.screenPadding(),
                 children: [
                   if (likers.isNotEmpty) ...[
                     _PendingLikersSummaryStrip(waitingCount: likers.length),
                     SizedBox(height: AppTheme.sectionSpacing(compact: true)),
                   ],
                   if (likers.isEmpty)
                     AppAsyncState.empty(...)
                   else
                     ...likers.map((liker) => Padding(
                       padding: EdgeInsets.only(
                         bottom: AppTheme.listSpacing(compact: true)),
                       child: _PendingLikerCard(liker: liker),
                     )),
                 ],
               ),
             ),
           ),
         ],
       ),
     )
   The loading and error states from likersState.when() still render inside
   a Padding(screenPadding) as before, just without the ShellHero issue.
   Keep the AppBar with the refresh IconButton as-is.

2. UPDATE ShellHero.
   The ShellHero is now rendered at Column level (extracted to _buildHero).
   Add a count badge when likers are loaded:
     ShellHero(
       compact: true,
       eyebrowLabel: 'Pending likes',
       eyebrowIcon: Icons.favorite_rounded,
       title: 'People who liked you',
       description: 'Open a profile for a closer look, or refresh to see
                     new interest as it lands.',
       badges: likers.isNotEmpty
         ? [ShellHeroPill(
             icon: Icons.people_outline_rounded,
             label: '${likers.length} waiting',
           )]
         : const [],
     )

3. FIX _PendingLikerCard: replace PersonMediaThumbnail with UserAvatar.
   Change:
     PersonMediaThumbnail(
       key: ValueKey('pending-liker-media-${liker.userId}'),
       name: liker.name,
       photoUrl: photoUrl,
       width: 72,
       height: 72,
       borderRadius: AppTheme.chipRadius,
     )
   To:
     UserAvatar(
       name: liker.name,
       photoUrl: photoUrl,
       radius: 28,
     )
   Adjust crossAxisAlignment to CrossAxisAlignment.center on the outer Row
   (since UserAvatar has a consistent height vs the variable thumbnail).

4. REPLACE _PendingLikerMetaText with CompactContextStrip.
   Delete the entire _PendingLikerMetaText class.
   In _PendingLikerCard, replace its usage:
     // Instead of:
     _PendingLikerMetaText(icon: Icons.schedule_rounded, label: likedAtLabel)
     _PendingLikerMetaText(icon: Icons.location_on_outlined, label: location)
     // Use:
     CompactContextStrip(
       leadingIcon: Icons.schedule_rounded,
       label: likedAtLabel,
     )
     CompactContextStrip(
       leadingIcon: Icons.location_on_outlined,
       label: liker.approximateLocation!,
     )
   Keep the conditional guards (only show if non-null) exactly as before.
   Keep the Wrap spacing for the metadata section.

5. REPLACE the "Open profile" link with TextButton.icon.
   Change:
     Row([
       Text('Open profile', style: labelLarge primary),
       SizedBox(width: 4),
       Icon(Icons.chevron_right_rounded, color: onSurfaceVariant),
     ])
   To:
     TextButton.icon(
       onPressed: () => _openProfile(context),
       icon: const Icon(Icons.open_in_new_rounded, size: 16),
       label: const Text('Open profile'),
       style: TextButton.styleFrom(
         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
         tapTargetSize: MaterialTapTargetSize.shrinkWrap,
       ),
     )
   This is a proper interactive element with ripple.

6. ADD count-up animation to _PendingLikersSummaryStrip.
   Replace the plain countLabel Text with:
     TweenAnimationBuilder<int>(
       tween: IntTween(begin: 0, end: waitingCount),
       duration: const Duration(milliseconds: 620),
       curve: Curves.easeOutCubic,
       builder: (context, value, _) {
         final label = value == 1 ? '1 person waiting' : '$value people waiting';
         return Text(label,
           style: theme.textTheme.labelLarge?.copyWith(
             color: colorScheme.primary));
       },
     )

─── WHAT TO PRESERVE UNCHANGED ──────────────────────────────────────────
• _openProfile() navigation logic
• SafetyActionsButton placement and tooltip
• _pendingLikerLikedAtLabel() and _primaryPhotoUrl() helpers
• likedAt formatting via formatShortDate()
• All providers and controller references
• AppBar structure (empty AppBar with refresh IconButton)
• _PendingLikersSummaryStrip gradient decoration and layout
  (only the count Text → TweenAnimationBuilder changes)
• All error and loading states via AppAsyncState