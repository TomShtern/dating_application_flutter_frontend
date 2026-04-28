# Design Language - Flutter Dating App

Status: active target-direction canon.

This document defines the visual direction agents should design toward. It is
not a claim that every current screen already matches the direction. Some
screens in the app still reflect older guidance and should be corrected in
future UI passes.

The previous design-language document was intentionally retired to
`docs/old-outdated-stale-design-language.md`. Do not use that file for new UI
work.

## Canonical Visual References

Before changing UI, inspect these durable reference screenshots:

- `design-reference/stats-run-0070-reference.png`
- `design-reference/notifications-run-0070-reference.png`
- `design-reference/notifications-dark-run-0070-reference.png`

Historical references retained for comparison:

- `design-reference/stats-run-0065-reference.png`
- `design-reference/notifications-run-0065-reference.png`
- `design-reference/notifications-dark-run-0065-reference.png`

The run-0070 screenshots are the current source of taste for this document.
The run-0065 screenshots are retained as historical references because they
started the direction, but future UI work should compare against run-0070.
These screenshots show the preferred mix of pastel color, compact useful
structure, soft surfaces, semantic visual signals, readable density, route
or screen context, and dark-mode personality.

Do not use `visual_review/latest/` as a durable reference. That folder is
disposable and replaced on each visual-review run. Archived visual runs can
also be pruned by the visual workflow.

## Recent Failure Modes To Avoid

This document exists because recent UI passes drifted away from the preferred
screens. Avoid these root causes when interpreting the design language:

- Large blank `ShellHero` slabs that consume first-viewport space without
  meaningful state or content.
- One-color mauve, pink, or rose sameness across a whole screen.
- Low first-viewport content density: too much intro chrome before useful
  cards, rows, or actions appear.
- Secondary screens that lose route context: no title, no back affordance, or
  invisible app-bar space that makes the screen feel detached from the app.
- Generic undecorated icons that look like placeholder Material defaults rather
  than polished product signals.
- Cards that are either plain white and unfinished or fully color-filled and
  overwhelming.
- Reusing one component pattern because it exists, even when the screen needs a
  different structure.

Use the reference screenshots to calibrate the fix: compact, colorful,
structured, semantic, and soft.

## Product Personality

The app should feel like a playful pastel product system with data-informed
clarity.

That means:

- Warm, lively, premium, and lightly romantic.
- Colorful and pastel, not plain white and not dominated by one brand color.
- Organized and consistent, not random or decorative for its own sake.
- People-centered where people matter, with compact signals around them.
- Dense enough to communicate useful state quickly, but still soft and
  comfortable.

The product should sit between a warm premium dating app and a playful romantic
interface. It should not feel like a cold admin tool, a generic Material demo,
or a childish sticker-heavy app.

## Core Principles

### Useful State First

The first viewport should tell the user where they are, what matters right now,
and show real content quickly. A compact summary, key count, status pill, or
primary action is useful. A large low-information header is not.

Headers should be compact by default. If the header consumes a large part of
the first viewport, it must earn that space with meaningful content, useful
state, or a genuinely important moment.

### Dense But Soft

Prefer dense but soft layouts:

- Compact summaries.
- Grouped sections.
- Information-rich cards.
- Short labels.
- Enough padding to feel approachable.
- No large empty vertical slabs.

The app should not be cramped. It should also not waste space that could show
useful content.

### Visual Grammar Over One Component

Different screens will need different components. Do not force every screen
into the same hero, card, or list pattern.

Consistency comes from visual grammar:

- Semantic pastel colors.
- Soft tinted surfaces.
- Compact section grouping.
- Decorated icon chips.
- Accent bars and status tags.
- Clear CTA hierarchy.
- Repeated spacing and typography rhythm.

Use shared widgets when they fit the desired outcome. If a shared widget pushes
the screen toward an older or weaker design, improve the shared widget or use a
more appropriate structure.

### People Plus Signals

People screens should keep people central, but the product should also expose
compact, colorful signals around them: active status, match status, message
state, location context, profile readiness, safety state, and server-provided
reasons.

Use real media when it adds presence. When media is unavailable or not useful,
use polished pastel avatars and meaningful chips rather than generic placeholders.

## Color Direction

Color is a first-class part of this product. It should be visible and joyful,
but it must stay organized.

