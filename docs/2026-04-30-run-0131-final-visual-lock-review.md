# Final Visual Lock Review — run-0131 (2026-04-30)

Inspector: read-only visual reviewer. No Dart, test, or doc edits.
Rubric: `AGENTS.md`, `docs/design-language.md` (target reference set: Stats and
Notifications run-0070).

## 1. Executive Verdict

**Design can lock with small accepted caveats.**

Reason: the canonical reference screens (`stats`, `achievements`, `notifications`,
`notifications_dark`) match the run-0070 design-language target very well. Most
secondary screens (Settings, Profile, Chats, Standouts, Pending Likers, Blocked
users, Verification, Location, Profile edit) follow the section-label / soft-tint
/ semantic-icon-chip recipe consistently and are clearly polished. Light/dark
parity reads well on the screens captured in both modes.

The remaining issues are either (a) a small number of bounded copy/contrast
issues that should be fixed in a tight follow-up, (b) a fixture-test artifact
that will not exist in production, or (c) borderline taste calls that do not
justify continued visual iteration. None of them are systemic failures of the
design language.

The team should stop generic visual polish and move to functional/backend work.
The follow-up handoff scope below is small enough to land in one focused pass.

## 2. Screens Inspected

All 19 run-0131 screenshots were inspected against the run-0070 reference set.

- `achievements__run-0131.png`
- `app_home_startup__run-0131.png`
- `blocked_users__run-0131.png`
- `conversation_thread__run-0131.png`
- `location_completion__run-0131.png`
- `notifications__run-0131.png`
- `notifications_dark__run-0131.png`
- `pending_likers__run-0131.png`
- `profile_edit__run-0131.png`
- `profile_other_user__run-0131.png`
- `shell_chats__run-0131.png`
- `shell_discover__run-0131.png`
- `shell_matches__run-0131.png`
- `shell_matches_dark__run-0131.png`
- `shell_profile__run-0131.png`
- `shell_settings__run-0131.png`
- `standouts__run-0131.png`
- `stats__run-0131.png`
- `verification__run-0131.png`

No screenshots were missing. Manifest reports `expectedScreenshotCount: 19`,
`capturedScreenshotCount: 19`, `isPartialRun: false`.

## 3. Must-Fix Before Visual Lock

Only one finding rises to "must fix" — a copy issue, not a layout or color
issue. Everything else is bounded follow-up.

### 3.1 Conversation header subtitle reads as instructional copy

- **Screenshot**: `conversation_thread__run-0131.png`
- **What you see**: Below the avatar and name "Noa", the secondary line says
  literally `Tap name to view profile`.
- **Why it matters**: The active design-language doc explicitly calls out
  "Repeated 'tap here' instructional copy where the card affordance is clear"
  as an anti-pattern (`docs/design-language.md` § Anti-Patterns). Every
  conversation thread will show this line, so this single string is repeated on
  every chat the user opens. It also competes for the slot where stronger
  signal copy (last-active, location, match age, verified) belongs.
