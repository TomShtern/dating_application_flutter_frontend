# Dating App Frontend UI Overhaul Design Brief

> Date: 2026-04-23
> Purpose: Single source of truth for the next end-to-end UI overhaul implementation plan.
> Scope: Consolidates the user's complaints and instructions, adds a deep visual/code audit, identifies systemic causes, and defines the redesign direction, constraints, do's and don'ts, dependencies, and open decisions.
> Inputs reviewed: `visual_review/latest/*__run-0008.png`, relevant Flutter screen files under `lib/features/**`, shared widgets under `lib/shared/widgets/**`, `lib/theme/app_theme.dart`, frontend handoff docs, and official Material 3 guidance for navigation bars, menus, and cards.

Baseline note: this brief intentionally uses the user-supplied `run-0008` screenshot set as the complaint baseline for this task. The repository contains later visual-review history, but this document is anchored to the screenshots and complaints explicitly supplied here so the implementation plan does not accidentally solve a different snapshot.

## How to use this document

- Use this document as the primary input for the next implementation plan.
- Treat the user's explicit complaints and instructions as mandatory unless a later user decision overrides them.
- Treat the additional audit observations in this document as recommended requirements unless they contradict future user direction.
- Preserve thin-client boundaries: the Flutter app may improve presentation, navigation, orchestration, and drill-down UX, but it must not invent server-owned business logic.
- Use this document to decide both what to change and what not to change.
- Treat the verification requirements below as merge-blocking quality gates for any implementation work derived from this brief.

## Verification Requirements

- Run `flutter analyze` for Dart changes.
- Run relevant `flutter test` targets for any code changes.
- Run `flutter test test/visual_inspection/screenshot_test.dart` after any UI change and inspect the generated visual output before merging.
- CI or manual review must confirm the applicable commands passed; if a command cannot be run, the implementation notes must state the blocker and the remaining risk.

## Product context and non-negotiable constraints

- This is a dating app. The UI must feel personal, attractive, warm, modern, and emotionally legible. It must not feel like CRUD software, a settings dashboard, or an admin panel wearing lipstick.
- The Flutter app is a thin client. Matching rules, compatibility logic, conversation persistence, moderation, verification rules, stats, achievements, and location resolution remain backend-owned.
- Android-first mobile UX remains the primary target. The screenshot review baseline is still the fixed `412x915` viewport used by `test/visual_inspection/screenshot_test.dart`.
- The current shared design primitives remain important and should be preserved rather than casually replaced:
  - `ShellHero`
  - `SectionIntroCard`
  - `AppAsyncState`
- Material 3 remains the baseline system, but the app must not look like raw default Flutter Material.
- Developer-only flows and controls must remain available for now, but they must be clearly marked as developer-only and visually separated from real product UI.
- Current backend/API realities must be respected. If richer UI needs richer data, the implementation plan must call that out rather than faking it in Dart.

## Screens and source files inspected

| Surface                      | Screenshot                                                                                                                                                | Current entry file                                      | Key supporting files                                                                 |
|------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------|--------------------------------------------------------------------------------------|
| Dev-user picker / startup    | not part of the attached screenshot set for this task                                                                                                     | `lib/features/auth/dev_user_picker_screen.dart`         | `lib/features/home/app_home_screen.dart`                                             |
| Signed-in shell / bottom nav | `shell_discover__run-0008.png`, `shell_matches__run-0008.png`, `shell_chats__run-0008.png`, `shell_profile__run-0008.png`, `shell_settings__run-0008.png` | `lib/features/home/signed_in_shell.dart`                | `lib/theme/app_theme.dart`                                                           |
| Discover                     | `shell_discover__run-0008.png`                                                                                                                            | `lib/features/browse/browse_screen.dart`                | `lib/shared/widgets/shell_hero.dart`, `lib/features/safety/safety_action_sheet.dart` |
| Matches                      | `shell_matches__run-0008.png`                                                                                                                             | `lib/features/matches/matches_screen.dart`              | `lib/features/safety/safety_action_sheet.dart`                                       |
| Chats list                   | `shell_chats__run-0008.png`                                                                                                                               | `lib/features/chat/conversations_screen.dart`           | `lib/features/chat/conversation_thread_screen.dart`                                  |
| Self profile                 | `shell_profile__run-0008.png`                                                                                                                             | `lib/features/profile/profile_screen.dart`              | `lib/shared/widgets/shell_hero.dart`, `lib/shared/widgets/section_intro_card.dart`   |
| Settings                     | `shell_settings__run-0008.png`                                                                                                                            | `lib/features/settings/settings_screen.dart`            | `lib/features/auth/selected_user_provider.dart`                                      |
| Other user profile           | `profile_other_user__run-0008.png`                                                                                                                        | `lib/features/profile/profile_screen.dart`              | `lib/features/safety/safety_action_sheet.dart`                                       |
| Profile edit                 | `profile_edit__run-0008.png`                                                                                                                              | `lib/features/profile/profile_edit_screen.dart`         | `lib/features/location/location_completion_screen.dart`                              |
| Pending likers               | `pending_likers__run-0008.png`                                                                                                                            | `lib/features/browse/pending_likers_screen.dart`        | `lib/shared/widgets/user_avatar.dart`                                                |
| Location completion          | `location_completion__run-0008.png`                                                                                                                       | `lib/features/location/location_completion_screen.dart` | `lib/features/location/location_provider.dart`                                       |
| Conversation thread          | `conversation_thread__run-0008.png`                                                                                                                       | `lib/features/chat/conversation_thread_screen.dart`     | `lib/features/safety/safety_action_sheet.dart`                                       |
| Blocked users                | `blocked_users__run-0008.png`                                                                                                                             | `lib/features/safety/blocked_users_screen.dart`         | `lib/features/safety/blocked_users_provider.dart`                                    |
| Stats                        | `stats__run-0008.png`                                                                                                                                     | `lib/features/stats/stats_screen.dart`                  | `lib/features/stats/achievements_screen.dart`                                        |
| Verification                 | `verification__run-0008.png`                                                                                                                              | `lib/features/verification/verification_screen.dart`    | `lib/features/verification/verification_provider.dart`                               |
| Standouts                    | `standouts__run-0008.png`                                                                                                                                 | `lib/features/browse/standouts_screen.dart`             | `lib/features/browse/standouts_provider.dart`                                        |
| Notifications                | `notifications__run-0008.png`                                                                                                                             | `lib/features/notifications/notifications_screen.dart`  | `lib/features/notifications/notifications_provider.dart`                             |

