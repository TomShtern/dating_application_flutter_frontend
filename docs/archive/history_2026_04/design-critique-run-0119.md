# UI / Design Critique - visual review run-0119

Status: reviewed and reconciled critique for `visual_review/latest/`
run-0119, captured on 2026-04-29.

Evidence set: `visual_review/latest/manifest.json` reports 19 expected and
19 captured screenshots. This document turns the original two-pass critique
into an action-first implementation guide. It keeps the useful critique and
removes duplicate punch lists, stale wording, and claims we decided not to
carry forward.

## How to use this document

The findings are grouped into four buckets:

1. **Concrete visual fixes** - UI changes that can be acted on from the current
   screenshots and code.
2. **Backend / data dependencies** - valid UX issues that need backend fields,
   real data, or contract verification before Flutter can solve them honestly.
3. **Future product features** - wanted product work that is real, but should
   not block the current visual lock-in pass.
4. **Hardening / QA** - accessibility, localization, responsive, and device
   audits.

Within concrete visual fixes, items are grouped by screen so an implementer can
work screen-by-screen. Each item uses the same format:

- **Finding** - what is wrong or unclear.
- **Decision** - what we decided after review.
- **Action** - what the next implementation pass should do.
- **Evidence** - screenshot or section reference.

---

## 1. Concrete visual fixes

### 1.1 `app_home_startup__run-0119.png` - dev sign-in

- **Finding:** The dev callout, backend status, and no-profile state are split
  into multiple prominent cards.
- **Decision:** Valid. This whole screen should be clearer and more compact.
  Backend/system state should feel developer-only, not like primary user-facing
  product content.
- **Action:** Rework the development sign-in and backend-online content into
  one clearer developer-only card. Keep the available profiles list below it.
- **Evidence:** `app_home_startup__run-0119.png`; original sections 3.1 and
  11.8.

- **Finding:** Profile rows mix accent bars and avatar colors in a way that
  feels visually busy.
- **Decision:** Valid, but lower priority than the dev-card restructure.
- **Action:** After the dev-card rework, align avatar/accent color treatment so
  the profile picker feels intentional.
- **Evidence:** `app_home_startup__run-0119.png`.

### 1.2 `shell_discover__run-0119.png` - Discover

- **Finding:** The large no-photo placeholder is the weakest visual element on
  the screen. It is especially bad on the large candidate photo plate.
- **Decision:** Valid. Some smaller fallback avatars are less severe, but the
  large Discover placeholder must be fixed, changed, or removed.
- **Action:** Replace the saturated muddy fallback with a calmer no-photo state:
  a softer tinted surface, a clear high-contrast monogram or icon, and a tidy
  "photo pending" treatment that belongs to the card instead of floating over
  it.
- **Evidence:** `shell_discover__run-0119.png`; original sections 2.1, 3.2,
  5, and 18.6.

- **Finding:** The undo and refresh icons sit together and look too similar.
- **Decision:** Valid. The UI looks pretty, but the meaning is not clear.
- **Action:** Make the two actions visually and semantically distinct, or keep
  only the action that is actually needed in the hero.
- **Evidence:** `shell_discover__run-0119.png`; original sections 3.2 and 19.1.

- **Finding:** "Why this profile is shown" uses a nested subcard inside the
  candidate card.
- **Decision:** Valid. It creates card-in-card chrome and makes the already
  large candidate card heavier.
- **Action:** Keep the content, but remove the extra inner-card treatment. Use a
  cleaner inline section divider or a lighter reason area.
- **Evidence:** `shell_discover__run-0119.png`; original section 14.1.

- **Finding:** Reason tags such as "Nearby", "Shared Interests", and "Eligible
  Match Pool" are visually flat and do not help scanning.
- **Decision:** Valid, but secondary to the photo and action issues.
- **Action:** Give reason tags clearer meaning through simple, consistent
  color/icon treatment. Do not invent new compatibility logic in Flutter.
- **Evidence:** `shell_discover__run-0119.png`.

- **Finding:** `Pass` and `Like` have different heights and the `Pass` button
  reads too unfinished.