### Semantic First

Meaning determines hue. Screen-level palettes can add personality, but they
must not override semantic clarity.

Use stable colors for repeated meanings:

| Meaning | Preferred hue family | Notes |
| --- | --- | --- |
| Matches, attraction, affinity | Rose, violet, soft pink | Use pink as one hue, not the whole system. |
| Messages, conversations | Teal, cyan, blue-green | Should feel fresh and relational. |
| Activity, momentum, highlights | Coral, amber, orange | Good for energy and progress. |
| Trust, success, active state | Green, mint | Use for positive state and availability. |
| Milestones, achievements | Violet, periwinkle, amber | Can be richer and more celebratory. |
| Profile, identity, personal info | Blue, lavender, rose | Softer and less urgent than action states. |
| Safety, block, report, moderation | Rose, coral, slate | Serious, not harsh unless destructive action is immediate. |
| Unknown, fallback, disabled | Slate, muted neutral | Never use slate as the main personality color. |

### Entity And State Color Defaults

Use these as default semantic anchors. They are not rigid exact-only colors:
agents may use lighter fills, darker text, alpha blends, or dark-mode tuned
variants when the meaning stays stable and the screen remains harmonious.

| Entity / state | Default accent | Typical treatment |
| --- | --- | --- |
| New match / match found | Violet `#7C4DFF` | Icon chip, unread accent bar, match tag, milestone accent. |
| Message / chat / conversation | Teal `#009688` | Chat icon chip, message status, conversation-count signals. |
| Friend / trust / reply quality | Green `#2E9D57` | Trust signals, reply-rate indicators, accepted social state. |
| Active now / available | Mint-green `#16A871` light, `#35C98E` dark | Small dot, active pill, availability label. |
| Likes sent / outgoing activity | Coral `#FF7043` | Activity metric, sent-like signal, warm action context. |
| Likes received / affinity | Rose `#E24A68` | Pending liker signal, received-like count, attraction state. |
| Weekly / accepted / relationship update | Indigo `#5B6EE1` | Accepted friend/match state, calendar or weekly status. |
| Achievement / milestone | Violet plus amber `#D98914` | Milestone card, progress state, celebratory accent. |
| Response time / timing | Amber `#D98914` | Timer icon, response-time metric, time-sensitive status. |
| Profile views / generic profile activity | Sky blue `#188DC8` | Profile-view metric, neutral profile activity. |
| Verification / safety trust | Green, blue, or muted violet by context | Verification badge, trust panel, proof state. |
| Blocked / reported / moderation | Rose, coral, or slate | Serious soft row, warning tag, overflow action context. |
| Unknown notification / fallback | Slate `#596579` or sky blue `#188DC8` | Display-only status, generic notification icon. |

Do not let these defaults collapse into a brand-pink theme. If a screen has
matches, messages, safety, and profile state together, those meanings should be
visually distinguishable.

### Pink Is Not The Base

Rose and pink are part of the palette, but they are not the default answer for
every screen. Avoid one-color mauve or pink-heavy screens. The preferred app
look is colorful pastel variety with stable meaning.

### Layered But Controlled

Use color in layers:

- Soft tinted card fills.
- Colored icon chips.
- Left or top accent bars.
- Small tags and status pills.
- Progress bars and rings.
- Selected controls.
- Occasional gradient surfaces for special moments.

Most screens should show more than one meaningful color family, but the colors
must repeat consistently enough that the screen feels designed, not scattered.

### Card Color Ceiling

Default cards are accent-dominant:

- Calm pale surface first.
- Semantic accent second.
- Full color-block or gradient treatment only for summaries, milestones,
  special status panels, primary emotional moments, and selected high-value
  CTAs.

Too much white feels unfinished. Too much filled color feels overwhelming. The
target is soft tinted surfaces with visible semantic accents.

Use this layer recipe for most cards:

1. Base: a soft surface using the current theme surface/tint system.
2. Tint: optional pale semantic fill or alpha blend.
3. Accent: one clear semantic bar, top stroke, icon chip, tag, or value color.
4. Signal: a decorated icon/status chip that explains the card's meaning.
5. Action: one primary affordance or a quiet trailing cue when the card is
   already tappable.