## Current UI diagnosis

### 1. The visual identity is too purple, too uniform, and too samey

The current app theme is built around a strong violet seed color in `lib/theme/app_theme.dart` and then amplified by `heroGradient`, `accentGradient`, large radii, and frequent soft/floating shadows. The result is not merely that the app is purple; it is that too many screens share the same lavender mood, the same glass pill treatment, the same rounded cards, and the same high-softness surfaces.

This makes the app feel bland, generic, and slightly toy-like instead of confident, attractive, and product-specific. The user complaint about the purple gradient is correct. The problem is not just one gradient; it is the over-dominance of one hue family across the whole interface.

### 2. The bottom navigation artifact is real and central, not incidental

The repeated lower strip is caused by `SignedInShell` rendering an extra summary row above the `NavigationBar`. That row repeats the active destination label and the current user name even though the navigation bar already shows the selected destination and the active screen usually already shows user context elsewhere.

This is the main reason multiple shell screens look visually broken near the bottom. It is a systemic shell problem, not a per-screen problem.

### 3. Too many screens are framed like utility panels instead of people-first dating surfaces

The app already has several nice reusable primitives, but many screens still spend too much space on intros, wrappers, stacked cards, and explanatory copy. In a dating app, the person, compatibility clues, recency, and next action should dominate. Instead, many screens feel like polished configuration panels.

### 4. Several actions are visually ambiguous

The shield icon from `SafetyActionsButton` appears in multiple contexts and currently reads like a badge or status indicator rather than a menu of actions. The user's confusion about the empty shield is fully justified. If an icon requires explanation and looks like passive status instead of an action, it should not remain as-is.

### 5. Information density is inconsistent

Some screens are too empty, some are too basic, and some are over-framed. Cards frequently contain too little information for their height. Other screens bury the important content below intro panels. This inconsistency makes the app feel unfinished even when individual widgets are styled decently.

### 6. Copy quality is uneven

Several screens use generic or repetitive lines that sound templated rather than product-specific. The worst examples are lines that repeat the same sentiment card after card without adding meaning. The UI must stop narrating obvious states and start showing useful, contextual reasons.

### 7. Developer-only affordances are leaking into the product experience

The settings screen is the clearest example, but `BrowseScreen` also currently includes a developer-oriented connection panel in the main product flow. The user is correct that some developer affordances must remain for now, but they must be explicitly labeled as such and visually quarantined.

### 8. Some screens need refinement; others need reconstruction

Not all surfaces need the same treatment:

- `ConversationThreadScreen` is fundamentally okay and only needs cleanup and small improvements.
- `LocationCompletionScreen` is directionally correct and needs polish, not reinvention.
- `NotificationsScreen` should be rebuilt from scratch.
- `Discover`, `Matches`, `Standouts`, `Profile`, and `ProfileEdit` need more meaningful structural redesign, not just paint.

## Systemic causes in the current implementation

### Theme and surface causes

- `AppTheme.light()` currently seeds the visual language with `Color(0xFF6A5CFF)` and pushes that tonality through `heroGradient`, `accentGradient`, and many surface styles.
- Surface radii are large almost everywhere: `28` and `32` are used heavily, which contributes to a soft-bulky look when combined with frequent shadows and rounded pills.
- Prominent shadows are used on many surfaces that would read more cleanly as flatter Material 3 cards.

### Shell causes

- `lib/features/home/signed_in_shell.dart` builds a persistent row containing the active destination and active user summary above the navigation bar.
- `NavigationDestinationLabelBehavior.alwaysShow` is already active, so the extra summary strip is doubly redundant.

### Action/menu causes

- `SafetyActionsButton` uses `Icons.shield_outlined` and an icon-only button. That reads as status, not action.
- Many screens rely on top-right refresh icons plus pull-to-refresh, creating unnecessary chrome.

### Screen composition causes

- `BrowseScreen` uses `ShellHero` as a static instruction banner rather than a true hero.
- `BrowseScreen` also lets the daily pick card compete with the main candidate for prime viewport space.
- `ProfileScreen` turns small facts such as gender and interested-in into separate full-width cards, which is overkill.
- `ProfileEditScreen` gives optional fields nearly the same visual priority as core identity/preferences fields.
- `StandoutsScreen` and `LocationCompletionScreen` hard-code more of their spacing and card anatomy instead of leaning fully on the shared layout system.
- `StatsScreen` and `AchievementsScreen` flatten everything into same-weight cards instead of meaningful groups.

## Redesign north star

The redesigned app should feel like a polished dating product that is:

- warm instead of cold
- modern instead of generic
- compact instead of bloated
- expressive instead of repetitive
- attractive without being tacky
- information-rich without becoming noisy
- clear about actions, reasons, and status

The app should feel more like a place where people meet, match, and talk, and less like a layered stack of beautiful-but-generic cards.

## Global redesign directives

### Theme and color direction

User-confirmed direction:

- The redesign should move away from warm lavender and candy-purple dominance.
- The approved theme family is now:
  - graphite as the main base
  - delicate, subtle silver as the premium detail layer
  - ink blue as the emotional/action accent
- Plum should not be the anchor color.
- Silver should stay soft and refined, not chrome-heavy or flashy.

Resulting palette strategy:

- Graphite should power the shell, deeper surfaces, stronger cards, and overall sense of weight.
- Delicate silver should appear in restrained places such as separators, outlines, icon accents, elevated highlights, and premium polish details.
- Ink blue should carry primary CTAs, selected states, focused interactions, and a few key hero accents.
- Compatibility / positive cues can still use restrained teal or emerald support when needed, but only as secondary semantic colors.
- Safety / warning cues remain red/orange and should stay semantically reserved.

Do not make the app monochrome, but also do not let the app drift back into purple-gradient repetition. The palette should feel darker, more adult, more premium, and more intentional.

### Navigation and shell chrome