- **Decision:** Valid.
- **Action:** Match their vertical size. Keep hierarchy through color, weight,
  and width, not accidental height mismatch. Give `Pass` a softer secondary
  treatment so it does not read disabled.
- **Evidence:** `shell_discover__run-0119.png`; original sections 2.4, 4.7,
  and 14.2.

- **Finding:** The user sees one candidate card but does not get a strong cue
  that there are more candidates behind it.
- **Decision:** Valid.
- **Action:** Add a simple stack/progress cue such as "1 of 5" or a subtle
  stack hint.
- **Evidence:** `shell_discover__run-0119.png`; original section 12.4.

### 1.3 `shell_matches__run-0119.png` and `shell_matches_dark__run-0119.png`

- **Finding:** `Message` and `View profile` compete for attention.
- **Decision:** Valid. Both actions are useful, but they should not look
  equally primary.
- **Action:** Keep both paths. Make `Message` the primary action and demote
  `View profile` visually.
- **Evidence:** `shell_matches__run-0119.png`, `shell_matches_dark__run-0119.png`;
  original sections 2.4, 3.3, 3.18, and 4.4.

- **Finding:** The hero can show `5 matches ready` and `No new matches yet` at
  the same time.
- **Decision:** Valid. It may be technically "total vs new", but it reads as a
  contradiction.
- **Action:** Rewrite the copy into one clear signal, for example
  `5 matches ready · 0 new this week`.
- **Evidence:** `shell_matches__run-0119.png`; original sections 3.3 and 18.3.

- **Finding:** The All/New filter has a weak unselected state.
- **Decision:** Valid.
- **Action:** Strengthen the unselected chip so the row reads as two real
  options, not one option plus a label.
- **Evidence:** `shell_matches__run-0119.png`; original sections 3.3 and 4.3.

- **Finding:** The third match card continues below the fold.
- **Decision:** This is not a hard clipping bug. It is reasonable scroll
  behavior. There may still be vertical whitespace that can be trimmed if the
  goal is to show more of the third card.
- **Action:** Treat as a density/spacing improvement, not as broken bottom-nav
  padding.
- **Evidence:** `shell_matches__run-0119.png`; original section 14.7.

### 1.4 `shell_chats__run-0119.png` - Chats

- **Finding:** Every row body repeats the count already shown in the pill:
  `N messages exchanged in this conversation`.
- **Decision:** Valid. The row needs real preview content, but Flutter cannot
  honestly invent that from the current DTO.
- **Action:** Add backend/API support for a last-message preview or equivalent
  conversation summary field, then render that in the row body. Until then,
  keep any fallback clearly temporary.
- **Evidence:** `shell_chats__run-0119.png`; original sections 2.9, 3.4, and
  18.2.

- **Finding:** Avatar overlay icons and chevrons are visually tidy but their
  meaning is not obvious.
- **Decision:** Valid, but lower priority than the missing preview content.
- **Action:** Clarify whether the avatar overlay means chat state, media, or
  profile photo. Keep the chevron only if it helps explain that the row opens a
  thread.
- **Evidence:** `shell_chats__run-0119.png`; original sections 3.4 and 19.3.

- **Finding:** Chat row colors do not always feel tied to the chat surface.
- **Decision:** Valid as guidance, not a rigid rule.
- **Action:** When adjusting avatars and rings, prefer a calmer chat-consistent
  treatment without making every avatar identical.
- **Evidence:** `shell_chats__run-0119.png`; original sections 3.4 and 4.1.

### 1.5 `shell_profile__run-0119.png` - Profile

- **Finding:** The profile readiness signal appears twice: once in the hero and
  again in the identity card with a progress bar.
- **Decision:** Valid and concrete. Only one readiness display should remain.
- **Action:** Keep the prettier and more useful readiness treatment, remove or
  replace the other one, and adjust spacing after removal.
- **Evidence:** `shell_profile__run-0119.png`; original sections 2.10 and 3.5.

- **Finding:** The Profile hero is rose-heavy, which contributes to the samey
  pink feel across primary tabs.
- **Decision:** Valid.
- **Action:** Move the Profile hero surface toward lavender or sky blue while
  preserving enough warmth for the app.
