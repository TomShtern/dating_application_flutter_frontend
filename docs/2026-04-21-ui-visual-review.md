# UI visual review — run 0007

Date: 2026-04-21

Reviewed artifacts:
- `build/visual_review/latest/*__run-0007.png`
- visual review workflow in `docs/visual-review-workflow.md`
- related screen/theme files mapped from `lib/features/**` and `lib/theme/app_theme.dart`

## Scope

I reviewed all 17 captured screens from the visual inspection suite:

1. Dev-user picker
2. Discover
3. Matches
4. Chats
5. Current-user profile
6. Settings
7. Conversation thread
8. Standouts
9. People who liked you
10. Other-user profile
11. Profile edit
12. Location completion
13. Stats
14. Achievements
15. Verification
16. Blocked users
17. Notifications

## Overall read

The app already has a strong aesthetic base:
- cohesive lavender/pink Material 3 palette
- pleasant rounded cards and soft shadows
- consistent avatar treatment
- no obvious clipped text, overflow warnings, or broken layouts in the reviewed run
- a clear product identity that feels warmer than a generic CRUD shell

The main opportunities are not "fix the broken UI" problems. They are mostly **density, hierarchy, and chrome-balance** problems:
- main-shell screens spend too much vertical space on repeated hero cards and bottom chrome
- several utility/detail screens are too sparse and stop visually halfway down the viewport
- the conversation thread is structurally the weakest screen right now
- some action hierarchies are muted or redundant
- repeated patterns should be consolidated into shared visual building blocks before polishing individual screens

## Highest-priority improvements

### 1. Shrink the main-shell chrome

**Priority:** P0

The biggest across-the-app issue is vertical efficiency.

The combination of:
- page title row
- large gradient hero card
- floating action/footer block
- large bottom navigation surface

means `Discover`, `Matches`, `Chats`, `Profile`, and `Settings` all show less real content above the fold than they should.

**What to change**
- Reduce hero-card height by about 25–35% on shell tabs.
- Reduce decorative background circles or make them subtler.
- Tighten vertical padding inside hero cards.
- Reduce the bottom navigation container height and simplify the duplicated signed-in status strip above the nav items.
- Re-evaluate whether both the page title and the large hero need to be present on every shell tab.

**Likely files**
- `lib/features/home/signed_in_shell.dart`
- `lib/features/browse/browse_screen.dart`
- `lib/features/matches/matches_screen.dart`
- `lib/features/chat/conversations_screen.dart`
- `lib/features/profile/profile_screen.dart`
- `lib/features/settings/settings_screen.dart`

### 2. Introduce a shared header/hero system

**Priority:** P0

The app uses multiple custom hero/header cards with similar shapes, spacing, chips, and gradients, but each screen feels like a separate interpretation of the same pattern.

**What to change**
- Extract a reusable shared hero/header widget with slots for:
  - eyebrow chip
  - title
  - supporting text
  - metadata pills
  - optional trailing action
- Support at least 2 density presets:
  - compact hero for shell tabs
  - expanded hero for special screens
- Reuse a consistent shadow, radius, and internal spacing model.

**Likely files**
- create under `lib/shared/widgets/`
- replace local hero variants in Browse, Matches, Chats, Profile, Settings

### 3. Define and enforce spacing tokens

**Priority:** P0

The UI feels mostly consistent, but many screens still read as hand-tuned rather than system-tuned.

**What to change**
- Introduce spacing tokens and use them everywhere instead of scattered magic numbers.
- Standardize:
  - screen horizontal padding
  - card internal padding
  - inter-card gaps
  - chip gaps
  - form field gaps
- Use 1 rhythm per screen family instead of near-duplicate values.

**Likely files**
- `lib/theme/app_theme.dart`
- screen files under `lib/features/**`

### 4. Rebalance action hierarchy

**Priority:** P1

Several screens have buttons that are either too visually dominant for their importance or too muted for the action they represent.