- The bottom navigation bar must be the only persistent bottom chrome in the signed-in shell.
- Remove the summary strip above the navigation bar.
- Keep the five main destinations if needed, but simplify the shell visually.
- If the navigation still feels crowded after removing the strip, consider reducing label emphasis before adding new chrome.
- Avoid heavy shadows on the nav container.
- Bottom navigation should feel like app chrome, not like another content card.

This aligns with Material 3 guidance that a navigation bar is the persistent destination switcher on compact screens and should not be accompanied by redundant repeated destination chrome.

### Menus and temporary actions

- Use overflow menus for temporary/contextual actions.
- Do not keep ambiguous icon-only contextual actions floating inside cards if those actions are not self-explanatory.
- Replace the repeated shield icon pattern with a kebab overflow trigger on applicable people surfaces.
- Keep safety actions available, but put them behind a clear menu or labeled action flow.

This aligns with Material 3 guidance that menus are for temporary actions, while always-visible screen chrome should be reserved for persistent primary controls.

### Cards and surfaces

- A card should represent one subject clearly.
- Do not stack multiple equally loud top cards before the user reaches the main content.
- Reduce nested framing and excessive introductory card usage.
- Vary card treatment by purpose:
  - people cards
  - summary cards
  - utility cards
  - developer-only cards
- Lower elevation and flatter surfaces should be used more often.
- Preserve generous touch targets, but trim unnecessary vertical bulk.

This aligns with Material 3 guidance that cards should contain related content and actions about a single subject, not act as repetitive wrappers around everything.

### People-first surface rules

For `Discover`, `Matches`, `Standouts`, `Pending likers`, and applicable profile surfaces:

- Prefer photos whenever real photos exist.
- If no photo exists, use a polished initial-based fallback rather than a flat empty block.
- Show identity first.
- Show 1 to 3 strongest context clues second.
- Show actions third.
- Make most people cards fully tappable.
- Avoid generic filler sentences that consume precious space without improving decisions.

### Information hierarchy and density

- Put the main point of the screen above the fold.
- Intro copy should be small, purposeful, and often collapsible or inline rather than a full card.
- Large top hero/intro surfaces should be reserved for places where they add real value.
- Make list cards denser and more scannable.
- Use badges/chips sparingly and only when each chip adds meaning.
- Eliminate mysterious or redundant pills.

### Copy and microcopy direction

- Prefer human and product-specific copy over generic template copy.
- Replace repeated filler lines with concrete reasons, signals, or actions.
- Use fewer words when a label and layout already communicate enough.
- Keep trust-and-safety language calm, clear, and explicit.

### Drill-down pattern

Use bottom sheets as the default drill-down pattern for secondary explanatory detail when the user does not need a full new page.

Recommended bottom-sheet use cases:

- why this profile is shown
- why two users matched / match factors
- stat detail
- achievement detail
- safety actions
- developer-only explanations

Bottom sheets should feel like lightweight contextual explanations, not like tiny forms.

### Developer-only UI rules

- Developer controls must be grouped and labeled `Developer only` or equivalent.
- Do not let developer controls read like end-user product features.
- Do not place developer/system status inside the main discovery flow.
- When a dev-only control is temporary, say that clearly in the UI.

### Shared system to preserve and refine

Keep these shared building blocks, but use them more selectively:

- `ShellHero` for true hero/context framing, not for generic instruction banners.
- `SectionIntroCard` for sparse or utility surfaces, not as a mandatory top card on every screen.
- `AppAsyncState` for loading/error/empty handling.

## Shared components and patterns that should be added or refactored

The next implementation plan should likely include reusable components for the following:

- `AppOverflowMenuButton` or equivalent reusable kebab trigger
- `PersonPhotoCard` or `PhotoBackedProfileCard`
- `CompactContextStrip` for small top-of-screen explanatory context
- `CompatibilityMeter`
- `ReasonChipRow` or `HighlightTagRow`
- `MatchFactorsSheet`
- `StatDetailSheet`
- `AchievementDetailSheet`
- `DeveloperOnlyCalloutCard`
- `ViewModeToggle` for list/grid switching
- `NotificationListRow` with recency grouping support
- `CompactSummaryHeader` for utility screens such as stats, pending likers, and blocked users

## Screen-by-screen redesign requirements

## Dev-user picker / startup

- Screenshot: not attached in this task
- Current files:
  - `lib/features/auth/dev_user_picker_screen.dart`
  - `lib/features/home/app_home_screen.dart`

### Why it is included anyway

The user did not attach the startup screenshot in this task, so it is not part of the complaint-heavy visual baseline. Even so, it remains the first screen a developer sees and it should not drift away from the rest of the redesign.

### Resulting redesign requirements

- Keep the startup flow explicitly developer-oriented.
- Do not let it read like real production authentication.
- Align it with the revised theme direction so the first impression matches the rest of the app.
- Clearly state that this is a temporary development user-picker flow.
- Make the selection affordance obvious and fast.
- Keep this screen low-risk and low-scope compared with the core signed-in surfaces.

## Discover

- Screenshot: `visual_review/latest/shell_discover__run-0008.png`
- Current file: `lib/features/browse/browse_screen.dart`

### User direction

- The screen is messy and inconsistent.
- Remove the top card that contains swipe/open hints and `Browsing as Dana`.
- Keep swipe/open hints, but place them near the top in a smaller, compact form.
- The daily pick card is good in principle but is in the wrong place.
- Collapse daily pick into a headline-level compact element near the top.
- Tapping daily pick should open a full profile screen.
- The main profile being decided on should take most of the screen.
- Add a small, neat, colorful compatibility meter.
- The shield badge is unclear.
- The screen needs a broader redesign, not just local fixes.

### Additional audit observations

- `ShellHero` is currently being used as a bulky static instruction card; that is not a good use of the hero pattern.
- The main candidate card has personality potential, but it is still mostly an accent-colored block rather than a truly person-first surface.
- The developer connection panel should not live in the main discovery flow.
- `Likes you` and `Standouts` shortcuts are valid, but they should not compete visually with the current candidate.
- The separate bottom action bar is good for one-handed actions and should remain in some form.
- The `Browsing as Dana` chip reads more like a filter chip than a session/context label.
- The candidate rationale copy still sounds machine-authored in places and needs a more human tone.
- The large `See full profile` button creates a third high-visibility action path on top of swipe and pass/like, which weakens the decisiveness of the main browse flow.