- **Evidence:** `shell_profile__run-0119.png`; original sections 2.3, 3.5, and
  6.

- **Finding:** The mini-cards inside Profile details use different tints, but
  the differences are subtle.
- **Decision:** Valid, but not as urgent as duplicate readiness.
- **Action:** Increase tint clarity or simplify the treatment so the grid looks
  intentional.
- **Evidence:** `shell_profile__run-0119.png`; original section 3.5.

- **Finding:** The screenshot cuts off while scrolling through profile details.
- **Decision:** Normal scrolling is not a bug. It only matters if important
  actions are hidden.
- **Action:** Do not treat this as a blocker. During any Profile pass, confirm
  important actions are discoverable.
- **Evidence:** `shell_profile__run-0119.png`; original section 12.2.

### 1.6 `shell_settings__run-0119.png` - Settings

- **Finding:** Quick access subtitles truncate mid-word.
- **Decision:** Valid and visible.
- **Action:** Allow two-line subtitles or shorten the copy. Do not leave
  mid-word ellipses on navigation rows.
- **Evidence:** `shell_settings__run-0119.png`; original sections 3.6 and 11.1.

- **Finding:** The Quick access group header is styled like another row inside
  the card, while other screens use clearer group labels.
- **Decision:** Valid, but explain simply: group names should look consistent
  across pages. Titles inside a card can stay simpler.
- **Action:** Make the Quick access heading read as a group label, not a
  competing row.
- **Evidence:** `shell_settings__run-0119.png`, `stats__run-0119.png`;
  original sections 2.5, 3.6, and 4.6.

- **Finding:** The theme segmented control wraps awkwardly.
- **Decision:** Valid.
- **Action:** Resize, relabel, or restructure the theme options so labels fit
  cleanly at the visual-review width.
- **Evidence:** `shell_settings__run-0119.png`; original section 3.6.

- **Finding:** Settings is becoming the hub for Stats, Notifications,
  Verification, Blocked users, and Achievements.
- **Decision:** Valid information-architecture concern.
- **Action:** Keep Settings usable now, but plan additional entry points for
  profile-related and notification-related surfaces.
- **Evidence:** `shell_settings__run-0119.png`; original sections 7 and 23.1.

### 1.7 `conversation_thread__run-0119.png`

- **Finding:** The capture does not show a visible in-app back chevron.
- **Decision:** Valid route-context issue. Android system back exists, but the
  UI should still show a visible in-app route affordance for clarity,
  screenshots, accessibility, and cross-platform parity.
- **Action:** Add a compact visible chevron or equivalent top navigation
  control when the thread is opened as a pushed route.
- **Evidence:** `conversation_thread__run-0119.png`; original sections 2.2,
  3.7, and 7.

- **Finding:** The original critique called the header too thin.
- **Decision:** Rejected. The slim header is desirable. It can be slightly
  expanded only if needed for route context, but do not make it bulky.
- **Action:** Keep the header slim.
- **Evidence:** `conversation_thread__run-0119.png`.

- **Finding:** The original critique objected to every bubble having its own
  timestamp.
- **Decision:** Rejected. Per-message timestamps are acceptable here because
  messages were sent at different times.
- **Action:** Do not remove per-message timestamps as part of this critique.
- **Evidence:** `conversation_thread__run-0119.png`; original section 11.6.

### 1.8 `standouts__run-0119.png`

- **Finding:** Photo fallback treatment needs the same cleanup as Discover and
  Profile surfaces.
- **Decision:** Valid.
- **Action:** Apply the shared photo-placeholder system once it exists.
- **Evidence:** `standouts__run-0119.png`; original sections 2.1 and 3.8.

- **Finding:** The rank/score badge reads as `#N · NN pts`.
- **Decision:** Keep the concern, but correct the framing. Flutter currently
  reads `rank` and `score` from the `Standout` DTO; it is not calculating
  recommendation scores locally. Still verify the live backend contract because
  recommendation metrics must remain server-owned.
- **Action:** Verify Java/backend ownership of `rank` and `score`. Separately,
  decide whether `pts` is clear enough user-facing wording.
