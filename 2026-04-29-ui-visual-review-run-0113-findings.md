# UI Visual Review Findings - Run 0113

## Implementation Status

Partial implementation completed and visually checked in `run-0116__2026-04-29__12-19-19`.

Items marked with ✅ were implemented and verified in the latest visual-review screenshots. Unmarked items still need follow-up in a later session.

Review date: 2026-04-29

Source screenshots: `visual_review/latest/`

Visual-review run: `run-0113__2026-04-29__11-22-03`

Reference rubric:

- `docs/design-language.md`
- `design-reference/stats-run-0070-reference.png`
- `design-reference/notifications-run-0070-reference.png`
- `design-reference/notifications-dark-run-0070-reference.png`

Scope: read-only visual review. No implementation changes were made.

## Overall Assessment

The current UI is moving in the right direction. The best screens now show the intended design language: compact useful state, soft pastel surfaces, semantic color, decorated icon chips, section labels, and higher first-viewport density.

The strongest current examples are:

- `stats__run-0113.png`
- `notifications__run-0113.png`
- `notifications_dark__run-0113.png`
- `achievements__run-0113.png`

The main remaining issue is consistency. Some screens are already close to the run-0070 reference direction, while others still carry older patterns: large cards for small amounts of information, pink/mauve sameness, horizontally clipped chips, content hidden behind bottom chrome, and secondary routes that need stronger navigation context.

## Highest Priority Fixes

Fix these before deeper visual polish:

1. ✅ `shell_discover__run-0113.png` has clipped reason chips in the "Why this profile is shown" panel. The third chip is cut off at the right edge.
2. ✅ `profile_other_user__run-0113.png` has clipped reason chips in the "Why this profile is shown" panel. The "Same..." chip is cut off.
3. ✅ `profile_edit__run-0113.png` has a sticky "Save changes" bar overlapping the Distance section. The helper text is partially hidden behind the bottom action area.
4. ✅ `conversation_thread__run-0113.png` has a bad replacement glyph at the end of the final visible message after "until then".
5. ✅ `shell_profile__run-0113.png` shows the "Profile details" cards cut off behind the bottom navigation. The screen needs enough bottom padding or a capture-safe layout.
6. ✅ `shell_matches__run-0113.png`, `shell_matches_dark__run-0113.png`, and `shell_chats__run-0113.png` show list content partially obscured by the bottom navigation. This reads as insufficient bottom inset even if the live screen can scroll.
7. ✅ `shell_matches_dark__run-0113.png` makes the "View profile" secondary button too dark. It reads close to disabled instead of a normal secondary action.
8. ✅ `profile_other_user__run-0113.png` does not show a back affordance in the capture. If this is a pushed route in real use, it needs visible route context and navigation.
9. `conversation_thread__run-0113.png` has a thin teal divider under the header that feels detached from the rest of the screen. It reads like a leftover boundary rather than intentional route chrome.

## Cross-Screen Issues

### Bottom Chrome And Insets

Status: ✅ Implemented for the affected shell captures in `run-0116`.

Several shell tabs appear to let content sit underneath the bottom navigation:

- Matches
- Matches dark mode
- Chats
- Profile

This creates a visible cut-off at the bottom of the screenshots. Even if this is caused by the screenshot stopping mid-scroll, the visual review output should show enough bottom breathing room for the final visible card or row.

Recommendation: standardize bottom padding for shell-scrollable content so the bottom nav never covers meaningful content in visual review captures or real use.

### Horizontal Chip Overflow

Status: ✅ Implemented for Discover and other-user profile in `run-0116`.

The "Why this profile is shown" chip rows are too fragile at the visual review width.

Affected screens:

- Discover
- Other-user profile

Recommendation: make reason chips wrap cleanly, reduce chip padding, cap label length, or move reasons into a vertical compact list when there are several labels.

### Pink And Mauve Sameness

Several screens still lean too heavily on one pink/mauve family:

- Verification
- Pending likers
- Blocked users
- Other-user profile
- Parts of Settings
- Parts of Profile

The design language says pink is a semantic hue, not the base of the app. These screens need more semantic color variety: blue for profile/location, green for active/trust, teal for messaging, coral/slate for safety, violet/amber for milestones.

### Oversized Cards For Low Information

Some cards consume a lot of vertical space without enough useful state:

- Pending liker cards
- Matches cards
- Profile ready card
- Some Standouts cards
- Backend/dev-user startup surfaces

Recommendation: tighten row anatomy, reduce repeated copy, use compact status chips, and reserve tall cards for genuinely content-rich or emotional moments.

### Placeholder Media Treatment

Several media areas still feel like placeholders rather than polished product fallbacks:

- Discover candidate media block
- Other-user profile photo failure tiles
- Large initial avatars in people cards

Recommendation: improve fallback media styling with more intentional pastel avatar/photo states, semantic chips, and less generic "unable to load photo" presentation.

### Route Context

Secondary screens vary in how connected they feel to the app.

Concern areas:

- Other-user profile
- Conversation thread
- Verification
- Location
- Profile edit

Recommendation: pushed routes should consistently show a compact title plus back affordance in real use. Standalone visual-review captures can omit the back button only if the screen still has clear route identity.

## Screen-By-Screen Findings

### Stats

Screenshot: `stats__run-0113.png`

Status: strong reference-quality screen.

What works:

- Closely matches the run-0070 reference.
- Compact useful header.
- Good semantic metric colors.
- Good section label pattern.
- Metric/status tiles feel colorful without becoming noisy.

Issues:

- No major issues found in the screenshot.

Recommendations:

- Treat this as one of the current benchmark screens.
- Preserve the density, tile anatomy, and semantic color split when updating related status/data screens.

### Notifications

Screenshots:

- `notifications__run-0113.png`
- `notifications_dark__run-0113.png`

Status: strong reference-quality screens.

What works:

- Compact summary area.
- Good unread/read action hierarchy.
- Strong semantic icon chips and accent bars.
- Section labels are clear.
- Dark mode keeps personality and semantic color.

Issues:

- No major new issues found. The visible bottom of the feed is cut by the screenshot, but the content itself is not visibly broken.

Recommendations:

- Keep this as the canonical list/feed pattern.
- Reuse its row anatomy for settings, safety, conversations, and other compact list surfaces where appropriate.

### Achievements

Screenshot: `achievements__run-0113.png`

Status: strong.

What works:

- Summary card has useful state and progress.
- Milestone rows have clear icon chips, status tags, and progress signals.
- The screen feels more celebratory than Stats without losing structure.

Issues:

- The screen leans heavily into violet/pink surfaces, though amber helps.
- The top summary gradient is close to the upper limit of color density but still acceptable for a milestone screen.

Recommendations:

- Keep the general structure.
- Slightly increase amber/green semantic variety if more achievement states are added.

### Discover

Status: ✅ Clipped/crowded reason panel fixed in `run-0116`; fallback media polish remains open.

Screenshot: `shell_discover__run-0113.png`

Status: directionally good but has layout defects.

What works:

- Header is compact and useful.
- Candidate card has a strong visual anchor.
- Active/location chips help expose people-plus-signals.
- Like/pass actions are clear and visually ranked.

Issues:

- The reason chip row in "Why this profile is shown" overflows horizontally; the third chip is clipped.
- The "Why this profile is shown" panel is too cramped inside the candidate card.
- The reason text is close to the fixed action row and appears visually squeezed.
- The media block still feels like a generated placeholder rather than a product-grade person fallback.
- The candidate card is very tall, so only one candidate is visible and the bottom of its explanation area is crowded.
- The yellow/orange gradient competes with the person identity rather than supporting it.

Recommendations:

- Fix reason chip wrapping first.
- Consider moving reasons below the action row or making them a compact vertical signal list.
- Refine the fallback person media treatment so it feels intentional when real photos are missing.
- Reduce the height of the media area or the reason panel so the card breathes before the action row.

### Matches

Status: ✅ Bottom inset and dark secondary button issue fixed in `run-0116`; density was improved but can still be refined later.

Screenshots:

- `shell_matches__run-0113.png`
- `shell_matches_dark__run-0113.png`

Status: solid structure, too tall and somewhat repetitive.

What works:

- Good people-card direction.
- Match age, location, active state, and match date are visible.
- Primary message action is clear.
- Dark mode has personality and is not flat.

Issues:

- Bottom navigation obscures the next card in both light and dark captures.
- Cards are tall for the amount of information.
- Large avatars, multiple chips, overflow button, and two large action buttons make each match consume too much vertical space.
- Dark-mode "View profile" button reads too disabled because it is nearly black.
- The filter row feels slightly detached from the list because there is a large gap below the header.
- The active dot on the avatar duplicates the "Active now" chip.

Recommendations:

- Add bottom inset for nav-safe scrolling.
- Tighten match card anatomy: smaller avatar, more compact chip row, or one primary action plus quieter secondary cue.
- Tune dark secondary button colors so "View profile" remains visibly available.
- Consider removing either the avatar active dot or the active chip when both are present.

### Chats

Status: ✅ Bottom inset, heavy date pills, and avatar badge noise addressed in `run-0116`.

Screenshot: `shell_chats__run-0113.png`

Status: good semantic direction, needs polish.

What works:

- Teal message color is a good semantic anchor.
- Header is compact and useful.
- Rows are readable.
- Message-count chips help scanning.

Issues:

- Bottom navigation cuts off the lower conversation row.
- The small chat badge attached to each avatar feels awkwardly placed and visually busy.
- Rows are somewhat tall for simple conversation summaries.
- Date pills are visually heavy compared with the row content.
- Every row repeats a message-count chip; useful, but it adds vertical height and may be redundant with the summary copy.

Recommendations:

- Add nav-safe bottom padding.
- Simplify avatar/chat-badge treatment.
- Consider making message counts trailing metadata or a smaller inline tag.
- Reduce row height while preserving the semantic teal accent.

### Conversation Thread

Status: ✅ Bad replacement glyph fixed in `run-0116`; remaining header/scroll polish can be revisited later.

Screenshot: `conversation_thread__run-0113.png`

Status: readable and calm, with specific defects.

What works:

- Message bubbles are readable.
- Sender/recipient distinction is clear.
- Date divider is compact.
- Composer placement is close to the task.

Issues:

- Bad replacement glyph appears at the end of the final visible message.
- Header feels cramped at the very top of the capture.
- The thin teal divider below the header feels misplaced or accidental.
- The overflow menu is visible, but the route context could be stronger if this is a pushed screen.
- Composer is very large and pale compared with the bubbles; it reads more like a card than an input.
- Send button is disabled-looking even though it may be empty-state behavior.

Recommendations:

- Fix the message text/glyph issue.
- Rework the header divider so it either becomes intentional route chrome or disappears.
- Tune composer styling to feel like an input, not a large bottom card.
- Verify real navigation includes a back affordance.

### Profile

Status: ✅ Profile details are visible above bottom chrome and readiness progress is labeled in `run-0116`.

Screenshot: `shell_profile__run-0113.png`

Status: improved but too vertically expensive.

What works:

- Header is compact and clear.
- Identity card has useful chips and profile context.
- Profile-ready state is understandable.
- Edit and refresh actions are visible.

Issues:

- Bottom navigation cuts into the "Profile details" section.
- The "Profile ready" card is tall for a simple readiness message and one action.
- The top half of the screen has multiple large blocks before detailed profile content appears.
- The screen leans pink/mauve with limited color variety beyond blue/green chips.
- The progress bar at the bottom of the identity card is visually unexplained in the screenshot.

Recommendations:

- Add bottom inset for nav-safe scrolling.
- Compress "Profile ready" into a smaller status row or merge it into the identity card if appropriate.
- Bring more useful profile details into the first viewport.
- Label or contextualize the progress bar if it remains prominent.

### Other-User Profile

Status: ✅ Back affordance and reason-chip wrapping fixed in `run-0116`; photo fallback polish remains open.

Screenshot: `profile_other_user__run-0113.png`

Status: usable, but several layout and polish issues.

What works:

- Profile identity is clear.
- Active, location, and distance chips are useful.
- Reason panel is valuable and aligned with the backend-driven explanation goal.

Issues:

- No visible back affordance in the capture.
- Reason chips overflow horizontally; the final chip is clipped.
- Photo failure tiles look unfinished and generic.
- The screen is very pink/mauve-heavy.
- The photo card consumes a lot of space despite only showing failures.
- The overflow menu and refresh action are at the top, but the title/back/navigation context is weak.

Recommendations:

- Fix chip wrapping.
- Add or verify a visible back affordance in real pushed-route usage.
- Replace "Unable to load photo" tiles with a more polished fallback photo state.
- Reduce the photo card height when photos are unavailable.
- Add more semantic color variety beyond pink/mauve.