**What to change**
- Make primary CTA sizing and treatment more intentional.
- Reserve the strongest filled button style for the single most important action on a screen.
- Use outlined or text buttons more often for secondary actions.
- Improve disabled button styling so disabled controls look deliberately disabled, not washed out or unfinished.

**Likely files**
- `lib/theme/app_theme.dart`
- Browse, Matches, Chats, Notifications, Blocked Users, Verification, Profile Edit

### 5. Densify sparse utility screens

**Priority:** P1

`Stats`, `Achievements`, `Blocked users`, `Verification`, and `People who liked you` have lots of unused screen real estate. They look clean, but also unfinished.

**What to change**
- Add stronger section framing.
- Use richer card content, subheaders, icons, progress indicators, or explanatory copy.
- Aim for a more intentional full-screen composition instead of a few floating cards near the top.

### 6. Normalize user-facing copy and labels

**Priority:** P1

Several screens still expose internal or admin-flavored language instead of product language.

**What to change**
- Replace enum-like labels such as `ACTIVE`, `FEMALE`, and comma-separated backend tokens with human-readable copy.
- Remove implementation phrasing such as `update payload`, `backend resolve`, and similar system-facing wording from user screens.
- Rewrite shell hero text so it speaks to user value, not to the redesign effort itself.
- Warm up standout/notification/status copy so it feels productized rather than diagnostic.

**Likely files**
- `lib/features/profile/profile_screen.dart`
- `lib/features/profile/profile_edit_screen.dart`
- `lib/features/location/location_completion_screen.dart`
- `lib/features/browse/standouts_screen.dart`
- `lib/features/browse/browse_screen.dart`
- `lib/features/matches/matches_screen.dart`
- `lib/features/chat/conversations_screen.dart`
- `lib/features/settings/settings_screen.dart`

## Cross-cutting review notes

### What is already working well

- The palette is consistent and pleasant.
- Rounded geometry feels deliberate and modern.
- Cards are readable and mostly uncluttered.
- Form controls are legible and have enough touch area.
- Avatar circles with initials are clean and recognizable.
- The product already has a visual identity; it does not feel like a starter template.

### Systemic issues to address

- Repeated large empty areas make some screens feel incomplete.
- Decorative circles add personality, but on the main shell they sometimes read as placeholder art rather than useful structure.
- Metadata chips are sometimes overused, especially when the same information is already present elsewhere.
- Some list/detail cards repeat the same visual recipe without enough distinction between content types.
- Navigation footer takes too much attention relative to the content area.
- Accessibility polish is still needed around contrast checks, semantic labeling, and clearer disabled states.
- Internal terminology leaks into the UI in several places, which makes polished layouts still feel partly developer-facing.
- Refresh affordances are overexposed on compact screens where pull-to-refresh or auto-refresh already exists.
- Dense utility screens need a tighter padding preset; the current roomy spacing works better for heroes than for feeds or moderation lists.
- Card interaction patterns are inconsistent: some rows are fully tappable and also show a CTA, while others only make the footer button interactive.

## Screen-by-screen review

### 1. Dev-user picker (`app_home_startup__run-0007.png`)

**What works**
- Clean, simple entry flow.
- User cards are readable.
- Primary action is obvious.
- Backend status card gives helpful confidence.

**Issues**
- The upper stack is card-heavy for a simple chooser.
- "Backend online" and "Current user: none selected" feel visually similar even though they are different information types.
- The buttons are so large that they overpower the lightweight content.
- The lower half of the screen is almost entirely empty.

**Recommended fixes**
- Merge or visually differentiate the status and session cards.
- Make user rows more compact so more options fit above the fold.
- Reduce button width and let the identity row carry more of the card weight.
- Add a small note that the selected dev user persists between launches.
- Make the entire user row tappable instead of only the trailing button.
- Replace plain picker avatars with the richer shared avatar treatment used elsewhere in the app.
- Move or demote the inline backend refresh action so the status banner stays informational first.

**Likely file**
- `lib/features/auth/dev_user_picker_screen.dart`

### 2. Discover (`shell_discover__run-0007.png`)