- **Evidence:** `standouts__run-0119.png`; `lib/models/standout.dart`;
  original sections 2.8, 3.8, 18.8, and 24.8.

- **Finding:** The screen capture needs visible route chrome.
- **Decision:** Valid.
- **Action:** Add a visible in-app back chevron or equivalent when opened as a
  pushed route.
- **Evidence:** `standouts__run-0119.png`; original section 2.2.

- **Finding:** Card tint choices may feel arbitrary.
- **Decision:** Valid enough to keep.
- **Action:** During the Standouts pass, make tint/color rules explainable:
  top-ranked, normal, selected, and fallback states should have clear meaning.
- **Evidence:** `standouts__run-0119.png`; original section 3.8.

### 1.9 `pending_likers__run-0119.png`

- **Finding:** Chevron-only rows do not clearly explain the intended
  profile-first decision flow.
- **Decision:** Valid. The desired behavior is: open the profile/prompt from
  the row, then show like/ignore actions there.
- **Action:** Make the row and hero copy explain that flow. Keep the aesthetic
  chevron if it remains useful, but do not rely on it as the only explanation.
- **Evidence:** `pending_likers__run-0119.png`; original sections 2.5, 3.9,
  18.5, and 19.5.

- **Finding:** The `Profile first` pill is unclear.
- **Decision:** Valid.
- **Action:** Rename or replace it with clearer copy that tells the user what
  happens next.
- **Evidence:** `pending_likers__run-0119.png`; original sections 18.5 and
  24.9.

- **Finding:** The screen capture needs visible route chrome.
- **Decision:** Valid.
- **Action:** Add a visible in-app back chevron or equivalent when opened as a
  pushed route.
- **Evidence:** `pending_likers__run-0119.png`; original section 2.2.

### 1.10 `profile_other_user__run-0119.png`

- **Finding:** The primary action for another user's profile is not visible in
  the first viewport.
- **Decision:** Valid. A dating profile needs a clear decision path.
- **Action:** Bring the primary action into the first viewport or provide a
  floating/sticky action area.
- **Evidence:** `profile_other_user__run-0119.png`; original sections 3.10 and
  12.1.

- **Finding:** Some reason chips are truncated or wrap awkwardly.
- **Decision:** Valid.
- **Action:** Let reason chips wrap cleanly or cap visible chips with a clear
  `+N more` affordance.
- **Evidence:** `profile_other_user__run-0119.png`; original section 11.3.

- **Finding:** Duplicate photo-pending placeholders appear in the Photos area.
- **Decision:** Not a blocker by itself. It will likely be solved by the shared
  photo-placeholder work.
- **Action:** Do not prioritize this separately unless the shared placeholder
  pass leaves it unresolved.
- **Evidence:** `profile_other_user__run-0119.png`; original section 24.10.

### 1.11 `profile_edit__run-0119.png`

- **Finding:** Profile edit is not complete enough for a real edit screen.
- **Decision:** Valid and concrete. Profile edit is expected to let users edit
  their profile.
- **Action:** Add or plan editable support for bio, photos, interests,
  lifestyle/preferences, and other real profile fields that the backend allows.
- **Evidence:** `profile_edit__run-0119.png`; original sections 3.11, 17.3,
  and 24.11.

- **Finding:** Gender and Interested-in pill rows wrap into an orphaned single
  `Other` chip.
- **Decision:** Valid.
- **Action:** Use a cleaner layout such as a 2x2 grid, smaller chips, or a
  separate "Other options" control.
- **Evidence:** `profile_edit__run-0119.png`; original section 11.4.

- **Finding:** Identity card chips also wrap with a single orphaned chip.
- **Decision:** Valid.
- **Action:** Rebalance or simplify the identity chip row.
- **Evidence:** `profile_edit__run-0119.png`; original section 11.5.

- **Finding:** The edit flow needs visible route chrome and safer exit actions.
- **Decision:** Valid.
- **Action:** Add visible route navigation. Add clear cancel/discard/reset
  affordances where appropriate, with confirmation if unsaved changes can be
  lost.
- **Evidence:** `profile_edit__run-0119.png`; original sections 2.2, 3.11, and
  16.