### Profile Edit

Status: ✅ Sticky save overlap fixed in `run-0116`.

Screenshot: `profile_edit__run-0113.png`

Status: good form direction, but bottom action overlap is a blocker.

What works:

- Clear title and identity summary.
- Form sections are grouped well.
- Gender and interest controls are readable.
- Primary save action is obvious.

Issues:

- Sticky "Save changes" bar overlaps the Distance section helper text.
- Bottom inset is insufficient for the fixed action area.
- The Distance section is partially hidden, so the screen cannot be judged as polished.
- The form is calmer than display screens, which is good, but it may be a little too pink.
- Segmented chips are readable, but there is a lot of repeated vertical spacing.

Recommendations:

- Fix bottom padding around the sticky save bar first.
- Keep form sections calm, but introduce slightly more semantic color where fields represent different domains.
- Tighten vertical spacing after the overlap is fixed.

### Settings

Screenshot: `shell_settings__run-0113.png`

Status: good utility screen direction.

What works:

- Developer-only section is clearly separated.
- Quick access rows are useful and compact.
- Icons are decorated and semantic.
- Current user and theme state are visible.

Issues:

- Bottom navigation cuts off the lower quick-access list.
- The screen still leans pink/pale overall.
- The top Settings header is compact but perhaps too sparse compared with the stronger Quick access card below.
- Row chevrons use different colors, which helps semantics, but may become visually noisy if more rows are added.

Recommendations:

- Add bottom inset for nav-safe scrolling.
- Preserve the dev-only separation.
- Keep quick-access row anatomy as a reference for other utility lists.
- Add restrained semantic variety without turning the list into a rainbow.

### Verification

Status: ✅ Trust-color direction, progress connection, and CTA color improved in `run-0116`.

Screenshot: `verification__run-0113.png`

Status: clean, but too one-color and slightly heavy.

What works:

- Step state is clear.
- Form flow is understandable.
- Input and CTA are prominent.
- "How it works" section is useful.

Issues:

- The screen is dominated by rose/mauve tones.
- The primary button is visually heavy and somewhat serious for a trust/verification flow.
- The progress indicator under the intro card feels disconnected from the "Step 1 of 2" pill.
- The first card is large for the amount of state it communicates.
- The icon treatment is more muted than the stronger reference screens.

Recommendations:

- Introduce trust colors: green, blue, or muted violet, not only rose.
- Tie the progress indicator more clearly to the step state.
- Make the intro card more compact or richer with meaningful verification state.
- Consider a stronger decorated verification icon chip.

### Location

Status: ✅ Country field spacing and toggle density improved in `run-0116`.

Screenshot: `location_completion__run-0113.png`

Status: practical and mostly polished.

What works:

- Blue location accent is semantically appropriate.
- Suggested cities section is compact and useful.
- Primary CTA is clear.
- Inputs are readable.

Issues:

- The toggle block is large and gray compared with the rest of the form.
- The form card consumes a lot of vertical space, leaving only two suggestions visible.
- The country dropdown label placement is close to the field border and feels a little cramped.
- The page has limited route context beyond the title.

Recommendations:

- Slightly tighten the toggle treatment.
- Keep the blue semantic direction.
- Consider bringing suggestions a little higher by reducing form card height.

### Pending Likers

Screenshot: `pending_likers__run-0113.png`

Status: readable, but too sparse and too pink.

What works:

- Count and state are clear.
- User cards are easy to scan.
- Overflow menus are available.

Issues:

- Cards are very tall for name, short bio, one location chip, and one action.
- The screen is heavily pink/mauve.
- "Open profile" appears as repeated text action, making the lower half of each card feel empty.
- Active/pending/attraction signals could be more compact and richer.
- Large avatar rings consume space without adding enough information.

Recommendations:

- Compress liker cards into denser people rows or smaller cards.
- Add semantic variation for pending/affinity/location states.
- Make "Open profile" a quieter trailing cue or compact button.
- Preserve overflow safety/context actions.

### Standouts

Status: ✅ Intro repetition and profile action wording reduced in `run-0116`; card/media polish remains open.

Screenshot: `standouts__run-0113.png`

Status: good but still somewhat oversized.

What works:

- Ranking badges are useful and visually clear.
- List/grid toggle is visible.
- Person cards have stronger personality than older plain cards.
- Server-provided reason text is prominent.

Issues:

- Intro card repeats the screen title and includes instructional copy that feels unnecessary.
- Person cards are tall and leave large open areas.
- "Open profile" repeated as text action feels less polished than the rest of the card.
- Fallback media blocks are colorful but still generic.
- The screen has a warm beige/pink cast and could use more semantic variety.

Recommendations:

- Remove or shrink instructional copy if the interaction is obvious.
- Tighten card height.
- Consider making "Open profile" a trailing cue or compact CTA.
- Improve fallback media treatment.

### Blocked Users

Status: ✅ Primary unblock task is clearer in `run-0116`; broader same-color safety palette refinement remains open.

Screenshot: `blocked_users__run-0113.png`

Status: clear and serious, but too same-color.

What works:

- Safety context is clear.
- Blocked count is visible.
- Each row explains the consequence.
- The tone is serious without being harsh.

Issues:

- Rows are nearly identical rose blocks, so reasons do not scan distinctly.
- The row action is hidden behind overflow, which may be correct, but the available action is not obvious from the screenshot.
- The header card is large for one count and explanation.
- Icons are consistent but repetitive.

Recommendations:

- Keep the serious safety palette, but introduce slate/coral variation by reason or state.
- Consider clearer unblock affordance if that is the primary task.
- Tighten header height if no additional state is needed.

### App Startup / Dev User Picker

Status: ✅ Backend status density and "No selection" wrapping improved in `run-0116`.

Screenshot: `app_home_startup__run-0113.png`

Status: functional, but could be denser.

What works:

- Developer-only status is clear.
- Backend status is visible.
- Available profiles are easy to choose.
- No selected profile state is explicit.

Issues:

- The backend-online banner is large for a simple status plus Refresh action.
- The page has a lot of vertical space after the two available profiles, which makes the top cards feel heavier.
- The developer sign-in card has multiple chips and explanatory copy; useful for internal flow, but visually bulky.
- The "No selection" chip sits far to the right and may become fragile with longer localized text.

Recommendations:

- Compact the backend status into a smaller row.
- Keep developer-only labeling strong, but reduce repeated explanatory text.
- Ensure the "No selection" state wraps safely for longer labels.

## Second-Pass Additions

These were found or sharpened during the second pass after the initial review:

- ✅ `app_home_startup__run-0113.png`: backend-online status is oversized for its information value.
- ✅ `app_home_startup__run-0113.png`: "No selection" chip placement could become fragile if the label changes or localization expands.
- ✅ `shell_discover__run-0113.png`: the reason panel is not only clipped; it is also crowded against the fixed action row, making the bottom of the candidate card feel cramped.
- `shell_discover__run-0113.png`: the yellow/orange media gradient competes with identity content and does not yet feel like a polished person fallback.
- `profile_other_user__run-0113.png`: photo failure state consumes too much space and looks unfinished.
- ✅ `shell_profile__run-0113.png`: the profile progress bar is prominent but not self-explanatory in the screenshot.
- ✅ `shell_chats__run-0113.png`: date pills are visually heavy relative to conversation summaries.
- ✅ `shell_chats__run-0113.png`: the per-row chat badge attached to avatars creates visual noise.
- ✅ `verification__run-0113.png`: the progress line under the intro card does not feel clearly connected to the "Step 1 of 2" state.
- ✅ `location_completion__run-0113.png`: country label placement is slightly cramped against the field border.
- ✅ `standouts__run-0113.png`: intro repeats the screen title and spends space on instructions that could be reduced.
- ✅ `blocked_users__run-0113.png`: the primary user task may be unclear because row actions are hidden behind overflow.

## Suggested Work Order

1. ✅ Fix hard layout defects: clipped chips, bad glyph, sticky save overlap, bottom nav insets.
2. ✅ Normalize shell scroll padding so bottom navigation never hides content.
3. Reduce one-color pink/mauve sameness on Verification, Pending Likers, Blocked Users, and Other-User Profile.
4. Tighten people-card density on Matches, Pending Likers, Standouts, and Chats.
5. Improve fallback media/photo states.
6. Review route context and back affordances for pushed screens.
7. Re-run the visual-review workflow and compare against the run-0070 reference set.