**What works**
- Strongest visual personality in the app.
- Daily-pick card has good promotional energy.
- Like/pass controls are easy to find.

**Issues**
- The hero card is too tall and pushes core browsing content down.
- Decorative circles are visually loud and feel less refined than the rest of the screen.
- The browsing action bar is large enough to crowd the candidate content.
- The top shell card and bottom shell card together reduce swipe-focused immersion.

**Recommended fixes**
- Compress the hero card substantially.
- Tone down or reposition the decorative circles.
- Make the candidate content the main focal area above the fold.
- Consider a tighter action row with clearer undo/pass/like emphasis.
- Let the bottom shell breathe less so the browsing card can breathe more.
- Make the first browse decision more person-first by promoting richer profile facts or media over decorative framing.
- Reduce the amount of promo-style copy around the core candidate card so the browsing target feels more immediate.

**Likely file**
- `lib/features/browse/browse_screen.dart`

### 3. Matches (`shell_matches__run-0007.png`)

**What works**
- Match card is readable and warm.
- "Message now" direction is good product guidance.
- The chips clearly communicate status.

**Issues**
- The hero is too large for a screen that already has strong content cards.
- The three chips under the card body are a little repetitive.
- The top-right utility icons on the match card are not immediately self-explanatory.
- The CTA could feel more celebratory given that a mutual match is a high-value moment.

**Recommended fixes**
- Reduce hero size.
- Collapse or prioritize metadata chips.
- Add labels/tooltips or re-think the card utility icons.
- Make the match card feel more premium than a generic list card.
- Consider a stronger visual state for newly active or fresh matches.
- Promote `Message now` into a clearly primary action instead of another soft tonal control.
- Add a stronger differentiator per match card so multiple matches do not blur together in a longer list.

**Likely file**
- `lib/features/matches/matches_screen.dart`

### 4. Chats (`shell_chats__run-0007.png`)

**What works**
- Conversation card is easy to scan.
- The main CTA is clear.
- Avatar and timestamp support recognition.

**Issues**
- Again, the hero is too tall.
- Timestamp formatting looks technical rather than conversational.
- The trailing chevron plus "Open chat" button is redundant.
- There is too much white space for a one-thread screen.

**Recommended fixes**
- Compress the hero.
- Replace raw timestamp formatting with a friendlier relative/date style.
- Pick one navigation affordance: either the whole card is tappable or the button handles it.
- Increase message preview prominence relative to metadata.
- Add a real conversation preview or latest-message summary instead of a generic message-count sentence.
- Move recency to a more standard trailing-header position so the card reads like an inbox, not a badge collection.

**Likely file**
- `lib/features/chat/conversations_screen.dart`

### 5. Current-user profile (`shell_profile__run-0007.png`)

**What works**
- Hero card reads clearly.
- Profile completeness concept is useful.
- Edit profile action is obvious.

**Issues**
- The profile hero is visually stronger than the actual profile details.
- The completeness card is functional but a little flat.
- Checklist items feel repetitive and overly uniform.
- There is not much sense of the actual profile content beyond status and location.

**Recommended fixes**
- Add more personality and structure below the hero.
- Make the completeness block feel like a proper progress module, not just a checklist.
- Show compact previews of bio, preferences, and photos.
- Tighten the spacing between completeness items.
- Remove or differentiate the duplicate edit affordances so the screen has one clearly primary entry point.
- Swap the completeness panel into a success/maintenance state once the profile is already complete instead of still rendering like a to-do list.

**Likely file**
- `lib/features/profile/profile_screen.dart`

### 6. Settings (`shell_settings__run-0007.png`)

**What works**
- The current session card is easy to understand.
- The section design below is clean.
- "Switch user" is in a good place conceptually.

**Issues**
- The session hero is too tall relative to the rest of the screen.
- The most important settings destinations are barely visible in the screenshot because the top block dominates the layout.
- The screen feels like two separate design systems stacked vertically.