### Resulting redesign requirements

- Remove the large instruction hero from the top of the page.
- Replace it with a compact context strip that can include:
  - short swipe/profile hint
  - active browsing user if needed
  - possibly undo as a secondary affordance
- Move the daily pick into a compact top element with strong discoverability but low vertical cost.
- The current candidate should dominate the viewport and read like the primary decision surface.
- Make the candidate card photo-first when data exists.
- If a photo does not exist, use a polished monogram fallback with intentional styling.
- Overlay only the key facts needed for first-pass decision-making:
  - name
  - age
  - 1 to 3 strongest reasons to care
  - compact compatibility meter
  - any truly important state chips
- Replace the shield icon with an overflow menu.
- Keep pass/like low and thumb-friendly.
- Keep swipe gestures as an equal first-class interaction.
- Keep a direct path to the full profile, but demote it so it feels secondary to the main decision path.
- Move developer/system status out of the main browse surface and into a developer-only location.

### Data and API dependencies

- Browse candidates are currently thin. A richer photo-first card may require:
  - profile enrichment in the browse DTO, or
  - on-demand fetch of richer profile data when the card expands or opens.
- `DailyPick` is also currently thin, so any compact daily-pick treatment that wants imagery or richer rationale should use the same enrichment-or-fetch strategy instead of assuming those fields already exist.
- The compatibility meter should only use server-provided compatibility/match-quality signals. If those signals are not currently available in browse data, the implementation plan must handle that explicitly.

## Matches

- Screenshot: `visual_review/latest/shell_matches__run-0008.png`
- Current file: `lib/features/matches/matches_screen.dart`

### User direction

- In addition to the bottom artifact, the screen looks generic.
- The shield badges at top right are unclear and inconsistent.
- All badges should be rethought and presented more clearly in the top-right area.
- Cards should be more compact.
- Each card background should be the person's photo, or their initial if no photo exists.
- Remove the generic grammatically weak repeated sentence.
- Replace it with actual reasons the users matched or compatible preferences that matter.
- Add a button that reveals all parameters that the users match on.
- That detailed match view should preferably be a popup, ideally a bottom sheet.

### Additional audit observations

- The current card anatomy is functional but text-generic and visually underpowered.
- The `Message now` CTA is good and should remain prominent.
- The whole card already navigates to chat on tap, which is directionally useful.
- The repeated `SafetyActionsButton` shield is the main cause of the confusing empty badge.
- Identity, date, state, and safety metadata currently sit too close to the same visual level, so the person gets buried behind metadata.
- The templated helper sentence becomes especially repetitive when several match cards are visible together.
- `View profile` is currently so soft that the secondary path is easy to miss.

### Resulting redesign requirements

- Redesign match cards as compact, visually rich person cards.
- Use a photo-backed or image-forward card treatment with readable overlay.
- If no photo exists, use a refined initial-based placeholder.
- Replace the generic body sentence with real compatibility signals.
- Show 2 to 4 concise match reasons at card level.
- Add a dedicated `Why we match` or equivalent CTA that opens a bottom sheet.
- The sheet should present:
  - strongest shared factors first
  - supporting compatibility details second
  - human-readable labels only
  - clear scannability
  - no form-like feel
- Replace the shield icon with a kebab overflow menu containing safety actions.
- Keep `Message now` as the primary CTA.
- Keep `View profile` secondary, but make it more discoverable and less ghost-like.

### Data and API dependencies

- Repository handoff docs mention `GET /api/users/{id}/match-quality/{matchId}` as a later enhancement, but the current frontend API layer does not expose that endpoint yet. The implementation plan should treat match quality as a contract-validation task: wire the frontend to a real server endpoint and DTO if backend support is available, or mark it as a backend dependency rather than inventing client-side logic.
- Photo-backed match cards may require either richer match data or an additional profile fetch path.

## Chats list

- Screenshot: `visual_review/latest/shell_chats__run-0008.png`
- Current file: `lib/features/chat/conversations_screen.dart`

### User direction

- This screen also has the weird shell artifact.
- It is a decent start but needs improving.
- It should be more compact.
- Each card should have an overflow kebab menu in the top right.

### Additional audit observations

- The current preview structure is readable, but the cards are taller than necessary.
- The `Open chat` filled button on every card makes the layout feel heavier than it needs to be.
- The overall list feels closer to a productivity inbox than a dating conversation list.
- Date and count metadata currently attract too much attention relative to the human context.
- The generic helper sentences make threads blur together instead of feeling socially distinct.

### Resulting redesign requirements

- Remove the shell artifact via the shared shell fix.
- Make each conversation row more compact.
- Prefer whole-row tap to open chat.
- Keep one clear preview line plus message count/date metadata.
- Add a top-right overflow menu per conversation row.
- Move nonessential actions out of the always-visible surface.
- Consider lighter CTA treatment than a large full button on every row.
- Make the person and conversational context feel more important than the activity-tracking metadata.
- Keep the screen simple; this surface does not need theatrical redesign.

### Nice-to-have improvements

- If later backend data supports it, add unread/new reply state.
- Consider small state cues such as `reply needed`, `new match`, or `active thread` where justified.

## Self profile

- Screenshot: `visual_review/latest/shell_profile__run-0008.png`
- Current file: `lib/features/profile/profile_screen.dart`

### User direction

- It looks okay from far away, but the actual hierarchy is wrong.
- The sentence about what other people can discover should not live inside the main profile card.
- `Active` and `Tel Aviv location` badges belong off to the side or in a more appropriate location.
- `Profile ready` should be smaller, higher, and more like an indication than a big section.
- The spacing between `4 essentials`, `complete`, and `ready for discovery` should be much tighter.
- The extra profile label near the bottom is an artifact and should not exist.

### Additional audit observations

- The current self-profile flow over-explains obvious context.
- The separate `Profile details` intro card adds more framing than value after the hero and profile completeness card already establish context.
- Small facts are over-promoted into their own full-width cards.
- The hero intro sentence currently describes the UI rather than the person.
- The sample bio text leaks meta/dev language such as `polished UI states`, which should never be used as product-facing example quality.
- Once the profile is complete, the page should feel calmer and less checklist-maintenance-oriented.

