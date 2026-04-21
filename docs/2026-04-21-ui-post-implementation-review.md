# UI post-implementation review — run 0013

Date: 2026-04-21

Reviewed artifacts:
- `build/visual_review/latest/*__run-0013.png`
- previous review in `docs/2026-04-21-ui-visual-review.md`
- completed implementation plan in `docs/superpowers/plans/2026-04-21-ui-polish-implementation.md`

Verification evidence:
- `flutter analyze` → no issues found
- `flutter test` → `00:22 +150: All tests passed!`
- `flutter test test/visual_inspection/screenshot_test.dart` → 17 screenshot checks passed
- fresh visual run captured as `run-0013`

## Overall read

This pass materially improved the app.

The UI now feels much more like one intentional product system and much less like a collection of individually decent screens. The strongest improvements came from the shared layout foundation:
- shared hero/header treatment
- shared intro framing for sparse screens
- tighter spacing tokens and denser shell chrome
- more human user-facing copy
- friendlier timestamps and labels

The result is not “finished forever” — no UI ever is, mostly because design likes job security — but it is clearly stronger than the earlier `run-0007` review baseline.

Just as important: the final screenshot run is visually stable. The last blocking regression during verification was the notifications overflow, and that is now fixed in `run-0013`.

## What is clearly better now

### Cross-cutting improvements

- **Shared hero language is much more consistent.** Screens now look related on purpose instead of coincidentally.
- **Shell copy is more product-facing.** The app speaks to the user instead of sounding like it is narrating backend plumbing.
- **Enums and raw state labels are much more humanized.** Values such as gender, status, dates, and activity labels read like product UI now.
- **Action hierarchy is stronger.** Primary actions such as `Message now`, `Open chat`, and `Save changes` are easier to identify.
- **Utility surfaces are denser and more intentional.** `Stats`, `Achievements`, `Verification`, `Blocked users`, and `Notifications` no longer feel like stub screens.
- **Bottom navigation and shell framing are lighter than before.** The shell still has room to tighten further, but it is improved.
- **No obvious screenshot breakage remains.** The final run shows no visual overflows, clipped controls, or broken layout states.

### What from the original review is now fixed

| Original review goal                  | Status          | Notes                                                                                   |
|---------------------------------------|-----------------|-----------------------------------------------------------------------------------------|
| Shrink main-shell chrome              | Partially fixed | Shell tabs are lighter, but several are still a bit hero-heavy.                         |
| Introduce a shared header/hero system | Fixed           | The new shared hero treatment is visible across shell and detail surfaces.              |
| Define and enforce spacing tokens     | Fixed           | The UI reads more systemized and less hand-tuned.                                       |
| Rebalance action hierarchy            | Mostly fixed    | Primary CTAs are clearer, though a few screens still duplicate interaction affordances. |
| Densify sparse utility screens        | Fixed           | Utility/supporting screens are meaningfully more intentional now.                       |
| Normalize user-facing copy and labels | Mostly fixed    | Most raw/internal language is gone, with a few notable leaks still remaining.           |

## What still is not fully fixed

These are no longer blocker-level issues. They are the next polish pass.

### 1. The shell is better, but still slightly top-heavy

`Discover`, `Matches`, `Chats`, `Profile`, and `Settings` still spend a little too much vertical space on hero framing before the main content takes over. This is most noticeable on:
- `Discover`, where the daily-pick and action tray still fight the actual browse content
- `Profile`, where summary cards still dominate above-the-fold space
- `Settings`, where the session block still pushes destinations downward

### 2. Some screens still use too much framing for the amount of content shown

The new intro cards helped sparse screens a lot, but a few now verge on being over-framed:
- `Verification`
- `Blocked users`
- `Notifications`
- `Stats`

The rule for the next pass should be simple: **one intro block before core content is enough on utility screens**.

### 3. A few dev/back-end flavored strings still leak through

The biggest remaining copy leaks are:
- `Backend rank suggests high reply odds this week` on `Standouts`
- `A tidy, read-only view of the account signals the backend is already tracking for this user.` on `Stats`
- `Debug helpers stay separate` on `Verification`