Do not apply all possible decorations at once. A card should usually have one
dominant semantic accent and one or two supporting signals.

Known read, inactive, or secondary cards should still keep a very light
semantic tint when the item has a clear meaning. Do not reserve semantic color
only for unread, selected, or primary states. Unknown or fallback items may use
slate or sky-blue tint, but they should still feel intentionally designed.

Use tint intensity as calibration, not an exact formula:

- Light mode: tint should be subtle but visible, enough to avoid plain white
  unfinished cards.
- Dark mode: tint can be slightly stronger because dark surfaces absorb color,
  but it must stay soft and readable.
- Avoid pure white default cards and avoid saturated full-color cards unless the
  card is a summary, milestone, special state, or primary emotional CTA.

### Dark Mode

Dark mode should keep the same personality and semantic color logic as light
mode. It should not become a separate muted product.

For dark mode:

- Keep similar hue families.
- Soften brightness and saturation against dark surfaces.
- Prefer deeper tinted panels and gentler accent fills.
- Preserve readable contrast.
- Keep color variety visible, but avoid neon.

The `notifications-dark-run-0070-reference.png` screenshot is the key reference
for dark-mode mood.

## Layout And First Viewport

### Compact Entry Pattern

Most screens should begin with a compact, useful intro or summary, not a large
hero slab. Good top areas usually include:

- Screen title or context.
- One useful count or state.
- A compact primary action or refresh affordance when needed.
- Optional filter or status chips.

Then the screen should move quickly into real content.

Compact intros should usually fit in roughly 90-140 px on a phone screenshot,
including chips and actions. If the intro is taller, it must earn the space
with richer state, a high-value moment, or real content. Otherwise split the
extra content into the first section below.

Do not confuse compact intro with route chrome. If a screen is pushed onto the
navigation stack, it still needs a back affordance and enough route context to
feel connected to the app.

### Section Labels

Use compact section labels for grouped content. The preferred pattern is visible
in Stats and Notifications:

- A short vertical accent bar.
- Bold section title.
- A thin horizontal rule that gives structure without adding weight.

This pattern is especially useful for feeds, grouped stats, grouped settings,
profile sections, safety lists, and any screen with multiple content groups.

### Cards And Lists

Cards should feel soft and touchable:

- Rounded, but not cartoonish.
- Light borders.
- Soft shadows.
- Pale tinted fills when useful.
- Semantic accents inside the card.
- Tappable cards use `Material` plus `InkWell`.

Lists should be readable and compact. Avoid repeating large CTAs or redundant
instructions inside every row. One chevron, one status pill, or one small action
is often enough.

For repeated list tiles, prefer the same anatomy as Notifications:

- Optional unread/priority accent bar.
- Decorated semantic icon chip.
- Primary title and short supporting copy.
- Compact tag/status row.
- Quiet trailing action, check, chevron, or overflow menu.

### Whitespace

Use compact breathing room:

- Enough internal padding to feel premium.
- Tight enough vertical rhythm to show useful content.
- No empty headers, decorative gaps, or oversized panels that hide the real
  content.

## Component Direction

### Headers

Large `ShellHero`-style headers are discouraged by default for this app. They
have repeatedly produced blank slabs that consume too much first-viewport space.

Use a large hero-like surface only when it has a specific reason:

- A data-rich summary.
- A milestone or achievement.
- A meaningful onboarding-style state.
- A success state or special confirmation.
- A high-value profile moment with real content.

If the header only contains a title, short description, and one pill, make it a
compact intro card or inline screen header instead.

### Route Chrome And App Bars

Secondary screens opened with `Navigator.push` should keep navigation context:

- Provide a back affordance through a compact app bar or an equivalent top
  navigation control.
- Show a short route title when the screen would otherwise feel detached.
- If an app bar exists only for trailing actions and has no visible title,
  reduce its height or move the actions into the compact intro.
- Do not leave default-height invisible app bars above the real content.
- Standalone visual-review captures may not show a back button because there is
  no parent route. In those cases, the screen should still show useful context
  through a compact title, intro, or summary.

### Icon Treatment

Icons should be meaningful, colorful, and polished.

Default rule:

- Use recognizable Material icons.
- Place them in semantic pastel chips, badges, or tinted containers.
- Size them consistently.
- Match icon color to the item meaning.