### Resulting redesign requirements

- Simplify the hero.
- Remove or relocate the explanatory sentence so it does not sit in the center of the main identity card.
- Make the hero focus on:
  - avatar/photo
  - name and age
  - compact meta chips
  - optional quick edit access
- Reposition state/location chips into a tighter metadata cluster.
- Convert `Profile ready` from a large card into a compact readiness indicator near the top.
- Make the readiness indicator tappable if a deeper checklist is needed.
- Tighten the layout of the completeness metadata.
- Reduce unnecessary intro framing lower on the page.
- Remove the apparent bottom artifact by fixing the shell.
- Add a copy-quality guardrail so self-profile examples and placeholders never read like internal product commentary.

## Settings

- Screenshot: `visual_review/latest/shell_settings__run-0008.png`
- Current file: `lib/features/settings/settings_screen.dart`

### User direction

- The screen is okay-ish and the icons are liked.
- The `Current profile` card is redundant, but should stay for development.
- That card should be highlighted and clearly separate.
- Add a small note that it exists for development and should be removed later.
- `Switch profile` should not read as a normal product feature.
- Add something like `Developer:` before it.
- The bottom settings artifact should disappear.

### Additional audit observations

- This is the cleanest home for developer-only session controls.
- Right now the session card looks too much like a real end-user account section.
- The quick-access section is useful and can stay, but grouping can be improved.
- The current profile card wraps awkwardly enough that simple profile facts can break onto their own line and feel sloppy.
- The quick-access descriptions are slightly too wordy for a fast-jump settings surface.

### Resulting redesign requirements

- Convert the top session card into a clearly labeled developer-only section.
- Recommended label direction:
  - `Developer session`
  - `Developer only`
  - `Temporary development tool`
- Rename the CTA to something explicit, such as `Developer: switch profile`.
- Add a subtle explanatory line that this flow is temporary and not part of the future production UX.
- Keep the rest of the settings surface calmer and more product-oriented.
- Remove the shell artifact.
- Tighten copy length in the quick-access list so it scans faster.

## Stats and achievements

- Screenshot: `visual_review/latest/stats__run-0008.png`
- Current files:
  - `lib/features/stats/stats_screen.dart`
  - `lib/features/stats/achievements_screen.dart`

### User direction

- The stats screen is ugly, bland, and not intuitive.
- It should be more colorful.
- The layout should be more intuitive.
- Clicking an achievement or a stat should open a new screen or popup with more detail.

### Additional audit observations

- `StatsScreen` is currently a flat ledger of equal-weight metric cards.
- The achievements entry point in the app bar is too subtle.
- `StatsScreen` and `AchievementsScreen` already have a lot of reusable structure, but they lack grouping and storytelling.
- Current stat descriptors are heuristic and generic.
- The top summary still behaves more like a style banner than a clear dashboard anchor.
- The top-right header icons are too cryptic for the amount of importance they currently hold.

### Resulting redesign requirements

- Redesign stats around grouped meaning, not a flat list.
- Group stats into human-readable clusters such as:
  - attraction
  - matching
  - conversation
  - profile health
- Make the top summary card more expressive and more helpful.
- Use color intentionally across categories.
- Make every stat card tappable.
- Make every achievement card tappable.
- Default drill-down pattern should be a bottom sheet unless a full screen becomes necessary.
- Drill-downs should explain:
  - what the stat or achievement means
  - why it matters
  - how it is calculated or interpreted when appropriate
  - any supporting context or milestone progress
- Make the achievements access point more discoverable than a small icon-only app bar button.
- Make the top summary anchor the dashboard more clearly by communicating scope, grouping, and control meaning.

### Achievement-specific requirements

- Distinguish unlocked vs in-progress achievements more clearly than the current screen does.
- Make unlocked states feel rewarding and celebratory without becoming gaudy.
- Make in-progress states feel motivating rather than visually second-class.
- Ensure achievement cards expose enough meaning at a glance before the user opens the detail drill-down.
- Use the same detail-sheet pattern for achievements that stats use, so the system feels coherent.
- Make scope and freshness legible on stats wherever recent, weekly, and total numbers coexist.
- Provide an explicit last-updated or refresh-context cue on stats surfaces that expose refresh actions.

### Data and API dependencies

- `UserStats` is currently flattened into `label/value` items. Any frontend mapping layer for `UserStats` must be strictly presentational, such as grouping display categories, labels, and units. It must not compute, aggregate, derive, or infer match, moderation, or metric state from other fields. Richer typing, trends, units, or computed semantics should be treated as a backend contract gap and requested through API changes rather than reimplemented in the client.

## Verification

- Screenshot: `visual_review/latest/verification__run-0008.png`
- Current file: `lib/features/verification/verification_screen.dart`

### User direction

- The screen is currently just meh and should be generally improved.

### Additional audit observations

- The main issue is not broken layout; it is under-designed flow.
- Step 1 looks acceptable, but the page feels empty and unfinished.
- Validation and guidance are light.
- The production experience feels too binary.
- The email/phone toggle and the field treatment are not coordinated tightly enough, so the form still feels like a static email form.
- The prefilled address does not feel clearly editable enough.

### Resulting redesign requirements

- Keep the two-step verification structure, but make it feel more intentional.
- Use a compact top context area that explains why verification matters.
- Make the step progression visually clearer.
- Improve inline validation, field affordances, and success feedback.
- Add resend and cooldown planning if backend behavior supports it.
- Keep the debug code panel dev-only and visually separate.
- Make the screen feel trustworthy and calm, not sparse and provisional.
- Make the step layout feel like a guided sequence rather than a lone settings tile.

## Standouts

- Screenshot: `visual_review/latest/standouts__run-0008.png`
- Current file: `lib/features/browse/standouts_screen.dart`

### User direction

- Add a toggle at the top to switch between grid and list.
- Remove the large `Profiles worth a closer look` card.
- Compress that concept into the top area near the `Standouts` title.
- Cards are boring and bland.
- Each profile should stand out in a unique way, but the uniqueness must still be expressed through a consistent format.

### Additional audit observations