**Recommended fixes**
- Reduce hero height and internal chip padding.
- Promote the settings list higher in the viewport.
- Consider a more compact session summary row rather than a large feature card.
- Standardize the relationship between top summary blocks and settings sections.
- Remove redundant theme-mode information from the hero when a dedicated `Appearance` section already exists below.
- Demote `Switch user` so it does not visually outrank actual settings navigation.
- Flatten nested card-inside-card patterns in the settings body to reduce visual heaviness.

**Likely file**
- `lib/features/settings/settings_screen.dart`

### 7. Conversation thread (`conversation_thread__run-0007.png`)

**What works**
- Message bubbles are readable.
- Header actions are simple.
- Composer is easy to identify.

**Issues**
- This is the weakest screen in the set.
- Huge empty space between the last message and the composer makes the thread feel unfinished.
- Message timestamps are too visually loud for a two-message thread.
- The header lacks enough identity and structure.
- The composer/send area looks more disabled than ready.

**Recommended fixes**
- Rework the layout so the conversation feels anchored and intentional, not vertically stranded.
- Add a date separator or message grouping treatment.
- Soften timestamps and strengthen sender/message hierarchy.
- Improve the header with stronger peer identity and online/status context if available.
- Make the composer more obviously interactive even when empty.
- Revisit bubble width, vertical spacing, and bottom-safe-area composition.
- Remove repeated identity text such as showing the participant name again in the body when it is already clear from the app bar.
- Show sender labels only when they add meaning instead of repeating `You` / the other name above every bubble.
- Consolidate refresh affordances; the thread does not need auto-refresh, pull-to-refresh, and a prominent manual refresh icon all fighting for relevance.

**Likely file**
- `lib/features/chat/conversation_thread_screen.dart`

### 8. Standouts (`standouts__run-0007.png`)

**What works**
- Clean list layout.
- Strong candidate names and scores.
- Good baseline card readability.

**Issues**
- The screen is visually clean but underpowered.
- The intro card is plain compared with the importance of the feature.
- Score/rank data is present but not visually leveraged.
- CTA feels too secondary.

**Recommended fixes**
- Add more visual excitement to standout cards.
- Convert score/rank into a clearer badge or progress treatment.
- Improve perceived exclusivity or premium feel.
- Make the reason each person stands out more visually distinct from generic profile copy.
- Rewrite standout reasons so they feel curated and human rather than backend-analytic.
- Make the whole card tappable or move the action closer to the title so the card does not split into inert content plus detached CTA.

**Likely file**
- `lib/features/browse/standouts_screen.dart`

### 9. People who liked you (`pending_likers__run-0007.png`)

**What works**
- Extremely clear and simple list.
- Easy to scan.

**Issues**
- Too sparse and too generic for a feature with emotional/product importance.
- Feels like a placeholder list rather than a product surface.
- No context or momentum-building framing.

**Recommended fixes**
- Add a compact introductory header or summary count.
- Increase card richness with recency, location, or a small CTA.
- Make rows more tappable and more distinct from a generic settings list.
- Consider preview affordances that create curiosity without overwhelming the screen.
- Vary the repeated passive subtitle text so multiple rows do not blur together.

**Likely file**
- `lib/features/browse/pending_likers_screen.dart`

### 10. Other-user profile (`profile_other_user__run-0007.png`)

**What works**
- Strong hero.
- Information is readable.
- The content structure is clear.

**Issues**
- Repeated full-width white cards make the screen feel monotonous.
- The layout becomes a long stack of similar sections without enough cadence.
- There is no strong action zone for what the user should do next.

**Recommended fixes**
- Introduce more section variety.
- Group related profile facts together to reduce repetition.
- Add a sticky or bottom action area for profile actions if that flow exists.
- Use more differentiated typography between field labels and values.
- Reduce repeated identity treatment across the app bar, hero, and support copy.
- Avoid repeating the same status/location facts both in hero pills and again as full-width detail rows.
- Map raw enum/admin values into human-readable labels before display.
- Break up the settings-list feel with richer content blocks so the profile reads as authored content, not a menu.

**Likely file**
- `lib/features/profile/profile_screen.dart`