Custom or illustrative icons are allowed only for special moments:

- Empty states.
- Verification success.
- Achievements and milestones.
- Onboarding-like intros.
- High-value profile or match moments.

If custom illustration assets are unavailable, default to decorated semantic
Material icons. Do not use plain generic icons as the finished visual treatment.

### Tags, Pills, And Chips

Tags and pills carry a lot of the product personality. Use them for:

- Status.
- Filters.
- Counts.
- Type labels.
- Server-provided reasons.
- Safety state.
- Verification state.

They should be colorful but compact. Avoid filling rows with many similar pills
that do not help the user understand or act.

### Gradients

Use gradients purposefully:

- Data summaries.
- Milestone cards.
- Special status panels.
- Primary or emotional CTAs.
- Very subtle page-level background treatment when it supports the screen.

Do not use gradients as filler decoration. Avoid background blobs or ornamental
shapes that do not clarify content. Prefer soft gradient washes and tinted
surfaces over decorative effects.

### Buttons And CTAs

CTA hierarchy matters:

- Primary or special actions can use the strongest color treatment.
- Gradient CTAs are reserved for primary, emotional, or special actions.
- Secondary actions should still get softer color, not dead-neutral styling.
- Destructive actions should be clear and serious, but not visually aggressive
  unless the destructive action is immediate.

Avoid multiple equally loud CTAs on one card. A card should not look like a row
of competing advertisements.

## Reusable Pattern Targets

These are target patterns, not mandatory widgets. Use existing shared widgets
when they fit. Compose locally when a screen needs a different shape. Improve a
shared widget only when the same improved pattern is useful across multiple
screens.

### Compact Intro

Use for most screen openings instead of a large hero slab.

Anatomy:

- Short title or context label.
- One useful count, state, or selected-user indicator.
- Optional decorated icon chip.
- One compact primary action or refresh affordance when needed.
- Optional filter/status chips below the main row.

Keep the intro short enough that real content appears in the first viewport.

### Section Label

Use for grouped content.

Anatomy:

- Left vertical semantic accent bar.
- Bold compact title.
- Thin horizontal rule.
- Optional small count/status chip only when it adds meaning.

Do not turn section labels into large cards. Their job is to organize, not to
dominate.

### Semantic List Tile

Use for notifications, settings rows, blocked users, safety rows, compact
matches, conversations, and utility lists.

Anatomy:

- Soft tinted card surface.
- Semantic icon chip.
- Strong title.
- One or two supporting lines.
- Compact tag/status row when useful.
- Quiet trailing cue or overflow menu.

Avoid repeated full-width buttons inside every row unless each row genuinely has
a primary action.

### Person / Social Card

Use for browse, matches, pending likers, standouts, profile previews, and other
people-centered surfaces.

Anatomy:

- Real media when it adds presence; otherwise a polished pastel avatar.
- Name and core identity details.
- Compact relationship/status signals: active, verified, location, match state,
  pending state, or server-provided reason.
- One clear primary action and quieter secondary actions.
- Safety/context actions in overflow menus unless the safety action is the main
  point of the screen.

Avoid oversized avatar rings and decorative media if they crowd out useful
signals.

### Metric / Status Tile

Use for stats, achievements, readiness, verification progress, profile
completion, and other quantified state.

Anatomy:

- Semantic color tied to the metric meaning.
- Decorated icon chip.
- Large value or status text.
- Short label.
- Optional small chart, progress bar, ring, or spark detail.

Use richer color density here than in forms or messaging because color improves
scanning.

### CTA / Action Row

Use when a surface has multiple actions.

Anatomy:

- One visually strongest action.
- Secondary actions with softer color treatment, not dead-neutral styling.
- Destructive actions separated by tone, placement, or confirmation.
- Icon plus label when the action benefits from quick recognition.

Avoid two or three equally loud buttons in one row.

### Form Section

Use for profile editing, location completion, verification input, settings
controls, and other editing flows.

Anatomy:

- Compact section title or decorated intro.
- Related fields grouped together.
- Softer pastel accents than display screens.
- Clear validation/status color.
- Primary save/continue action visible without crowding fields.

Forms should feel expressive but calmer than feeds, stats, or achievements.

### Empty State

Use when a screen or section has no data.