- The current screen is clean but too repetitive.
- Rank and score exist but are visually underused.
- Every card says roughly the same thing, so the unique reason does not land strongly enough.
- The current screen still lacks one obvious primary interaction model because the text link suggests a different affordance than a tappable card.
- Rank and score sit too low in the card to organize the list at a glance.
- Variable reason lengths will make the list feel ragged unless the card anatomy is stabilized.
- The summary chip tells users how many standouts exist, but not how fresh or newly updated they are.

### Resulting redesign requirements

- Add a top-level list/grid toggle near the title.
- Recommended default: grid view, because standouts should feel visual-first and immediately scannable.
- Replace the large intro card with a compact inline summary row or chip cluster.
- Make each standout card visually richer.
- Use a consistent `why this profile stands out` format, such as:
  - one reason category tag
  - one concise primary reason line
  - optional rank or score chip
- Let the content vary per profile while keeping the card anatomy consistent.
- Make the whole card tappable.
- Preserve list mode for users who want fuller explanations.
- Make freshness or recency visible enough that the list feels alive rather than static.

### Data and API dependencies

- Current `Standout` data includes rank, score, reason, and timestamps. If the UI wants typed reason categories or richer standout signals, backend enrichment may be needed.

## Other user profile

- Screenshot: `visual_review/latest/profile_other_user__run-0008.png`
- Current file: `lib/features/profile/profile_screen.dart`

### User direction

- Add a top-right overflow kebab menu with:
  - report
  - block
  - hide
  - `Why this profile is presented to me?`
- `Gender` should be much smaller and integrated into another component.
- `Interested in` should also move near the top and consume minimal space.
- `Profile snapshot` should be at the top left, not in the middle.
- Additional improvements are welcome as long as they do not contradict the above.

### Additional audit observations

- The screen starts strong and then turns into a long stack of same-weight info cards.
- Photos appear too late in the current detail structure.
- The app bar title duplicates the hero's identity content.
- If imagery is absent, the current top state can feel placeholder-like rather than deliberately minimal.
- The page is informative, but the next available action is not obvious enough once the user finishes scanning the hero.

### Resulting redesign requirements

- Put the `Profile snapshot` pill at the top-left of the hero/header area.
- Replace the shield action in the app bar with a kebab overflow menu.
- Put `Gender` and `Interested in` into a compact top metadata row under the name.
- Avoid spending separate full-width cards on tiny facts.
- Bring photos higher in the page hierarchy when photos exist.
- Add a `Why this profile is shown` bottom sheet or equivalent drill-down.
- The `Hide` action must either be persisted by the backend or tracked as an explicit deferred backend dependency. Do not implement `Hide` as a client-only filter that is lost on restart or across devices. This follows the thin-client principle: moderation, matching, and relationship state are backend-owned. If the backend contract is missing, surface the API gap in the implementation notes instead of fabricating server-owned behavior locally.
- Define a stronger no-photo or limited-data presentation so the screen still feels intentional when media is missing.

## Profile edit

- Screenshot: `visual_review/latest/profile_edit__run-0008.png`
- Current file: `lib/features/profile/profile_edit_screen.dart`

### User direction

- The screen is messy and not intuitive.
- The gender section should be narrower.
- The preference section should also be narrower.
- Maximum distance should be a slider with an indication.
- Top descriptions should be more compact and integrated into the top.
- `About` should be below gender, preferences, and distance, not at the top.
- The layout should change accordingly.

### Additional audit observations

- The current form gives too much equal importance to all fields.
- Optional and advanced numeric fields are too prominent.
- The screen relies on long chip wraps and generic card sections.
- Public-profile fields and matching-preference fields still feel too visually interchangeable.
- The distance field currently makes blank-vs-default behavior ambiguous.

### Resulting redesign requirements

- Reorder the form so that the first visible items support fast editing of the most important profile signals.
- Recommended order:
  - basics / identity
  - preferences
  - distance
  - about
  - location
  - advanced optional filters
- Replace maximum-distance text input with a slider plus live numeric display.
- Make gender and interested-in controls more compact and structured.
- Move `About` below preferences as requested.
- Collapse or visually demote advanced optional numeric fields such as age range and height.
- Keep the sticky save button.
- Use the shared surface system and tighter spacing.
- Add a compact preview/summary cue so users can better understand what will actually be shown after save.

## Pending likers

- Screenshot: `visual_review/latest/pending_likers__run-0008.png`
- Current file: `lib/features/browse/pending_likers_screen.dart`

### User direction

- Cards should be more compact.
- Card backgrounds should use the profile picture or fallback first letter.
- Each card should have a subtle overflow kebab menu in the top-right.
- The top `Already interested` section should be more compact.

### Additional audit observations

- The current cards have too much white space for the amount of information shown.
- The primary action button is larger than the information density requires.
- The summary card is good in intent but taller than it needs to be.
- The repeated `Recent like` treatment does not help users decide who deserves attention first.
- The open-in-new style affordance makes the transition read too much like leaving the flow.

### Resulting redesign requirements

- Compress the summary section into a smaller header-style card or strip.
- Redesign liker cards as compact, image-forward rows or mini cards.
- Add overflow menus.
- Make the whole card tappable.
- Preserve recency context, but present it more elegantly.
- Keep `Open profile` as a secondary action, not the dominant visual element.
- Add a stronger prioritization cue so the list does not feel interchangeable.

### Data and API dependencies

- Pending liker cards will need photo support or profile-fetch fallback if the current DTO does not include enough media data.

## Notifications

- Screenshot: `visual_review/latest/notifications__run-0008.png`
- Current file: `lib/features/notifications/notifications_screen.dart`

### User direction

- This screen is considered the most broken, unintuitive, unresponsive, badly laid-out, and failure-prone of the set.
- It should be recreated from scratch.

### Additional audit observations

- At the reviewed `412x915` screenshot size, the layout is not literally exploding, but the user's overall diagnosis is still directionally correct: the screen is over-framed, visually noisy, repetitive, and fragile.
- The current layout uses too many simultaneous unread indicators:
  - surface tint
  - status chip
  - button
- The design is too card-heavy for a notification inbox.
- The existing filter and bulk action logic is useful and should survive, but not in the current layout.
- `Unread only` and `Mark all read` currently carry too similar a visual weight despite being different kinds of actions.
- Notification rows are too structurally similar across types, so the feed will blur quickly as it grows.
- Command wording should be tightened and standardized across `Unread only`, `Mark all read`, and `Mark read`.