### 11. Profile edit (`profile_edit__run-0007.png`)

**What works**
- Functional and readable.
- The save button is clearly placed.
- Location row is understandable.

**Issues**
- Feels heavy and form-builder-like.
- Too many outlined inputs in a row with limited grouping.
- Intro copy is longer than it needs to be.
- Blank numeric fields make the middle of the form feel unfinished.
- No obvious sectioning between identity, preferences, and location.

**Recommended fixes**
- Split the form into sections.
- Convert some single-choice text inputs into chips, dropdowns, or segmented controls where appropriate.
- Tighten intro copy.
- Consider sticky save behavior or persistent affordance if the form grows.
- Add helper text only where it adds real value.
- Remove developer-facing wording like `update payload` from the opening guidance.
- Replace typed enum-token fields with proper pickers or chips so users never have to enter backend constants manually.

**Likely file**
- `lib/features/profile/profile_edit_screen.dart`

### 12. Location completion (`location_completion__run-0007.png`)

**What works**
- One of the strongest utility screens.
- Clear hierarchy.
- Suggestions area is useful.
- Toggle placement is understandable.

**Issues**
- The country row leading content looks visually odd and could be interpreted as a rendering glitch.
- Save CTA feels a little undersized for the primary job.
- Suggestions could feel more obviously interactive.

**Recommended fixes**
- Clean up the country selector leading icon/flag treatment.
- Consider a wider or full-width primary save button.
- Increase visual affordance on suggestion rows.
- Tighten the toggle row alignment and spacing.
- Avoid duplicate top-level titles between the app bar and the first card.
- Rewrite backend/system phrasing into outcome-focused user copy.
- Replace suggestion-row chevrons with a clearer selection affordance because tapping a suggestion fills the field rather than navigating elsewhere.

**Likely file**
- `lib/features/location/location_completion_screen.dart`

### 13. Stats (`stats__run-0007.png`)

**What works**
- Very readable.
- Metrics are easy to parse.

**Issues**
- Far too sparse.
- Feels like a stub screen, not a productized stats surface.
- The top-right action icon is visually disconnected from the metric cards.

**Recommended fixes**
- Turn the metrics into a more intentional dashboard.
- Add icons, trend context, labels, or comparative framing.
- Consider a denser card/grid presentation.
- Clarify what the top-right action does or remove it.
- Promote the metric values into the strongest visual position; right now labels read louder than the numbers themselves.
- Distinguish counts from rates more clearly so quantities and percentages do not all read as the same kind of data.

**Likely file**
- `lib/features/stats/stats_screen.dart`

### 14. Achievements (`achievements__run-0007.png`)

**What works**
- Easy to understand.
- Good baseline card readability.

**Issues**
- Also too sparse.
- In-progress and unlocked states are not visually differentiated enough.
- There is little delight for a feature that should feel rewarding.

**Recommended fixes**
- Add progress bars, badges, or completion states.
- Visually celebrate unlocked achievements more.
- Make in-progress achievements show momentum more clearly.
- Add category/grouping if this surface expands.
- Split description, progress, and state into separate visual tiers instead of flattening everything into one sentence-like subtitle.

**Likely file**
- `lib/features/stats/achievements_screen.dart`

### 15. Verification (`verification__run-0007.png`)

**What works**
- Segmented email/phone control is clear.
- The form is readable and simple.

**Issues**
- Screen composition is too minimal for a trust-sensitive flow.
- There is little explanation of why verification matters.
- CTA is visually okay but the screen lacks emotional and informational framing.

**Recommended fixes**
- Add compact trust-building context and benefits.
- Consider a richer header block or verification-status summary.
- Let the primary action span more confidently if appropriate.
- Add clearer state treatment for method selection.
- Rework the post-request and post-confirmation flow into a more guided single journey instead of a stack of loosely related cards.
- Visually quarantine dev-only verification-code output so it does not read like normal production UI.

**Likely file**
- `lib/features/verification/verification_screen.dart`

### 16. Blocked users (`blocked_users__run-0007.png`)