Those lines stand out more now precisely because the rest of the copy got much better.

### 4. Interaction patterns still need one more consistency pass

Some cards still present both a row-level navigation hint and a separate CTA, which makes the screen feel slightly indecisive.

Most obvious examples:
- `Standouts`
- `People who liked you`
- a few shell/detail cards that still combine tappable-card energy with a detached button

### 5. Conversation thread is still the weakest layout in the set

`conversation_thread__run-0013.png` is better than before, but it still has:
- too much empty middle space
- a composer block that feels oversized for a short thread
- a chat layout that still looks more staged than naturally inhabited

It no longer feels broken, but it still looks least mature relative to the rest of the UI.

## What has been fixed from the original review

### Fixed or strongly improved

- Shared header/hero treatment across many surfaces
- Shared intro framing for sparse screens
- Human-readable profile/status labels
- Friendlier date formatting and notification timestamps
- Denser utility surfaces
- Better shell CTA hierarchy
- Cleaner dev-user picker rows
- More intentional current-user profile maintenance state
- Better verification flow structure
- Notifications overflow regression during final verification

### Improved but not fully closed

- Shell chrome density
- Content-first layout on `Discover`
- Detail density in `Profile`
- Conversation thread composition
- Interaction consistency on list/detail cards
- Removal of every remaining backend/dev-flavored phrase

## Screen-by-screen review

### 1. Dev-user picker

**What is good now**
- Better persistence guidance
- stronger row affordance
- richer avatar treatment
- clearer startup framing

**What is still weak**
- each row still has a bit too much “tap here / continue / chevron” signaling at once

**Next change**
- choose one dominant row interaction model and simplify the secondary hints

### 2. Discover

**What is good now**
- friendlier headline and support copy
- stronger chip hierarchy
- more unified shell treatment

**What is still weak**
- still too much stacked chrome above the candidate content
- the candidate card is not yet the clear above-the-fold hero of the screen

**Next change**
- reduce hero height again and let the browse target own more vertical space

### 3. Matches

**What is good now**
- `Message now` reads like a real primary action
- status/date chips are more readable
- overall screen feels more productized

**What is still weak**
- `For Dana` is still redundant
- the top-right utility icons on the card are still a little opaque

**Next change**
- remove redundant ownership metadata and simplify card utilities

### 4. Chats

**What is good now**
- much cleaner than before
- inbox action is obvious
- hero copy is stronger

**What is still weak**
- recency is shown twice (`Apr 18, 2026` and `Updated Apr 18, 2026`)
- the screen still feels airy for a one-thread state

**Next change**
- keep one recency treatment and let the conversation preview carry more of the card

### 5. Current-user profile

**What is good now**
- better hero treatment
- `Profile ready` is a stronger maintenance-state concept than the earlier checklist feel
- labels are more human-readable

**What is still weak**
- there is still too little actual profile detail above the fold
- duplicate edit entry points remain a little close to each other

**Next change**
- surface a short bio/preferences preview higher on the screen and demote one edit affordance

### 6. Settings

**What is good now**
- current-session framing is clearer
- settings destinations are cleaner and more understandable
- `Switch profile` is less overpowering than before

**What is still weak**
- the session card still uses a lot of space
- the screen is still slightly split between “hero summary” and “destinations list”

**Next change**
- compress the session module further and pull the destinations higher

### 7. Conversation thread

**What is good now**
- duplicate identity text was reduced
- timestamps are calmer
- the composer is clearer than before

**What is still weak**
- too much empty vertical middle space remains
- the composer card is still oversized

**Next change**
- anchor short threads lower, tighten the composer, and add stronger message grouping/date treatment

### 8. Standouts

**What is good now**
- stronger intro framing
- clearer rank/score presentation
- `Open profile` is easier to find

**What is still weak**
- one standout reason still sounds backend-authored
- chevron plus CTA still duplicates the interaction model

**Next change**
- rewrite standout reasons into fully user-facing language and choose either full-card navigation or a dedicated CTA, not both

### 9. People who liked you

**What is good now**
- no longer feels like a placeholder list
- stronger framing and count summary
- clearer profile CTA

