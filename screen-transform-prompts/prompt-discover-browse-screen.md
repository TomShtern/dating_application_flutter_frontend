You are a Flutter frontend engineer. Your task is to visually enhance the
BrowseScreen in lib/features/browse/browse_screen.dart.
Do not change any swipe/like/pass/undo logic, providers, or API calls.
Only the visual layer changes.

─── DESIGN LANGUAGE RULES (required reading) ────────────────────────────
• Design doc: docs/design-language.md — read it fully before writing code.
• Shared widgets: lib/shared/widgets/ — use them, never reinvent them.
• Section label pattern (§7.1): vertical 3px primary accent bar +
  bold titleMedium w800 text + fading horizontal rule.
• AppTheme.glassDecoration(context) for floating badge/pill overlays.
• Surface decorations: AppTheme.surfaceDecoration(), never raw BoxDecoration.
• All spacing from AppTheme tokens. No magic numbers.
• PersonMediaThumbnail: use for rectangular photo previews (96×128 default,
  corner radius 24). Default fallback gradient is name-based.
• Every tappable: Material + InkWell. Never GestureDetector.

─── WHAT IS WRONG NOW ────────────────────────────────────────────────────
1. ShellHero has title: '' — the hero title is empty, making the top of
   the screen look blank and wasted. The hero only shows description text
   and a single pill.
2. _DailyPickCard uses UserAvatar(radius: 22) — a 44px circle — to show
   the daily pick person. This is too small to communicate real presence.
   PersonMediaThumbnail would show the photo at much better scale.
3. _BrowsePresentationContextContent uses a plain titleSmall Text widget
   for the "Why this profile is shown" heading — should use the §7.1
   section label pattern (accent bar + bold title + horizontal rule).
4. The _CandidateCard "New for you" badge uses a raw white semi-transparent
   color overlay instead of AppTheme.glassDecoration(context).
5. The candidate count label ("3 candidate(s) ready") is a raw centered
   bodySmall text — no icon, no design system styling.
6. The _DiscoveryShortcutRow cards (Likes you / Standouts) use identical
   plain primaryContainer icon chips — both cards look the same, with no
   semantic color differentiation.

─── REQUIRED CHANGES ─────────────────────────────────────────────────────

1. FIX ShellHero title.
   In BrowseScreen.build(), change the ShellHero from:
     ShellHero(compact: true, title: '', description: '...')
   to:
     ShellHero(
       compact: true,
       title: 'Discover',
       description: 'Swipe on a profile or open it for more detail.',
       badges: [
         ShellHeroPill(
           icon: Icons.favorite_outline_rounded,
           label: 'Browsing as ${widget.currentUser.name}',
         ),
       ],
     )
   Remove the standalone badges from the old hero (they move into the hero).

2. REDESIGN _DailyPickCard person photo.
   Replace:
     UserAvatar(name: dailyPick.userName, photoUrl: ..., radius: 22)
   with:
     PersonMediaThumbnail(
       key: ValueKey('daily-pick-media-${dailyPick.userId}'),
       name: dailyPick.userName,
       photoUrl: _primaryPhotoUrl(dailyPick.primaryPhotoUrl, dailyPick.photoUrls),
       width: 72,
       height: 88,
       borderRadius: BorderRadius.all(Radius.circular(AppTheme.cardRadius)),
     )
   Adjust the Row crossAxisAlignment to CrossAxisAlignment.start.
   The name/location column beside it stays the same — just the avatar changes.

3. REDESIGN _BrowsePresentationContextContent heading.
   Replace:
     Text('Why this profile is shown', style: textTheme.titleSmall)
   with the §7.1 Section Label pattern:
     IntrinsicHeight(
       child: Row(
         crossAxisAlignment: CrossAxisAlignment.stretch,
         children: [
           Container(
             width: 3,
             decoration: BoxDecoration(
               color: colorScheme.primary.withValues(alpha: 0.85),
               borderRadius: BorderRadius.all(Radius.circular(999)),
             ),
           ),
           SizedBox(width: 10),
           Text('Why this profile is shown',
             style: theme.textTheme.titleMedium?.copyWith(
               fontWeight: FontWeight.w800)),
           SizedBox(width: 12),
           Expanded(
             child: Align(
               alignment: Alignment.centerLeft,
               child: Container(
                 height: 1,
                 color: colorScheme.outlineVariant.withValues(alpha: 0.45)),
             ),
           ),
         ],
       ),
     )
   Apply the same section label change in _BrowseWhyPlaceholder.

4. FIX _CandidateCard "New for you" badge.
   Replace the raw semi-transparent overlay:
     color: Colors.white.withValues(alpha: 0.18)
   with:
     decoration: AppTheme.glassDecoration(context)
   If the current wrapper is a `ColoredBox` or another widget that only
   accepts `color`, change that wrapper to `DecoratedBox` or `Container`
   around the same child and remove the old `color` argument. Do not leave
   both `color` and `decoration` on the same surface.
   This makes the badge consistent with ShellHeroPill and other floating
   glass surfaces in the app.

5. REDESIGN candidate count label.
   Replace:
     Text('${browse.candidates.length} candidate(s) ready',
       style: textTheme.bodySmall, textAlign: TextAlign.center)
   with:
     Align(
       alignment: Alignment.center,
       child: DecoratedBox(
         decoration: AppTheme.glassDecoration(context),
         child: Padding(
           padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
           child: Row(
             mainAxisSize: MainAxisSize.min,
             children: [
               Icon(Icons.people_outline_rounded, size: 14,
                 color: colorScheme.onSurfaceVariant),
               SizedBox(width: 6),
               Text(
                 '${browse.candidates.length} ready to explore',
                 style: textTheme.labelMedium?.copyWith(
                   color: colorScheme.onSurfaceVariant)),
             ],
           ),
         ),
       ),
     )

6. REDESIGN _DiscoveryShortcutCard to use semantic colors.
   The two cards need distinct identities:

   "Likes you" (pending likers) card:
   - Icon color: AppTheme.matchPink (#B85C78) instead of colorScheme.primary
   - Icon chip background: Color(0xFFB85C78).withValues(alpha: 0.14)
   - Icon: Icons.favorite_rounded (filled, not border)

   "Standouts" card:
   - Icon color: Color(0xFFD98914) — amber, matches the design doc's
     achievement/highlight semantic color
   - Icon chip background: Color(0xFFD98914).withValues(alpha: 0.14)
   - Icon: Icons.auto_awesome_rounded (unchanged)

   Both cards keep their existing layout (icon chip, title, subtitle).
   Only the icon color and chip background change per card. Pass these as
   parameters to _DiscoveryShortcutCard: `accentColor` and `icon`.

─── WHAT TO PRESERVE UNCHANGED ──────────────────────────────────────────
• All swipe/dismiss logic, Dismissible, confirmDismiss callbacks
• _handleLike(), _handlePass(), _handleUndo(), all API calls
• _BrowseActionBar (Pass / Like buttons at bottom) — unchanged
• _SwipeCue, _BrowseConflictState, _LocationWarningCard — unchanged
• _BrowseEmptyCard — unchanged
• _DeveloperSessionPanel — unchanged
• All providers, controllers, navigation (push to profile, standouts, etc.)
• _primaryPhotoUrl() helper
• BrowseCandidate card body below the photo (name overlay, why-shown section,
  "See full profile" button) — only the badge overlay and heading change