- **Finding:** The original critique called out the Save gradient as too loud.
- **Decision:** Keep as visual polish, not a blocker. Approved attractive
  gradients can remain when they fit the screen.
- **Action:** Revisit only if the screen still feels too heavy after layout and
  field-completeness work.
- **Evidence:** `profile_edit__run-0119.png`; original section 4.4.

### 1.12 `location_completion__run-0119.png`

- **Finding:** Country, city, ZIP, and the CTA use inconsistent field and color
  treatments.
- **Decision:** Valid.
- **Action:** Standardize form fields and make the primary CTA align with the
  screen's visual language.
- **Evidence:** `location_completion__run-0119.png`; original sections 2.6,
  3.12, and 24.12.

- **Finding:** The screen capture needs visible route chrome.
- **Decision:** Valid.
- **Action:** Add a visible in-app back chevron or equivalent when opened as a
  pushed route.
- **Evidence:** `location_completion__run-0119.png`; original section 2.2.

- **Finding:** Current-location and inline autocomplete are useful.
- **Decision:** Wanted, but future feature work rather than a visual lock-in
  blocker.
- **Action:** Move to future product features.
- **Evidence:** `location_completion__run-0119.png`; original section 24.12.

### 1.13 `stats__run-0119.png`

- **Finding:** Sparkbars look like data but currently read as template
  decoration.
- **Decision:** Valid. The bars are liked visually, but they must represent
  real data eventually.
- **Action:** Keep the sparkbar idea, but wire it to real trend data or replace
  it with a non-data decorative treatment.
- **Evidence:** `stats__run-0119.png`; original sections 3.13, 14.8, 18.8, and
  19.4.

- **Finding:** Metrics such as response time and reply rate need context.
- **Decision:** Valid.
- **Action:** Add date ranges, windows, benchmarks, or labels that explain what
  each number means.
- **Evidence:** `stats__run-0119.png`; original sections 3.13 and 18.8.

### 1.14 `achievements__run-0119.png`

- **Finding:** In-progress achievements are visible, but there is no separate
  locked/to-unlock roadmap.
- **Decision:** Valid product direction. The original wording was misleading
  because `Still building` already exists.
- **Action:** Add a locked or to-unlock section if the achievement system is
  meant to motivate future goals.
- **Evidence:** `achievements__run-0119.png`; original sections 3.14, 12.3,
  and 24.14.

- **Finding:** Completed achievements still show completed progress chips such
  as `3 / 3`.
- **Decision:** Valid issue. The exact solution can be chosen during
  implementation.
- **Action:** Reduce redundant completed-progress chips on already-unlocked
  cards, or replace them with a cleaner completed-state cue.
- **Evidence:** `achievements__run-0119.png`; original section 24.14.

### 1.15 `verification__run-0119.png`

- **Finding:** The flow needs more verification pieces: step 2 visibility,
  resend timer, and a photo-verification path if the product supports it.
- **Decision:** Valid.
- **Action:** Complete or plan the verification flow so it supports the full
  expected user journey.
- **Evidence:** `verification__run-0119.png`; original sections 3.15, 17.10,
  and 24.15.

- **Finding:** The screen capture needs visible route chrome.
- **Decision:** Valid.
- **Action:** Add a visible in-app back chevron or equivalent when opened as a
  pushed route.
- **Evidence:** `verification__run-0119.png`; original section 2.2.

- **Finding:** The original critique said the green CTA should be softened.
- **Decision:** Rejected. The green Verification CTA is an approved special
  case and should stay.
- **Action:** Do not change the green CTA solely because of this critique.
- **Evidence:** `verification__run-0119.png`; original section 24.15.

### 1.16 `blocked_users__run-0119.png`

- **Finding:** Rows repeat similar explanatory copy, and `Can unblock` repeats
  the button meaning.
- **Decision:** Valid.
- **Action:** Move shared explanation to the intro area and remove redundant
  per-row pills where the button already explains the action.
- **Evidence:** `blocked_users__run-0119.png`; original sections 3.16, 11.2,
  and 24.16.

- **Finding:** `Unblock` should read as a real action, not a weak secondary
  label.