**What is still weak**
- repeated subtitle text is still generic
- chevron plus CTA duplicates interaction intent

**Next change**
- vary the supporting copy with recency/context and simplify the navigation model

### 10. Other-user profile

**What is good now**
- labels are humanized
- hero card is cleaner and warmer
- overall read is less admin-ish

**What is still weak**
- the page still becomes a long stack of visually similar cards

**Next change**
- group related facts into fewer, richer sections so the page feels more authored than list-like

### 11. Profile edit

**What is good now**
- much better user-facing intro copy
- cleaner labels than before
- clearer location handoff
- save CTA is solid

**What is still weak**
- still feels like a generic stack of fields
- several values would be better as chips/pickers than freeform form rows

**Next change**
- split the form into `About`, `Preferences`, and `Location`, and replace enum-like inputs with stronger controls

### 12. Location completion

**What is good now**
- warmer and clearer framing
- stronger explanation of what location is used for
- suggestions area is visible and understandable

**What is still weak**
- the country row leading treatment still looks slightly awkward
- the save CTA could still be a touch more assertive

**Next change**
- clean up the country selector leading content and consider a wider CTA treatment

### 13. Stats

**What is good now**
- much more intentional than before
- values are easier to scan
- intro framing gives the screen structure

**What is still weak**
- still uses backend-facing language
- still feels like a nicer snapshot rather than a fully productized stats surface

**Next change**
- rewrite the explanatory copy into user value language and add denser grouping or lightweight trend context

### 14. Achievements

**What is good now**
- unlocked vs in-progress distinction is clearer
- cards now have more momentum and structure

**What is still weak**
- progress values like `3 / 3` and `87%` still feel visually detached from the rest of the card
- could still use more delight

**Next change**
- introduce a more visual progress treatment such as bars, rings, or aligned progress rows

### 15. Verification

**What is good now**
- much better guided flow
- the steps are clearer
- method selection is easy to understand

**What is still weak**
- `Debug helpers stay separate` still reads like internal UI
- hero + explainer + form stack is slightly longer than it needs to be

**Next change**
- remove or quarantine the debug/helper messaging more aggressively and compact the intro stack

### 16. Blocked users

**What is good now**
- much better safety framing
- unblock action is clearer and less floating
- the screen finally explains consequences

**What is still weak**
- the top section is still a little oversized for a one-row list
- the `Pull to refresh` chip feels unnecessary

**Next change**
- remove the refresh chip and shorten the intro so the list owns more of the screen

### 17. Notifications

**What is good now**
- friendlier timestamps
- stronger unread emphasis
- clearer intro framing
- the previous overflow is fixed

**What is still weak**
- the top framing + filter area still takes a lot of room before the feed starts
- read/unread state is improved, but could still be standardized further

**Next change**
- collapse the header/filter region into a tighter control area and unify the trailing read-state treatment more explicitly

## Recommended next refinement pass

If there is a follow-up pass, this is the order I would use:

1. **Compact shell pass**
   - reduce shell hero height again by about 20–25%
   - make `Discover` more content-first
   - trim `Profile` and `Settings` summary height

2. **Messaging and profile pass**
   - tighten `Conversation thread`
   - show more real profile content above the fold
   - section `Profile edit` into stronger form groups

3. **Copy cleanup pass**
   - remove remaining backend/dev phrases from `Standouts`, `Stats`, and `Verification`
   - simplify redundant metadata on `Matches` and `Chats`

4. **Interaction consistency pass**
   - choose one interaction model per card family
   - avoid chevron-plus-button duplication when both trigger the same thing

5. **Utility compaction pass**
   - keep the stronger framing
   - cap utility screens at one intro block before core content
   - compress `Notifications`, `Blocked users`, and `Verification`

## Bottom line

The UI polish work succeeded.

Compared with the original `run-0007` review, the app is now:
- more cohesive
- more user-facing
- more intentional on sparse surfaces
- more consistent in visual language
- fully green in analyzer, test, and screenshot verification

The remaining issues are mostly second-order polish decisions, not structural problems or regressions. The one screen that still most wants another design pass is `Conversation thread`, and the one cross-cutting theme still worth pursuing is **one more round of shell compaction**.