- **Likely source**: Hardcoded in
  [`lib/features/chat/conversation_thread_screen.dart:192`](lib/features/chat/conversation_thread_screen.dart#L192).
  It is the `else` branch for when no richer subtitle is available, but the
  fixture currently hits this branch every time.
- **Suggested direction**: Replace with a quiet truthful signal (e.g. an
  "Active now" / "Last active …" pill or location chip when available), or fall
  back to nothing rather than to instructional copy. The header already has the
  whole "Conversation / Back to chats" affordance, so the user does not need a
  second tap-instruction.

## 4. Should-Fix Soon But Not Blocking

These are worth fixing in a small focused pass, but should not extend the
current visual phase.

### 4.1 Discover candidate card reads as a dark slab in the visual review

- **Screenshot**: `shell_discover__run-0131.png`
- **What you see**: The active candidate card's primary-photo region is a dark
  charcoal/slate gradient with the candidate's monogram letter ("N") and a
  small image-placeholder icon in the corner. It dominates the middle of the
  first viewport and feels visually separate from the rest of the app's pastel
  surfaces.
- **Why it matters**: This is overwhelmingly a visual-fixture artifact — the
  fixture uses non-resolvable `/photos/...jpg` URLs (see
  `test/visual_inspection/fixtures/visual_fixture_catalog.dart:52` etc.), so
  every photo falls back to the placeholder. In production with real media,
  this slab becomes a real face. But the placeholder treatment itself looks
  more "broken image" than "polished pastel fallback" because of the dark
  gradient, and Discover is the highest-stakes surface in a dating product.
- **Likely source**: The candidate-card photo widget falls back to a dark
  gradient rather than a soft pastel avatar. Compare with the `UserAvatar` /
  `PersonPhotoCard` monogram fallback on `shell_matches` and `pending_likers`,
  which look polished even with no real photo. The candidate-card fallback
  should follow the same pastel-monogram recipe at a larger size.
- **Suggested direction**: Soften the no-photo fallback for the Discover
  candidate's primary image area to match the avatar-monogram recipe used
  elsewhere (soft pastel gradient, decorated initial). Do not change the photo
  area when real photos are present.

### 4.2 Matches dark mode "Message" gradient reads brighter than its surface

- **Screenshot**: `shell_matches_dark__run-0131.png`
- **What you see**: On each match card, the rose→violet gradient "Message"
  primary CTA looks luminous and slightly cool against the dark navy surface,
  while the rest of the screen (Active-now mint pill, "Matched 11 days ago"
  rose tag, location chips) is calmly desaturated. The CTAs visually pop in a
  way that feels off-temperature for the rest of the dark composition.
- **Why it matters**: Design language says "soften brightness and saturation
  against dark surfaces" and "preserve readable contrast" without becoming
  neon. Light-mode matches reads as harmonious; dark mode reads slightly
  unbalanced because of the gradient luminosity.
- **Likely source**: The matches-card primary-CTA gradient is shared across
  modes and not tuned per `Theme.of(context).brightness`.
- **Suggested direction**: Apply a softer dark-mode variant of the rose→violet
  gradient (lower lightness, slightly desaturated), the same pattern already
  used on the browse-screen Pass/Like row tinting (`_browseSky.withValues(alpha:
  ...)` brightness branching).

### 4.3 Discover Pass/Like row consumes the bottom viewport

- **Screenshot**: `shell_discover__run-0131.png`
- **What you see**: The bottom action row has a Pass outlined button and a
  rose-filled Like button at 48 px each, padded inside a softly tinted panel.
  Combined with the candidate card and the "Why this profile is shown" section
  above, the whole viewport ends with a dense action area that crowds the
  scroll axis.
- **Why it matters**: Hierarchy is correct (one primary, one secondary), so
  this is not a hierarchy bug — it is density. The screen reads as "a lot of
  primary surface in a small space."
- **Suggested direction**: Either reduce the panel padding around Pass/Like,
  collapse the "Why this profile is shown" inline section to a compact chip
  row, or both. Do not shrink the Like button itself.

### 4.4 Profile-edit "Save changes" floating bar uses primary-rose for a save action

- **Screenshot**: `profile_edit__run-0131.png`
- **What you see**: A full-width sticky pink/rose "Save changes" CTA at the
  bottom of the form.
- **Why it matters**: Forms-and-editing screens "should be calmer than display
  screens, but still expressive." A full-bleed rose primary at the bottom of
  every edit screen is louder than the verification flow's green CTA and
  louder than location's sky-blue CTA. The semantic tone for "save profile" is
  closer to the trust/active green family than to attraction-rose.
- **Suggested direction**: Either tone the gradient down to a quieter pastel
  rose, or move the save action color to the trust-green family used on
  Verification's `Send verification code` button.

### 4.5 Photos placeholder boxes on `profile_other_user` show monogram twice

- **Screenshot**: `profile_other_user__run-0131.png`
- **What you see**: The "Photos 2" tile under "Shared sections" shows two
  thumbnail squares, each with a soft teal tint, a centered photo-stack icon,
  and the candidate's initial "R" stamped large at the bottom. Two side-by-side
  squares with the same letter feel placeholder-y rather than designed.
- **Why it matters**: Identical letters in two adjacent tiles is the most
  visible "this is empty" signal in the visual review. In production these
  would be real photos, but for the lock review the letter twins make the
  Shared sections card look unfinished.
- **Suggested direction**: Either drop the monogram from non-primary thumbnails
  in the photo-grid fallback, or vary the gradient family between the two
  fallback tiles so the slot looks designed rather than duplicated.

## 5. Accept / Do Not Chase

These are imperfect but acceptable, or require backend/product decisions and
should not be solved visually right now.

- **Photo-fallback monograms across people screens**. Every `shell_matches`,
  `pending_likers`, `standouts`, `conversation_thread`, `profile_other_user`,
  `shell_profile`, and `app_home_startup` person tile shows a letter on a
  pastel avatar instead of a real photo. This is purely a fixture-data
  limitation (`test/visual_inspection/fixtures/visual_fixture_catalog.dart`
  uses unreachable `/photos/...jpg` URLs that never resolve in widget tests).
  Production rendering with real media will not look like this. Do not extend
  the visual phase to make the fixture render real images.
- **`shell_discover` candidate card hosting the only dark gradient surface in
  the entire app**. This is the photo-area fallback. Once the candidate card
  fallback is softened (4.1), this acceptance becomes permanent.
- **"Why this profile is shown" reasons block on Discover and on
  `profile_other_user`**. The reason chips ("Nearby", "Shared Interests",
  "Eligible Match Pool", "Same Relationship Goals") are server-driven —
  rendered from `ProfilePresentationContext.reasonTags` parsed via
  `parseStringList(json['reasonTags'])` in
  [`lib/models/profile_presentation_context.dart:25`](lib/models/profile_presentation_context.dart#L25).
  These are not client-fabricated reasons, so they do not violate the
  design-language rule "no invented compatibility logic or reasons in Dart."
  No action needed.
- **Stats hero "8 highlights / Active profile / Achievements" gradient slab and
  Achievements hero "2 milestones unlocked" gradient slab being relatively
  tall**. Both are explicitly allowed by the design language for "data and
  status screens" and they match the run-0070 references one-to-one. Do not
  reduce.
- **Match-screen header "Your matches / 5 matches ready · 0 new today" rose
  tint feeling slightly mauve-leaning in light mode**. The pink/rose accent is
  semantically correct for the matches/attraction family. The rest of the
  screen (mint Active-now pill, sky location chip, gradient Message CTA)
  introduces enough variety that this is not a one-color screen. Acceptable.
- **Blocked-users "Unblock" button using a rose color similar to primary
  attraction CTAs**. The whole screen sits in the safety-rose family per
  design-language guidance, and the action is constructive (unblock = restore),
  not destructive. Acceptable.
- **Developer-only callouts on `shell_settings` and `app_home_startup` using
  amber + "Developer only" pill**. Correct. Do not redesign.
- **`location_completion` Save-location CTA using sky-blue rather than
  rose/green**. Correct semantic — informational save, not emotional save.
  Acceptable.
- **Conversation thread incoming bubbles repeating no avatar after the first
  message**. This is a deliberate grouping decision — message content is the
  visual priority, sender context is shown once at the top. Acceptable.

## 6. Cross-Screen Patterns

### Repeated strengths

- **Section-label rhythm is consistent**: short vertical accent bar + bold
  title + thin horizontal rule + optional small count chip. This pattern
  appears on `notifications`, `notifications_dark`, `stats`, `achievements`,
  `shell_chats`, `shell_profile`, `shell_settings`, `standouts`,
  `pending_likers`, `blocked_users`, `app_home_startup`, `location_completion`,
  `profile_other_user`. It is the strongest cross-screen consistency signal
  and matches the run-0070 reference exactly.
- **Color variety is real, not cosmetic**. Across the suite, rose (matches /
  attraction), teal (chats), sky (informational, location, verification
  context), violet (profile, achievements), green/mint (active, trust,
  verification CTA), amber (developer-only, response time), and slate
  (fallback) all show up where they should. The previous "one-color mauve"
  failure mode is no longer present.
- **Hero treatment scales correctly with screen role**. Compact intros on
  Notifications, Chats, Standouts, Pending Likers, Blocked Users, Verification,
  Location. Tall expressive gradient heroes only on Stats and Achievements.
  Settings, Profile, and Discover use mid-weight identity surfaces. This
  matches the `docs/design-language.md` rule "use a large hero-like surface
  only when it has a specific reason."
- **Light/dark parity**. `notifications_dark` keeps the same semantic colors
  as the light variant with deeper tints — exactly what the design language
  asks for. `shell_matches_dark` carries the same structure as light with one
  small contrast caveat (4.2).

### Repeated weaknesses

- **Photo-fallback recipe is inconsistent between surfaces**. The avatar
  monogram recipe used on `shell_matches`, `pending_likers`, `shell_chats`,
  `standouts`, and the small thumbnails on `profile_other_user` is polished
  and pastel. The candidate-card primary photo on `shell_discover` falls back
  to a dark gradient that does not match the rest of the app. Two photo
  fallback systems exist where one would be enough.
- **Sticky-bottom primary CTAs vary in tone without a clear pattern**.
  Verification uses green (`Send verification code`), Location uses sky-blue
  (`Save location`), Profile-edit uses rose gradient (`Save changes`),
  Discover uses rose-fill (`Like`). Verification and Location are intentional
  semantic choices; Profile-edit is the outlier (4.4).
- **Instructional / placeholder microcopy creeps into product surfaces**. The
  `Tap name to view profile` line in conversation header (3.1) is the clearest
  example. This anti-pattern is documented and worth a one-pass sweep before
  lock.

### Shared-widget / theme-level patterns

- The section-label widget pattern, the `AppGroupLabel` accent-bar rule, the
  `AppTheme.surfaceDecoration(...)` soft-tinted card surface, the
  `UserAvatar` monogram fallback, and the semantic-icon-chip pattern are
  doing most of the cross-screen consistency work. These shared abstractions
  are healthy and should not be touched.
- The browse-screen `_BrowseInlineReasonSection` (sky-blue left bar + lightbulb
  icon) is well-themed but currently appears on a screen where it competes
  with the candidate card and the action row for first-viewport real estate.
  This is screen-composition, not a shared-widget bug.

## 7. Final Recommendation

**Stop generic visual polish now.** The canonical references match, the design
language is internally consistent, and the cross-screen color story works. The
remaining issues are bounded.

Smallest possible read-only-to-implementation handoff scope for the next
agent (a single focused pass, not a phase):

1. Replace `Tap name to view profile` (`conversation_thread_screen.dart:192`)
   with a quiet truthful signal or remove it (3.1).
2. Soften the Discover candidate card photo fallback to match the pastel
   avatar-monogram recipe used on `pending_likers` / `shell_matches` (4.1).
3. Tune the matches-card "Message" gradient brightness for dark mode (4.2).
4. Pick one tone for the Profile-edit `Save changes` CTA — either soften the
   rose, or align with the trust-green / sky-blue used on Verification and
   Location (4.4).
5. Optional small win: drop the duplicate monogram from non-primary thumbnails
   in the photos-grid fallback on `profile_other_user` (4.5).

After that pass, run the visual suite once more and lock. Do not extend the
visual phase further; subsequent quality-of-photo concerns will resolve
naturally once the app is exercised against real backend media rather than
fixture URLs.