- **Decision:** Valid.
- **Action:** Promote `Unblock` to a clearer button while preserving
  confirmation.
- **Evidence:** `blocked_users__run-0119.png`; original section 3.16.

- **Finding:** The screen capture needs visible route chrome.
- **Decision:** Valid.
- **Action:** Add a visible in-app back chevron or equivalent when opened as a
  pushed route.
- **Evidence:** `blocked_users__run-0119.png`; original section 2.2.

### 1.17 `notifications__run-0119.png` and `notifications_dark__run-0119.png`

- **Finding:** Mark-as-read affordances are unclear when check icons and row
  navigation affordances coexist.
- **Decision:** Valid.
- **Action:** Make the meaning of check, chevron, and row tap explicit through
  consistent placement and behavior. Use one trailing action pattern unless
  two distinct actions are clearly communicated.
- **Evidence:** `notifications__run-0119.png`, `notifications_dark__run-0119.png`;
  original sections 3.17 and 19.2.

- **Finding:** Notification settings are needed.
- **Decision:** Wanted, but future feature work rather than a current visual
  lock-in blocker.
- **Action:** Move to future product features.
- **Evidence:** `notifications__run-0119.png`; original sections 3.17 and 17.6.

---

## 2. Cross-screen system fixes

### 2.1 Visible route chevrons and route context

- **Finding:** Secondary visual-review captures often look detached because the
  in-app back affordance is not visible.
- **Decision:** Valid. Android system back exists, but visible in-app chevrons
  are still needed for clarity, accessibility, screenshots, and cross-platform
  behavior.
- **Action:** Add a compact app bar, chevron, close control, or equivalent top
  route control for pushed routes. Placement can vary by screen, but the
  affordance must be visible and understandable.
- **Evidence:** Conversation thread, profile edit, location, verification,
  blocked users, pending likers, achievements, stats, notifications, and
  standouts captures.

### 2.2 Shared photo-placeholder system

- **Finding:** No-photo states are inconsistent and often too loud. The largest
  photo plates look worst.
- **Decision:** Valid. Fix large placeholders first, then align smaller
  fallbacks.
- **Action:** Define one calm placeholder recipe: tinted surface, high-contrast
  monogram or icon, and clear copy only when needed.
- **Evidence:** Discover, Standouts, Profile other user, Profile edit, and
  dev-picker/profile avatars.

### 2.3 Group headings

- **Finding:** Some pages use clear group labels with a small accent bar and
  thin rule, while others bury group titles inside cards.
- **Decision:** Valid, but keep it simple. Group names should feel consistent
  across pages. Titles inside a card can stay simpler.
- **Action:** Use the shared group-label pattern for groups between cards. Keep
  plain titles for sections inside a card.
- **Evidence:** Stats, Achievements, Notifications, Settings, Profile.

### 2.4 CTA and toggle consistency

- **Finding:** Buttons and toggles sometimes communicate hierarchy by accident
  instead of by design.
- **Decision:** Valid with exceptions. The green Verification CTA is approved
  as a special case.
- **Action:** Use consistent visual ranks: primary action, secondary action,
  tertiary/link action, and destructive action. Comparable toggles should share
  a common pattern; action pairs such as Notifications can differ when the
  actions are not filters.
- **Evidence:** Matches, Discover, Profile edit, Verification, Standouts,
  Settings.

### 2.5 Copy and date formatting

- **Finding:** Repeated body text, current-year dates, ambiguous pills, and
  unclear metric labels make the UI harder to scan.
- **Decision:** Valid. Deduplicate copy cleanup into one system pass instead
  of scattering it across screens.
- **Action:** Standardize current-year date formatting, reduce repeated counter
  text, clarify ambiguous labels such as `Profile first` and `Daily pick live`,
  and keep backend/dev infrastructure language out of user-facing surfaces.
- **Evidence:** Chats, Conversation thread, Pending likers, Discover,
  Settings/dev sign-in.

### 2.6 New-match dot behavior

- **Finding:** The Matches bottom-nav dot is intended to mean "new matches".
- **Decision:** Valid and desired. The document should not treat it as a vague
  unread marker.
