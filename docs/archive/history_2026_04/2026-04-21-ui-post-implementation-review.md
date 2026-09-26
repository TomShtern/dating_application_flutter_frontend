# UI post-implementation review — run 0016

Date: 2026-04-22

Reviewed artifacts:
- `visual_review/latest/*__run-0016.png`
- previous review in `docs/2026-04-21-ui-visual-review.md`
- completed implementation plan in `docs/superpowers/plans/2026-04-21-ui-polish-implementation.md`

Verification evidence:
- `flutter analyze` → no issues found
- `flutter test` → `00:41 +161: All tests passed!`
- `flutter test test/visual_inspection/screenshot_test.dart` → `00:17 +17: All tests passed!`
- fresh visual run captured as `run-0016`

## Overall read

This second polish pass materially improved the app again.

The earlier implementation already established a stronger shared design language. The `run-0016` pass builds on that by fixing several of the remaining “almost there” issues:
- less redundant shell metadata
- cleaner row/action signaling
- better profile detail placement
- stronger stats and achievements communication
- more compact utility framing

The app now feels more like a coherent product and less like a polished prototype with a few developer leftovers still poking through. The screenshots are also visually stable: no overflows, no clipped controls, and no new regressions surfaced in the latest run.

Compared with the original `run-0007` baseline, the UI is clearly stronger. Compared with the earlier post-polish checkpoint in `run-0013`, the app is also cleaner, denser, and more deliberate in the places that still felt a little hesitant.

## What is clearly better now

### Cross-cutting improvements

- **Shared hero and section framing still hold the system together well.** The app reads as one product language instead of many local interpretations.
- **Shell surfaces are cleaner than before.** The dev-user picker is less over-signaled, the shell footer is a touch tighter, and redundant shell metadata was reduced.
- **Profile surfaces are better structured.** Real profile content now appears higher instead of hiding behind too much summary framing.
- **Action hierarchy is clearer.** `Message now`, `Open chat`, `Save changes`, and similar actions stand out more intentionally.
- **Utility screens now communicate value better.** `Stats`, `Achievements`, `Verification`, `Blocked users`, and `Notifications` all read more like owned product surfaces.
- **Copy quality is stronger.** Most backend/admin flavor has been removed from user-facing flows.
- **The app remains verification-clean.** Analyzer, full tests, and the screenshot suite are all green on the latest pass.

### What from the original review is now fixed

| Original review goal                  | Status       | Notes                                                                                       |
|---------------------------------------|--------------|---------------------------------------------------------------------------------------------|
| Shrink main-shell chrome              | Mostly fixed | Shell tabs are lighter and cleaner, though `Discover` still wants one more compaction pass. |
| Introduce a shared header/hero system | Fixed        | The shared hero treatment is now clearly established across shell and detail surfaces.      |
| Define and enforce spacing tokens     | Fixed        | The UI reads systemized rather than hand-tuned.                                             |
| Rebalance action hierarchy            | Mostly fixed | Primary CTAs are clearer and several duplicated affordances were removed.                   |
| Densify sparse utility screens        | Fixed        | Utility/supporting screens feel materially more intentional now.                            |
| Normalize user-facing copy and labels | Mostly fixed | Most internal/raw language is gone, though a few lines still want cleanup.                  |

## What still is not fully fixed

These are no longer blocker issues. They are the next refinement pass.

### 1. `Discover` is still the most top-heavy shell surface

The screen is cleaner than before, but the browse target still does not fully dominate above the fold. The main remaining pressure points are:
- the daily-pick block
- the developer/status framing
- the action tray under the candidate card

It looks better, but it still does not feel maximally content-first.

### 2. `Conversation thread` is still the weakest visual layout

The thread is improved, but it still has:
- too much empty middle space
- a composer that feels oversized for short threads
- a chat layout that still looks staged instead of naturally lived-in

This is still the one screen that most wants another focused design pass.

### 3. A few screens are better, but still slightly plush

The following are improved, yet still a little roomier than they need to be:
- `Settings`
- `Verification`
- `Notifications`
- `Blocked users`

They no longer feel unfinished, but they still spend a bit too much space on framing before the main content takes over.

### 4. A small amount of copy cleanup remains

Most backend/dev language is gone, but a few strings still deserve cleanup — especially in places like `Standouts`, and some supporting explanatory copy in utility flows.

### 5. A few surfaces still want richer personality, not just cleaner structure