**What works**
- Clean row design.
- Unblock action is obvious.

**Issues**
- Extremely sparse.
- The unblock button is visually soft for a potentially sensitive action.
- The screen lacks context or safety framing.

**Recommended fixes**
- Add an explanatory header about what blocking does.
- Use a more intentional empty/non-empty list composition.
- Revisit the visual treatment of the unblock action so it looks deliberate, not casual.
- Add metadata such as blocked date if available.
- Reduce the width and visual weight of the trailing action so the reason text does not wrap prematurely.
- Rebalance the row so the user information, not the avatar ring and action pill, owns the visual center.

**Likely file**
- `lib/features/safety/blocked_users_screen.dart`

### 17. Notifications (`notifications__run-0007.png`)

**What works**
- Notification cards are readable.
- Event types are clear.
- The unread-only filter is a useful control.

**Issues**
- The filter/control card is oversized relative to the feed.
- "Mark all read" floats awkwardly inside the control card.
- Read/unread affordances are inconsistent: one item shows a pill button, another a check mark.
- The top control block consumes too much space.

**Recommended fixes**
- Convert the top control area into a tighter toolbar/filter row.
- Standardize read/unread states across cards.
- Make row interaction patterns more consistent.
- Reduce vertical padding in the control module.
- Replace raw log-like timestamps with friendlier conversational time formatting.
- Keep a consistent trailing layout width so read and unread rows do not shift their text blocks.
- Make unread state more legible with a stronger accent than a barely tinted card background.

**Likely file**
- `lib/features/notifications/notifications_screen.dart`

## Shared component opportunities

These should be done before or alongside screen-by-screen polish so the app gets cleaner and faster to iterate on.

### Shared component opportunity A: reusable shell hero

Create a shared widget for the repeated top summary card pattern used by:
- Discover
- Matches
- Chats
- Profile
- Settings

### Shared component opportunity B: reusable list/detail cards

Create a shared family of card primitives for:
- avatar + title + subtitle + metadata + CTA
- metric cards
- section intro cards
- settings destination rows

### Shared component opportunity C: shared empty/utility-state patterns

Secondary screens should share a stronger visual grammar for:
- intro/context header
- filter row
- empty state
- single-item state
- dense list state

### Shared component opportunity D: UX-copy normalization helpers

Create shared formatting/mapping helpers for:
- profile enums and status labels
- verification method labels
- timestamp display modes
- standout reason copy
- notification state text

## Accessibility and polish checklist

These were not catastrophic in the screenshots, but they should be part of the fix pass.

- Check contrast for tinted chips and lavender surfaces.
- Improve disabled-button clarity.
- Add semantic labels for icon-only actions.
- Ensure touch targets remain at least 48x48 after compaction.
- Review keyboard/focus behavior for desktop/web.
- Ensure timestamp formatting is readable and local-friendly.
- Tone down over-surfaced utility icons on sparse screens so they stop competing with the actual content.
- Add compact button/list variants for utility surfaces instead of reusing plush hero-era sizing everywhere.

## Suggested implementation order

1. **Foundation pass**
   - spacing tokens
   - button states
   - nav/footer height
   - shared hero component

2. **Main shell pass**
   - Discover
   - Matches
   - Chats
   - Profile
   - Settings

3. **Conversation/detail pass**
   - conversation thread
   - other-user profile
   - profile edit
   - location completion

4. **Utility-surface densification pass**
   - Standouts
   - People who liked you
   - Stats
   - Achievements
   - Verification
   - Blocked users
   - Notifications

5. **Accessibility and final visual polish pass**
   - semantics
   - disabled states
   - contrast
   - responsive spacing audit

## Bottom line

The app already looks cohesive and intentionally branded. The next leap in quality is **not** a new theme — it is a **layout refinement pass**:
- less oversized chrome
- more consistent density
- stronger action hierarchy
- more productized secondary screens
- a substantially better conversation thread

If we apply the changes above in the recommended order, the UI should feel noticeably more mature without losing the visual personality it already has.