- **Action:** Verify the dot actually means new matches, updates predictably,
  and clears when the user visits the relevant tab or when backend state says it
  should clear.
- **Evidence:** Shell bottom navigation captures; original section 23.6.

---

## 3. Backend / data dependencies

### 3.1 Chats last-message preview

- **Issue:** Chat rows need real preview text. Current Flutter DTOs expose
  `messageCount` and `lastMessageAt`, not a last-message preview.
- **Required dependency:** Add an API field such as last message preview,
  latest sender/copy, or equivalent server-owned summary.
- **Do not:** Invent message previews in Flutter from unrelated fields.
- **Evidence:** `shell_chats__run-0119.png`; `lib/models/conversation_summary.dart`.

### 3.2 Standouts rank and score ownership

- **Issue:** Standouts display `rank` and `score` as `#N · NN pts`.
- **Current Flutter evidence:** The values are parsed from the `Standout` DTO.
- **Required dependency:** Confirm the Java/backend live contract produces
  these recommendation metrics and owns their meaning.
- **Open UX question:** Decide whether `pts` is the right user-facing label.
- **Evidence:** `standouts__run-0119.png`; `lib/models/standout.dart`.

### 3.3 Real stats trend data

- **Issue:** Sparkbars are liked visually, but they must represent real data.
- **Required dependency:** Provide trend points, windows, or enough stats
  history for the chartlets.
- **Do not:** Keep decorative bars that look like real analytics.
- **Evidence:** `stats__run-0119.png`.

### 3.4 Metric context

- **Issue:** Some numbers need context: response time, reply rate, achievement
  percentages, and standout scores.
- **Required dependency:** Backend or product contract should define windows,
  baselines, and labels.
- **Note:** `50 km` already has a unit; treat distance preferences as future
  product work, not the same issue.
- **Evidence:** Stats, Standouts, Achievements.

### 3.5 Alternate states

- **Issue:** run-0119 captures populated paths. Many loading, empty, and error
  states exist in code, but they are not fully visually reviewed. Offline,
  skeleton, and optimistic states may still be incomplete.
- **Required dependency:** Some alternate states need backend/API behavior or
  fixture coverage to verify properly.
- **Action:** Audit and capture representative empty/error/loading/offline
  states in a later visual run.
- **Evidence:** `visual_review/latest/manifest.json`; original sections 8 and
  13.

---

## 4. Future product features

These are wanted or likely needed, but they should not block the immediate
visual cleanup unless a specific feature is reopened.

- **Notification settings route:** Needed, but future feature work.
- **Chat search:** Should be near the top of future feature work for Chats.
- **Deep links:** Important. Define notification-to-destination behavior and
  fallback routes.
- **Profile back-stack origin:** Opening an other-user profile from Discover,
  Pending likers, Standouts, or Matches should preserve the user's origin.
- **Auth:** Add at least a simple auth/onboarding placeholder later; real auth
  remains future product work.
- **Discovery filters:** Age range, distance, verified-only, and preference
  controls belong to future product work.
- **Broader chat features:** Read receipts, delivery state, typing indicators,
  attachments, emoji/voice, long-press actions, and report-from-chat.
- **Profile edit completeness:** Concrete for the edit screen, but broader
  field/contract work may need its own implementation plan.
- **Locked achievements:** Add a locked/to-unlock roadmap if the achievement
  system is meant to motivate future behavior.
- **Location improvements:** Current-location and inline city autocomplete are
  useful future feature work.
- **Premium/paid tier:** Future product roadmap only.
- **Safety center/account/help/logout:** Future product surfaces, separate from
  the current visual pass.
- **Brand presence:** Future product polish. Do not treat it as a visual
  blocker for this pass.
- **Special-state icons:** Future polish for empty, success, and verification
  moments.

---

## 5. Hardening / QA

These items should be tracked, but they are not current visual lock-in blockers.

- **Accessibility and contrast:** Run a real contrast and semantics audit. Do
  not present unmeasured contrast notes as proven failures, except for obvious
  low-contrast placeholder cases.
- **Screen-reader labels:** Audit icon-only buttons, tappable cards, live
  regions, and decorative icon chips.