The structural fixes worked well, but some screens could still feel more alive:
- `Achievements` could celebrate unlocked states more
- `Matches` could use slightly richer personality in the cards
- `Pending likers` could use more varied context per person

## What has been fixed from the original review

### Fixed or strongly improved

- Shared header/hero treatment across many surfaces
- Shared intro framing for sparse screens
- Human-readable profile/status labels
- Friendlier date formatting and notification timestamps
- Denser utility surfaces
- Better shell CTA hierarchy
- Cleaner dev-user picker rows
- Less redundant shell/profile metadata
- Better profile detail placement above the fold
- More intentional current-user profile maintenance state
- Better verification flow structure
- Stronger achievement progress treatment
- Notifications overflow regression during verification

### Improved but not fully closed

- Final shell chrome density
- Content-first layout on `Discover`
- Conversation density on `Chats`
- Conversation thread composition
- Final copy cleanup in a few screens
- Last-mile personality and delight in selected surfaces

## Screen-by-screen review

### 1. Dev-user picker

**What is good now**
- better persistence guidance
- stronger row affordance
- richer avatar treatment
- much cleaner interaction signaling than before

**What is still weak**
- the startup stack is still a little card-heavy for such a simple choice

**Next change**
- reduce or merge some status/current-profile framing so the actual choices start even sooner

### 2. Discover

**What is good now**
- friendlier headline and support copy
- more unified shell treatment
- less shouty developer/session framing

**What is still weak**
- still too much stacked chrome above the candidate content
- the candidate card is not yet the unquestioned above-the-fold focal point

**Next change**
- compress the top stack one more step so the browse target owns more vertical space

### 3. Matches

**What is good now**
- `Message now` reads like a true primary action
- status/date chips are cleaner
- the redundant owner badge is gone
- card actions feel more intentional now

**What is still weak**
- the remaining utility treatment still feels a little generic

**Next change**
- simplify or clarify remaining card utilities and add a little more personality to the match content itself

### 4. Chats

**What is good now**
- cleaner than before
- inbox action is obvious
- recency handling is less cluttered

**What is still weak**
- the screen still feels airy when only one thread is present

**Next change**
- nudge the single-thread state toward denser inbox behavior so it feels less empty

### 5. Current-user profile

**What is good now**
- better hero treatment
- `Profile ready` is a stronger maintenance-state concept
- labels are more human-readable
- real profile detail appears much earlier now

**What is still weak**
- duplicate edit entry points are still a little close to each other

**Next change**
- decide whether the app-bar edit action or the maintenance-card action is the one clearly primary edit path

### 6. Settings

**What is good now**
- current-session framing is clearer
- destinations are easier to reach earlier in the viewport
- `Switch profile` is better behaved visually now

**What is still weak**
- the session block is still slightly plush

**Next change**
- compress the session summary another small step so the destinations start even sooner

### 7. Conversation thread

**What is good now**
- duplicate identity text was reduced
- timestamps are calmer
- the thread is better anchored than before
- the composer is clearer

**What is still weak**
- too much empty middle space remains
- the composer is still oversized for short threads

**Next change**
- tighten the composer, reduce the empty center, and make short threads feel more naturally inhabited

### 8. Standouts

**What is good now**
- stronger intro framing
- clearer rank/score presentation
- the worst duplicated interaction signaling is reduced

**What is still weak**
- one standout reason still sounds backend-authored

**Next change**
- rewrite the remaining standout reason strings into fully user-facing language

### 9. People who liked you

**What is good now**
- no longer feels like a placeholder list
- stronger framing and count summary
- the card action model is cleaner than before

**What is still weak**
- supporting copy is still a bit generic from card to card

**Next change**
- use richer recency/context hints so each liker card feels less templated

### 10. Other-user profile

**What is good now**
- labels are humanized
- hero card is cleaner and warmer
- the page groups better now that profile detail appears sooner

**What is still weak**
- it still becomes a long stack of visually similar sections

**Next change**
- regroup related facts into fewer, richer content blocks so the page feels more authored than listed

### 11. Profile edit

**What is good now**
- much better user-facing intro copy
- clearer labels and handoff language
- the new sections are much stronger
- save CTA remains solid

**What is still weak**
- it still wants slightly tighter vertical rhythm inside the sections

**Next change**
- keep the new section structure and tighten the spacing/copy density inside each section

### 12. Location completion