### Resulting redesign requirements

- Rebuild the screen from scratch.
- Use a cleaner notification inbox model with grouped sections such as:
  - Today
  - Yesterday
  - Earlier
- Replace giant stacked cards with denser, responsive rows or list items.
- Keep a compact top controls area for filters and bulk actions.
- Use only one strong unread signal per item.
- Add type-specific quick actions when supported by the data payload.
- Make long titles and messages wrap safely on smaller widths.
- Make tap targets and hierarchy feel reliable and responsive.
- Ensure this screen can scale visually as the list grows.
- Give the controls bar a clearer priority split between filter state and bulk actions.
- Differentiate notification types more strongly so the feed becomes scannable at a glance.

### Data and API dependencies

- `NotificationItem.data` is the obvious hook for deeper contextual actions and destinations. The implementation plan should decide how much of that payload can power deep links or actions.

## Location completion

- Screenshot: `visual_review/latest/location_completion__run-0008.png`
- Current file: `lib/features/location/location_completion_screen.dart`

### User direction

- The general direction is okay-ish.
- The top and bottom edges have too much white space.
- It should be improved rather than fundamentally changed.

### Additional audit observations

- The screen is the most directionally correct utility form in the set.
- The country code badge looks technical rather than friendly.
- The suggestions block works, but the city search could feel more like a polished autocomplete.
- The model already carries `flagEmoji`, which the UI is not currently using.
- The screen does not yet clearly separate typed input from resolved selection.
- ZIP currently competes too strongly with the primary city flow.

### Resulting redesign requirements

- Keep the basic flow.
- Reduce wasted vertical space at the top and bottom.
- Make the country selector feel more human, not technical.
- Prefer flag + label over a code-like badge when appropriate.
- Make city search/autocomplete feel more polished and directly connected to the field.
- Keep the CTA obvious and mobile-friendly.
- Add slightly warmer explanatory framing about why location helps nearby matches.
- Style suggestions as results, not navigation rows, and show a clearer committed-selection state before save.

## Conversation thread

- Screenshot: `visual_review/latest/conversation_thread__run-0008.png`
- Current file: `lib/features/chat/conversation_thread_screen.dart`

### User direction

- It is good enough to mostly ignore for now.
- Add a kebab overflow menu at the top right.
- Suggestions are welcome if they improve the screen.

### Additional audit observations

- The core thread layout is solid.
- The app bar is slightly too busy because profile, safety, and refresh actions are all visible at once.
- The screen could benefit from a lightweight long-thread quality-of-life affordance.
- The screen currently opens with the top message bubble clipped, which makes the first visual state feel slightly misaligned.
- The header would benefit from one compact context line beyond just the user's name.
- The empty composer state should feel more visibly disabled before text is entered.

### Resulting redesign requirements

- Keep the standard thread structure.
- Add a top-right overflow menu.
- Consolidate profile, safety, and refresh actions into that overflow where appropriate.
- Keep the composer and bubble fundamentals.
- Consider a small `jump to latest` affordance for longer threads.
- Keep this screen low on the redesign-risk list; it does not need a dramatic rewrite.
- Make the initial viewport land on a cleaner visual message boundary.

## Blocked users

- Screenshot: `visual_review/latest/blocked_users__run-0008.png`
- Current file: `lib/features/safety/blocked_users_screen.dart`

### User direction

- The screen is basic.
- The top card should be more compact.
- The text should be stretched a bit rather than looking like narrow paragraphs in cards.
- Add an overflow kebab menu at the top right of each person card.

### Additional audit observations

- The trust-and-safety tone is already good.
- The current unblock action is too lightweight for the amount of space the row occupies.
- The short list leaves a lot of dead white space afterward.
- Inline block reasons may expose more moderation context than the list necessarily needs at a glance.

### Resulting redesign requirements

- Compress the summary card into a tighter row-based header.
- Rewrite or reflow the summary copy so it reads horizontally and cleanly.
- Add an overflow menu on each blocked-user row.
- Make the row feel more intentional and less like a placeholder list item.
- Improve the short-list state so the screen does not feel unfinished when only a few rows exist.
- Require confirmation or offer undo for unblock so it is harder to trigger accidentally.

## Accessibility and state-behavior requirements

These are mandatory planning guardrails, not nice-to-haves.

### Accessibility

- Preserve comfortable touch targets even after densifying layouts. Target `48x48` minimum interactive areas where practical.
- Provide semantic labels for icon-only actions and especially for overflow menus.
- Ensure contrast remains strong enough after the theme shift away from the current lavender-heavy system.
- Keep disabled states visually clear and not merely lower-opacity guesswork.
- Do not rely on color alone to communicate read/unread, active/inactive, or safety-critical status.

### State behavior

- Every redesigned screen must still have coherent loading, error, and empty states using the shared async-state system.
- Single-item states should not feel over-framed or lonely.
- Dense-list states should remain readable and tappable.
- Long text must wrap safely without clipping or awkward overlap.
- Image-first people surfaces must define failure fallback behavior explicitly:
  - loading
  - broken image
  - no image available
- Any bottom sheet introduced by the redesign must have a clear close path and must not trap essential actions behind hidden scrolling surprises.

## Interaction grammar and freshness requirements

These rules should be enforced across the redesign so the app stops feeling like a collection of individually styled screens.

- Define one primary tap target per row or card. Secondary actions should not visually compete with the main action.
- Normalize how primary vs secondary actions are expressed across the app. The redesign should not keep randomly switching between text links, pills, filled buttons, and icon-only actions for equivalent importance levels.
- Rationalize refresh behavior. If pull-to-refresh exists, do not keep a high-visibility refresh icon everywhere unless that screen genuinely benefits from it.
- Add freshness context where refresh exists, especially on stats, standouts, and notifications. A refresh icon without any sense of `what changed` or `how recent this is` feels decorative.
- Prevent bottom navigation chrome from clipping the last meaningful row or CTA on shell tabs.
- Strengthen no-photo fallbacks so identity does not collapse into the same repeated monogram treatment across every people surface.
- Use chips more intentionally. Count, state, recency, selection, and developer labels should not all look semantically identical.
- Keep action controls visually close to the object they affect. Avoid controls that feel bolted onto a header when they really belong to a row or card.