Anatomy:

- Decorated semantic icon or special illustrative icon if available.
- Short human title.
- One useful explanation.
- One clear next action or refresh action when appropriate.

Do not use generic empty-state copy or plain centered icons as the final visual
treatment.

### Filter Strip

Use for list modes, unread filters, all/new filters, and view toggles.

Anatomy:

- Compact chips or segmented control.
- Selected state uses semantic tint and clear contrast.
- Unselected state remains soft and visible.
- Every visible filter must be functional.

Avoid decorative filters that do not change the content.

### Safety Action Panel

Use for block, report, unmatch, unblock, and safety explanations.

Anatomy:

- Serious soft color palette.
- Clear consequence text.
- Explicit action labels.
- Destructive action visually separated and confirmed when needed.
- No playful decoration that weakens seriousness.

### Chat Bubble / Grouping

Use for conversation threads.

Anatomy:

- Clear sender/recipient distinction.
- Compact date or status grouping.
- Friendly bubbles with subtle color.
- Message content remains the visual priority.
- Input/action area stays close to the conversation task.

Avoid turning chat into a metric dashboard or overdecorated card stack.

### Profile Summary

Use for current-user and other-user profile surfaces.

Anatomy:

- Person identity first.
- Real media or polished avatar when useful.
- Compact chips for active, verified, location, distance, profile readiness, and
  other truthful signals.
- Grouped sections for details, preferences, safety, and actions.
- Edit/review actions visible but not louder than identity and status.

## Screen Intent Guidance

### Data And Status Screens

Examples: Stats, Achievements, progress, readiness, high-level activity.

Use richer color density here:

- Compact summary area.
- Semantic metric colors.
- Data tiles with top/side accents.
- Section labels.
- Progress indicators, small chart-like details, rings, or bars.
- Small delight animations such as count-ups and progress fills.

These screens can be more expressive because the color helps the user parse
meaning quickly.

### Notifications And Status Feeds

Notifications are a core reference for the design language.

Use:

- Compact intro summary.
- Section labels for time or status groups.
- Per-item semantic colors.
- Left accent bars for unread or important state.
- Decorated icon chips.
- Compact type tags.
- Clear, quiet trailing actions.

The list should feel alive and colorful without becoming noisy.

### People And Social Screens

Examples: Browse, Matches, Pending Likers, Standouts, Profile, Chats.

Use people plus signals:

- Real media when it adds presence.
- Polished pastel avatars when media is absent.
- Compact status chips.
- Server-provided reasons and context.
- Location, active state, match state, and verification as small signals.
- Color-coded accents for relationship state and actions.

Do not invent compatibility, recommendation, or business logic client-side just
to make a card look richer. If the API does not provide a signal, use available
truth or call out the backend contract gap.

### Messaging Screens

Messaging should feel personal and calm:

- Compact participant context.
- Clear message grouping.
- Friendly bubbles without excessive decoration.
- Subtle color to distinguish sender, recipient, status, or date groups.
- Keep actions near where they are used.

Avoid turning chat into a dense dashboard. The design should support reading
and replying first.

### Forms And Editing Screens

Forms should be calmer than display screens, but still expressive:

- Clear section grouping.
- Softer pastel accents.
- Muted icon chips.
- Helpful status and validation colors.
- Consistent field rhythm.
- Primary action clearly visible.

Do not make forms plain and gray. Also do not make them as visually loud as a
stats or achievements screen.

### Settings And Utility Screens

Settings and utility screens should be practical, compact, and polished:

- Useful grouped rows.
- Decorated icons.
- Compact descriptions.
- Subtle color per category.
- No oversized marketing-style intro areas.

Developer-only or internal controls must be visually separated from user-facing
product controls.

### Safety And Moderation Screens

Safety screens should be serious, soft, and clear:

- Use rose, coral, slate, and muted warning tones.
- Reserve strong red for immediate destructive confirmation.
- Keep actions explicit.
- Avoid playful treatment that weakens the seriousness of block/report/unmatch.

## Typography And Hierarchy

Hierarchy should come primarily from color and grouping, then typography, then
media.

Approximate balance:

- 70 percent color and grouping.
- 22 percent typography.
- 8 percent media scale.

Use typography consistently:

- Titles are bold but not oversized by default.
- Section labels are compact and strong.
- Numbers, names, and important states carry visual weight.
- Supporting text uses `onSurfaceVariant` or an equivalent muted color.
- Avoid using huge text to compensate for weak structure.

## Motion

Motion should provide small delight:

- Count-ups.
- Progress fills.
- Selection transitions.
- Chip state transitions.
- Subtle list or card polish.

Motion should not slow the app down, distract from reading, or make routine
screens feel theatrical.

## Implementation Rules

### Use Existing Tokens First

Prefer existing `AppTheme` spacing, radius, surface, shadow, and color helpers.
Keep styling centralized when a pattern repeats across screens.

If the target design language needs a reusable token or helper that does not
exist, future agents may carefully update `AppTheme`. Theme changes must be:

- Centralized.
- Named by meaning, not by one screen.
- Verified against light and dark mode.
- Used by more than one component or justified as a real system primitive.

### Use Shared Widgets When They Fit

Shared widgets are valuable, but they are not more important than the target
visual outcome. If a shared widget encodes an outdated pattern, do not force it
onto a screen. Improve it or use a better structure.

If a shared intro, card, or list widget inherits the wrong semantic color for a
screen, customize locally or extend the widget. Shared structure is not a
reason to accept wrong color meaning, excess height, or missing route context.

Decision rule:

- Use the shared widget unchanged when it already matches this document.
- Improve the shared widget when the same improved pattern will serve multiple
  screens.
- Compose locally when only one screen needs a specialized structure.
- Do not add a new shared abstraction just to avoid writing a few lines of clear
  screen-specific UI.

### Keep Backend Ownership Clear

The Flutter client owns presentation, navigation, local UI state, request
orchestration, and modest polling.

Do not implement backend-owned business logic in Dart just to enrich UI:

- Compatibility.
- Match recommendations.
- Moderation decisions.
- Stats and achievements.
- Notification routing beyond known safe payloads.
- Server-provided reasons.

If richer UI needs missing data, document the backend contract gap.

## Anti-Patterns

Avoid these:

- Blank `ShellHero` slabs.
- Large top panels that consume around 20 percent of the screen without useful
  content.
- One-color mauve, pink, or rose screens.
- White-heavy screens that feel unfinished.
- Fully color-filled screens that feel overwhelming.
- Oversized low-information cards.
- Generic undecorated icons.
- Decorative gradients that do not explain state or action.
- Multiple equally loud CTAs in the same card.
- Pushed secondary routes without a visible back affordance or route context.
- Invisible default-height app bars used only to reserve space for actions.
- Repeated "tap here" instructional copy where the card affordance is clear.
- Forcing the same component pattern onto every screen.
- Client-invented reasons, compatibility, status, or metrics.

## Visual Review Checklist

Before marking UI design work or a screen-transform prompt implemented, compare
the result against the three run-0070 canonical reference screenshots and check:

- Does the first viewport show useful state and real content quickly?
- Are headers compact and useful rather than large low-information panels?
- If the screen is pushed as a route, does it provide a back affordance and a
  compact route title or equivalent context?
- Is any app-bar space visible and useful, rather than invisible blank chrome?
- Is there visible pastel color variety without one-color mauve/pink sameness?
- Does color follow semantic meaning consistently, using the entity/state map as
  the starting point?
- Are cards built from the surface layer recipe rather than plain white or fully
  color-filled by default?
- Are icons decorated, colorful, and meaningful?
- Are section labels or grouping cues clear?
- Are CTAs visually ranked instead of competing?
- Does dark mode keep the same personality with softer color?
- Are there any blank hero slabs or one-color mauve/pink screens?
- Did the work avoid inventing backend-owned product logic?

For UI changes, run the visual-review workflow when feasible and inspect the
generated PNGs, not only widget tests:

```powershell
flutter test test/visual_inspection/screenshot_test.dart
```

Use this document as the review rubric during screenshot inspection.

## Maintenance

Update this document when the target visual language changes or when new
reference screenshots replace the current canon. If a screenshot becomes the
new source of taste, copy it into `design-reference/` before referencing it
here.

Do not append contradictory notes. Replace stale guidance so future agents have
one clear source of truth.

*Last updated: 2026-04-28 - target reference set: Stats and Notifications run-0070.*