**What is good now**
- warmer and clearer framing
- stronger explanation of location value
- country selector and primary action read more clearly than before

**What is still weak**
- the country row leading treatment still looks just a little awkward

**Next change**
- refine the selector leading treatment one more step and make the save CTA feel a touch more assertive

### 13. Stats

**What is good now**
- much more intentional than before
- values are easier to scan
- copy is much less backend-authored now

**What is still weak**
- it still feels more like a polished snapshot than a fully productized stats surface

**Next change**
- add lightweight comparison or trend context so it feels less static

### 14. Achievements

**What is good now**
- unlocked vs in-progress distinction is clearer
- cards have more momentum and structure
- the new progress treatment reads much better in `run-0016`

**What is still weak**
- unlocked achievements could still feel a little more celebratory

**Next change**
- keep the new bars and add slightly more delight/celebration for unlocked states

### 15. Verification

**What is good now**
- much better guided flow
- the steps are clearer
- method selection is easy to understand
- debug-only messaging is better quarantined than before

**What is still weak**
- hero + explainer + form stack is still slightly longer than it needs to be

**Next change**
- compact the stack a little more so the actionable part arrives faster

### 16. Blocked users

**What is good now**
- much better safety framing
- unblock action is clearer and less floating
- the unnecessary refresh framing is gone

**What is still weak**
- the intro is still slightly oversized for a one-row list state

**Next change**
- shorten the intro another small step so the blocked-user row owns the screen faster

### 17. Notifications

**What is good now**
- friendlier timestamps
- stronger unread emphasis
- clearer intro framing
- header/filter region is meaningfully tighter now
- the previous overflow remains fixed

**What is still weak**
- read/unread treatment is improved, but could still be standardized further

**Next change**
- unify the remaining read/unread visual treatment one more step

## Recommended next refinement pass

If there is a follow-up pass, this is the order I would use:

1. **Compact shell pass**
   - reduce shell hero height another 10–15% where it still feels plush
   - make `Discover` more content-first
   - trim `Settings` summary height another step

2. **Messaging pass**
   - tighten `Conversation thread`
   - make single-thread `Chats` states feel denser and more inhabited

3. **Copy cleanup pass**
   - remove the last backend-ish standout wording
   - simplify remaining explanatory/support text in utility surfaces

4. **Profile and detail rhythm pass**
   - keep profile detail high in the viewport
   - reduce duplicate edit affordance weight
   - tighten the new `Profile edit` sections vertically

5. **Delight pass**
   - add more celebration to unlocked achievements
   - give matches/pending-liker cards a little more personality without adding clutter

## Bottom line

The UI polish work succeeded, and the second pass made it meaningfully better again.

Compared with the original `run-0007` review, the app is now:
- more cohesive
- more user-facing
- more intentional on sparse surfaces
- more consistent in visual language
- fully green in analyzer, tests, and screenshot verification

Compared with the earlier checkpoint in `run-0013`, the latest `run-0016` pass also makes the app:
- cleaner in shell metadata
- better structured in profile/detail flows
- less repetitive in action affordances
- stronger on stats and achievements communication

The remaining issues are mostly second-order polish decisions, not structural regressions. The one screen that still most wants another design pass is `Conversation thread`, and the one cross-cutting theme still worth pursuing is **one more round of shell compaction**.

## Additional issues and observations missed in the first write-up

After a closer pass through the `run-0016` screenshots and the corresponding widget code, there are a few more concrete issues worth calling out.

These are mostly not new categories of problems. They are sharper versions of the remaining polish work, and they make the next implementation pass easier to target.

### Cross-cutting misses

- **Single-item screens still feel too isolated.** `Matches`, `Chats`, and some utility surfaces still spend a lot of visual energy on a header, then present one lone card in a large field of empty space.
- **Some screens are now cleaner, but also a little over-framed.** The app occasionally stacks an app bar, a hero/intro surface, and then another large decorated card before useful interaction starts.
- **Nested card patterns are still heavier than they need to be.** `Settings`, `Notifications`, `Verification`, and `Location completion` are the clearest examples.
- **Metadata is sometimes repeated in multiple visual forms.** A headline, subtitle, chip, and helper line will occasionally all communicate the same thing in slightly different ways.
- **The app still mixes “product card” and “utility card” density.** Some support screens use the same generous spacing as feature hero surfaces, which makes them feel plush instead of efficient.

### More specific screen issues that were under-called before

#### 1. `Matches` is cleaner, but the hero is no longer earning its space