- **Touch targets:** Verify small chevrons, refresh icons, mark-read checks,
  and menu buttons meet comfortable mobile tap sizes.
- **RTL and localization:** Future hardening. Hebrew/RTL support matters for
  the likely region, but no RTL screenshot was captured in run-0119.
- **Date/time/plural formatting:** Use localization-aware formatting when
  localization work begins.
- **Responsive/device QA:** Prioritize small-phone and keyboard behavior before
  tablet/foldable layouts.
- **Safe areas and keyboard avoidance:** Verify input screens and bottom nav on
  real devices or representative emulators.
- **Reduce motion:** Future accessibility preference for non-essential motion.

---

## Appendix: screen notes

This appendix preserves the screen-by-screen decision record without repeating
the full critique.

### `app_home_startup__run-0119.png`

- Rework dev sign-in and backend status into one developer-only card.
- Keep available profile cards, but align accent/avatar treatment later.

### `shell_discover__run-0119.png`

- Fix the large no-photo plate and photo-pending treatment.
- Clarify undo/refresh icon meaning.
- Remove nested-card chrome from "Why this profile is shown".
- Add a candidate stack/progress cue.
- Keep reason tags, but make them easier to scan.

### `shell_matches__run-0119.png`

- Demote `View profile` relative to `Message`.
- Rewrite `5 matches ready` plus `No new matches yet`.
- Strengthen the unselected filter chip.
- Treat the third-card cutoff as density/scroll behavior, not broken padding.

### `shell_matches_dark__run-0119.png`

- Keep dark mode mostly as-is.
- Treat bright secondary CTA styling as low-priority Matches polish.

### `shell_chats__run-0119.png`

- Replace repeated message-count body text when backend preview data exists.
- Clarify avatar overlay meaning and row navigation affordance.

### `shell_profile__run-0119.png`

- Keep only one readiness display.
- Move hero away from rose.
- Improve profile-detail tint clarity.
- Do not treat ordinary scroll cutoff as a bug.

### `shell_settings__run-0119.png`

- Fix Quick access subtitle truncation.
- Make group headings easier to understand.
- Fix theme control wrapping.
- Keep Settings hub concern as information-architecture work.

### `conversation_thread__run-0119.png`

- Add visible route/back affordance.
- Keep slim header.
- Keep per-message timestamps.
- Move attach/emoji/voice to future chat features.

### `standouts__run-0119.png`

- Apply shared photo-placeholder cleanup.
- Verify backend ownership of rank/score.
- Revisit `pts` wording.
- Keep card color/tint meaning explainable.

### `pending_likers__run-0119.png`

- Keep profile-first flow.
- Make the row and copy explain where like/ignore happens.
- Rename or replace `Profile first`.

### `profile_other_user__run-0119.png`

- Bring primary action into the first viewport or make it sticky/floating.
- Fix truncated reason chips.
- Treat duplicate placeholders as part of shared photo-placeholder work.

### `profile_edit__run-0119.png`

- Make profile editing complete.
- Fix orphaned pill rows.
- Add safe cancel/discard/reset behavior where needed.
- Keep Save gradient as polish unless later layout still feels heavy.

### `location_completion__run-0119.png`

- Standardize field treatment.
- Keep current-location/autocomplete as future feature work.

### `stats__run-0119.png`

- Keep sparkbars visually, but make them real data.
- Add metric windows, ranges, and context.

### `achievements__run-0119.png`

- Keep `Still building`.
- Add a locked/to-unlock roadmap later.
- Reduce redundant completed progress chips.

### `verification__run-0119.png`

- Complete the verification flow pieces.
- Keep green CTA.
- Add visible route/back affordance.

### `blocked_users__run-0119.png`

- Reduce repeated row copy.
- Remove redundant `Can unblock` cue.
- Make `Unblock` read as a real action with confirmation.

### `notifications__run-0119.png` and `notifications_dark__run-0119.png`

- Clarify mark-read and row-navigation affordances.
- Keep notification settings as a future route.

---

## Verification notes

After this restructure, the old duplicated quick-fix and backlog sections have
been merged into the action buckets above. Future edits should update the
bucketed sections directly instead of adding a second backlog at the bottom.