## Cross-cutting do's and don'ts

### Do

- Do make the app feel like a dating product first.
- Do put people, photos, compatibility, and conversation cues above generic chrome.
- Do preserve the shared design primitives while using them more selectively.
- Do prefer overflow menus and bottom sheets for contextual secondary actions.
- Do label developer-only UI explicitly.
- Do reduce redundant copy, repeated chips, and repeated framing.
- Do use server-driven data for compatibility, stats, verification, and safety details.
- Do keep one-handed actions strong in `Discover`, `Matches`, and chat.

### Don't

- Do not keep the duplicate shell summary strip above the bottom nav.
- Do not keep the current mystery shield icon pattern.
- Do not let every important surface be some form of lavender gradient.
- Do not let intro cards consume prime content space when the user already understands the screen.
- Do not turn tiny facts into full-width cards unless they genuinely deserve it.
- Do not invent compatibility logic, reasons, or metrics in the client.
- Do not let developer tools masquerade as production UX.
- Do not rebuild stable screens just because other screens need drastic changes.

## Backend and data coordination notes

The next implementation plan should explicitly decide how to handle the following dependencies:

- Do not reduce UI quality targets just because the current frontend contract is thin.
- If a redesign requirement needs new endpoint support or richer response fields, call that out explicitly as backend work instead of weakening the surface design to fit today's DTOs.

1. Photo-backed people cards
   - `Discover`, `Matches`, `Standouts`, and `Pending likers` all want richer person media treatment.
   - If the current DTOs are too thin, choose between:
     - DTO enrichment from backend
     - lightweight profile-detail fetch on demand
     - temporary refined monogram fallback

2. Match reasoning and compatibility details
  - Use backend match-quality data where available.
  - The current frontend API layer does not yet expose a match-quality endpoint, even though older repo docs mention one as a later enhancement.
  - The implementation plan must include explicit contract validation and a backend-coordination fallback before shipping a `Why we match` sheet.
   - Do not infer or fabricate compatibility from unrelated fields.

3. Why shown / why presented explanations
   - These should be server-driven wherever possible.
   - If the backend does not yet expose enough explanation, the implementation plan must spell out the fallback behavior.

4. Stats richness
   - Richer grouping, trend descriptions, and typed semantics may require backend structure beyond flat `label/value` strings.

5. Notifications deep links and actions
   - The implementation plan should assess how much of `NotificationItem.data` can power contextual actions.

6. Hide action on other-user profiles
   - `Hide` must be either a backend-persisted preference or an explicitly deferred backend dependency.
   - Do not ship a restart-lost or device-local client-only hide filter.
   - If the API contract is missing, call out the backend gap rather than emulating moderation, matching, or relationship state in Dart.

## Recommended planning slices

This is not the implementation plan yet, but the likely planning order should be:

1. Theme and shell cleanup
   - color system
   - bottom nav artifact removal
   - overflow menu standardization

2. Shared person-surface system
   - photo-backed cards
   - chip/tag patterns
   - bottom-sheet drill-downs

3. Core revenue-of-attention screens
   - `Discover`
   - `Matches`
   - `Chats`
   - self/other profile surfaces

4. Utility-but-visible screens
   - `Standouts`
   - `Pending likers`
   - `Stats`
   - `Achievements`
   - `Verification`

5. Rebuild target
   - `Notifications`

6. Low-risk polish pass
   - `Location completion`
   - `Conversation thread`
   - `Blocked users`
   - settings dev-only cleanup

7. Visual review and consistency pass
   - fresh screenshot suite
   - edge-case density pass
   - chip/menu/action consistency pass

## Above-the-fold acceptance cues

These cues are not the full implementation plan, but they should help the future plan stay concrete.

Before any implementation based on these cues is merged, reviewers must confirm the applicable verification gates passed: `flutter analyze` for Dart changes, relevant `flutter test` targets for code changes, and `flutter test test/visual_inspection/screenshot_test.dart` for UI changes with visual output inspected.

### Discover

- Above the fold at `412x915`, the user should immediately see the current candidate as the dominant surface.
- Daily pick should be present but compact.
- The primary pass/like decision path should be obvious without scrolling.

### Matches

- Above the fold, the user should understand who the first match is, why the match is promising, and what the next action is.
- The first card should expose a clear path to `Message now` and `Why we match`.

### Chats

- Above the fold, the user should see at least the first two conversations with clear recency cues and a clear tap path into the thread.

### Self profile

- Above the fold, the user should see identity, a compact status/location cluster, and a compact profile-readiness indicator without large explanatory clutter.

### Notifications

- Above the fold, the user should see the current filter context and multiple notification rows without the screen feeling card-stacked or over-framed.

## User-confirmed design choices

These were reviewed directly with the user after the first spec draft and should now be treated as locked unless the user later changes direction.

### 1. Theme family

- Use a graphite-led visual system.
- Use delicate, subtle silver for premium detailing.
- Use ink blue as the main accent color.
- Avoid plum as the anchor color.
- Keep the silver restrained and elegant rather than shiny or dominant.

### 2. Standouts default view

- Default to grid view.
- Keep a toggle to list view.

### 3. Discover interaction model

- Keep a persistent bottom action bar for `Pass` and `Like`.
- Preserve swipe as a first-class interaction.
- Keep card tap / profile-opening behavior available as the path to fuller detail.

### 4. Match details drill-down

- `Why we match` should open in a bottom sheet by default.
- Escalate to a full page only if the content later becomes significantly richer than currently expected.

## Final design intent summary

The next version of this UI should stop feeling like a collection of soft purple cards and start feeling like a real dating app:

- people-first
- compact
- visually warmer
- less redundant
- less generic
- less admin-like
- clearer in action and meaning
- stronger in hierarchy
- more photo-driven
- more intentional about what earns screen space

The shell artifact must go. The mysterious shield pattern must go. The purple-gradient dominance must be reduced. `Discover`, `Matches`, `Standouts`, `Profile`, `ProfileEdit`, and `Notifications` need the most meaningful redesign attention. `Conversation thread` and `Location completion` should be improved carefully rather than overworked.

This document is the canonical input for the forthcoming implementation plan.