The match cards are already expressive enough to carry the screen. The current hero adds product tone, but it is now the third-strongest thing on the page instead of the first. On a short list, it makes the screen feel more ceremonial than useful.

**Refinement target:** either remove the hero entirely or collapse it into much lighter top-of-list summary metadata.

#### 2. `Chats` still reads like an inbox wrapped inside a landing page

The conversation card itself is solid, but the screen still opens with too much “screen intro” before the inbox behavior begins. This is especially noticeable when there is only one thread.

**Refinement target:** demote the hero, strengthen the conversation card as the primary visual anchor, and make the single-thread state feel intentionally inhabited rather than sparsely listed.

#### 3. `Discover` still duplicates relationship/status signals inside the candidate area

Inside the candidate card, the name line, subtitle, and chips still repeat profile facts more than necessary. The result is readable, but not yet elegant.

**Refinement target:** remove one layer of repeated metadata so the profile preview feels more authored and less templated.

#### 4. `Settings` is still visually nested one layer too deep

The top session card is better, but the `Quick access` section followed by multiple individually decorated destination cards still creates a card-inside-card feel.

**Refinement target:** flatten quick links into a lighter grouped list so the page feels like one settings surface instead of one overview card plus a stack of mini feature cards.

#### 5. `Notifications` still spends too much vertical space on control framing

The screen is improved, but it still uses a hero, a controls card, and then the feed. For a utility surface that should feel quick and high-frequency, that is still one framing layer too many.

**Refinement target:** collapse the top area into a compact summary + filter/action row and let the feed start sooner.

#### 6. `Verification` still feels like multiple separate modules instead of one guided task

The flow is much clearer than before, but the current page still reads as hero → card → card → result card. That makes the task feel longer than it is.

**Refinement target:** reduce the amount of preamble and tighten the start/confirm sequence so the screen feels like one guided verification journey.

#### 7. `Standouts` still has too many metadata chips per card

The copy is warmer now, but the card still spends a lot of surface on rank/score/date metadata. The feature should feel curated first and scored second.

**Refinement target:** compress metadata into fewer, stronger tokens and let the reason/profile identity lead.

#### 8. `People who liked you` still repeats the same support sentence too often

The screen improved structurally, but card-to-card copy still feels slightly templated. It reads like one good card duplicated, not like a list of distinct people.

**Refinement target:** move generic explanatory copy to the screen-level intro and let each card carry only the most specific context.

#### 9. `Blocked users` still uses too much explanation per row

The safety framing is stronger now, but every blocked-user row still explains the blocking effect again. On longer lists, that will become visually repetitive fast.

**Refinement target:** keep the consequence explanation in the screen intro and simplify each row to person + state + unblock affordance.

#### 10. `Stats` and `Achievements` are stronger, but still slightly over-introduced

Both screens now communicate more clearly, but they still combine a hero and an explanatory intro before the actual stat or achievement content takes over.

**Refinement target:** keep one strong top summary and remove redundant explanatory framing below it.

#### 11. `Profile edit` still pays a high vertical cost for helper copy

The sectioning is much better now, but every section still consumes extra height through description copy and full-width form rhythm.

**Refinement target:** tighten section spacing and combine related numeric inputs so the form feels faster to scan and complete.

#### 12. `Location completion` is clear, but still a little over-described

The flow is good, yet the screen still uses generous explanatory copy around a very simple task.

**Refinement target:** shorten the explanatory stack and make the save path feel closer to the first input interaction.

## Strongest next-pass opportunities

If there is another polish pass, the best return now comes from these changes:

1. **Remove or substantially collapse unnecessary shell heroes** on `Matches`, `Chats`, `Notifications`, and possibly `Blocked users`.
2. **Flatten nested utility layouts** so `Settings`, `Verification`, and `Notifications` feel quicker and lighter.
3. **Reduce repeated metadata** inside `Discover`, `Standouts`, and notification rows.
4. **Tighten short-list states** so single-card screens feel intentional rather than under-filled.
5. **Shorten explanatory copy where the UI is already understandable** — especially in edit and setup flows.

## What the next implementation pass should optimize for

The next pass should not chase a brand new visual style.

It should optimize for:

- faster content access
- fewer stacked decorative surfaces
- less repeated metadata per card
- tighter utility-screen rhythm
- stronger single-item-state composition

That would move the app from “polished and coherent” to “confidently productized.”
