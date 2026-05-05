# UI Visual Review: Dating Application

Verified against run-0143 screenshots and `docs/design-language.md` on 2026-05-05.

Each screen is rated by severity: 🔴 Critical (major UX/usability problem), 🟡 Moderate (clear improvement needed), 🟢 Minor (polish pass).

---

## 🔴 Sign In (`app_home_startup`)

**What works:** Clean, minimal form. Dev-login shortcut is clearly separated.

**Issues:**
- Zero visual identity. No app name, logo, illustration, or brand presence whatsoever — the screen is a plain white form floating in empty space.
- The dark maroon "Sign in" button is disconnected from the app's pastel design system. Nothing on this screen hints at what the product actually is.
- Massive dead white space below the form (~60% of the screen is blank).

**Improvements:**
- Add a brand element: app name, tagline, or a subtle romantic illustration above the form.
- Add a soft pastel gradient or tinted background so the screen participates in the app's visual language.
- Style the CTA button using the primary brand color or a soft gradient to match the aesthetic found in the rest of the app.
- Consider a compact "welcome back" moment rather than a raw utility form.

---

## 🔴 Shell Discover (`shell_discover`)

**What works:** The intro header communicates useful state (candidate count, browsing-as context, daily pick chip, undo). The "Why this profile is shown" section provides server-driven reasoning with tag chips.

**Issues:**
- The intro area + chips + undo button consume roughly 30% of the first viewport before any profile content appears. This violates the design-language principle of "useful state first" and compact entries.
- The profile card uses a grey letter avatar ("N") instead of a compelling photo. Even with test data, the card layout doesn't give photos visual priority — the photo area is small and secondary.
- The "Pass" button has very low contrast — a white/pale outlined button on a pale pink background. It's easy to miss next to the bold pink "Like" button.
- The "Why this profile is shown" section, while useful, pushes the action buttons (Pass/Like) below the fold. Users have to scroll past reasoning text to act.
- The "See full profile" link is a low-contrast teal text link that competes with the "Why this profile is shown" card below it.

**Improvements:**
- Collapse the intro area into a slim, sticky header with the essential state (candidate count + refresh). Move chips and undo into a compact toolbar or overflow.
- Redesign the profile card to make the photo area dominant — ideally large or edge-to-edge when real photos are available. The photo should be the first thing the user sees.
- Make Pass/Like buttons high-contrast floating action buttons (FABs) pinned at the bottom, always visible without scrolling.
- Move "Why this profile is shown" below the fold or into an expandable section so it doesn't compete with the primary browse-and-act flow.

---

## 🟡 Shell Matches (`shell_matches`)

**What works:** Good semantic signals — "Matched X days ago" pills, location chips, "Active now" indicators. The All/New filter tabs are useful. The intro header is compact and informative.

**Issues:**
- Match cards are excessively tall because each card includes a full-width pink "Message" button and a "View profile" button side by side. This means only ~3 matches are visible at a time on a phone screen.
- The two large buttons inside every card create visual noise and make each card look like a competing advertisement rather than a list item.

**Improvements:**
- Remove the full-width "Message" and "View profile" buttons from inside each card.
- Make the entire card tappable (opening the profile), and add a small chat icon button on the trailing edge for direct messaging.
- This would roughly double the visible match density, making the list much more scannable.

---

## 🟡 Shell Chats (`shell_chats`)

**What works:** Clean teal semantic color. Good section label ("Open conversations" with count). Date stamps on the trailing edge. The intro header is compact.

**Issues:**
- Each conversation row shows "X messages so far." as subtitle text AND a teal "X messages" pill below it — the same count appears twice in every row, which is redundant.
- The subtitle "12 messages so far." tells the user nothing useful about the conversation's state. Users care about *what* was said last, not how many messages exist.

**Improvements:**
- Replace the "X messages so far." subtitle with a snippet of the last message (or "You: ..." / "Noa: ..." prefix).
- Keep only one message-count indicator — either the pill or inline text, not both.

---

## 🟡 Conversation Thread (`conversation_thread`)

**What works:** Clear sender/recipient distinction with teal (sent) vs grey (received) bubbles. Readable text. Date group separators ("Apr 23") are well-designed with a teal clock icon. Back navigation and overflow menu present. Participant context (name + "Tap name to view profile") at the top.

**Issues:**
- The bubble contrast is acceptable but could be slightly stronger — the sent bubbles (light teal) are on the softer side.
- The input field is bare — just a text field and send arrow. No attachment or media affordance.

**Improvements:**
- Consider darkening the sent-bubble teal slightly for better readability, particularly in bright ambient light.
- Add a '+' or camera icon to the input area as a placeholder for future media attachment.
- These are lower-priority polish items — the thread is functional and readable as-is.

---

## 🟢 Shell Profile (`shell_profile`)

**What works:** The pastel detail cards (Gender, Interested in, Location, Distance, Status) are aesthetically nice. The large circle avatar works well here as the user's identity anchor. The chips (Active, Tel Aviv, 50 km) are clean. The "About" section with its icon is well-structured. Section label ("Profile sections") follows the design-language pattern.

**Issues:**
- The detail grid has a single orphan card ("Status") on the last row that doesn't fill the available width, creating visual asymmetry.
- The "Profile details" card's subtitle "The signals currently shaping discovery." is a bit vague for a user-facing label.

**Improvements:**
- Ensure the detail grid handles odd item counts gracefully — either stretch the last card to full width or add a placeholder slot.
- Consider tightening the subtitle to something more direct like "Discovery preferences" or similar.

---

## 🟡 Profile Edit (`profile_edit`)

**What works:** Clean section organization (Photos, Basics, Interested in). The intro header with status chips (Active, Tel Aviv, 2 photos, Verified) is informative. The "Save changes" FAB is prominent. Gender/interest selection with pastel chips is nice.

**Issues:**
- The photo slots show "P" letter placeholders with a generic copy/document icon overlay. The "P" doesn't clearly communicate "empty photo slot" to the user.
- The photo thumbnails blend into the card background — their boundaries aren't visually distinct.

**Improvements:**
- Replace the "P" letter placeholders with a clear "+" icon inside the pastel rounded slot, making it obvious these are empty slots waiting for a photo.
- Add a subtle border or slightly different tint to distinguish photo thumbnails from the card background.

---

## 🟢 Shell Settings (`shell_settings`)

**What works:** This is one of the better-designed screens. The quick-access list items use decorated pastel icon chips with appropriate semantic colors (teal for stats, amber for notifications, green for verification, rose for blocked users, violet for achievements). The developer-only section is clearly labeled and visually separated with a "Developer only" badge. The compact intro header with status chips (Dana, Active profile, Light theme) is useful.

**Issues:**
- Minor: the "Quick access" section subtitle ("Open the essentials faster.") takes up space without adding much value.

**Improvements:**
- Consider removing or shortening the "Quick access" subtitle since the section's purpose is self-evident from the items.
- This screen is largely well-designed and low priority for changes.

---

## 🟡 Blocked Users (`blocked_users`)

**What works:** The section label with count ("Blocked profiles 4") follows the design-language pattern. Block reasons are shown as tagged pills (Repeated spam, Inappropriate messages, etc.).

**Issues:**
- The "Unblock" action uses a lock/padlock icon, which is semantically backwards — a lock implies locking someone out, not releasing them.
- The entire screen uses a uniform rose/salmon tint across every card. While the design-language doc prescribes "rose, coral, slate" for safety screens, using one rose tone for everything creates a monotone "error state" feeling rather than a management list.
- The intro "Safety controls" card with a large shield icon takes up significant first-viewport space for relatively little information.

**Improvements:**
- Use an unlock icon (or just text without an icon) for the "Unblock" action.
- Introduce some visual variation between cards — perhaps use slightly different rose/coral/slate tints, or add the block-reason category as a subtle color differentiator.
- Compact the intro card — the safety explanation doesn't need to be as large.

---

## 🟢 Notifications (`notifications` & `notifications_dark`)

**What works:** This is a reference-quality screen per the design-language doc. Each notification type already has a distinct semantic icon chip (violet heart for match, teal message icon, green person icon for friend request, blue bell for updates). Background tints vary by type. Section labels ("Today", "Yesterday", "Earlier") with counts follow the compact grouped pattern. The "Unread only" and "Mark all read" actions are well-placed. Dark mode retains the same personality with appropriately softened colors.

**Issues:**
- Very minor: the trailing arrow buttons could have slightly more visual distinction between actionable and read notifications.

**Improvements:**
- This screen is already well-designed and serves as the design-language reference. Low priority for changes.

---

## 🟡 Location Completion (`location_completion`)

**What works:** Clean form layout. The "Suggested cities" section with a section label and count chip is well-structured. The closest-match toggle with explanation is a nice UX touch. The intro card ("Match area") provides clear context.

**Issues:**
- The "Save location" button uses a solid teal fill. While teal is semantically associated with location in the design system, the button's color weight is noticeably heavier than the rest of the form's softer aesthetic.
- The city text field border appears standard Material outline — it's functional but doesn't participate in the app's pastel styling.

**Improvements:**
- Soften the "Save location" button — consider a teal-tinted outlined or lighter-filled style that blends with the form's calmer aesthetic (per design-language: "Forms should feel expressive but calmer than feeds").
- Apply the app's pastel field styling to the form inputs for consistency with other edit screens.

---

## 🟡 Verification (`verification`)

**What works:** Clear step indication. The benefit chips ("Verified badge", "More trust", "Better matches") communicate value well. The "How it works" explainer section at the bottom is helpful. Green semantic color for verification/trust is correct per the design-language doc.

**Issues:**
- "Step 1 of 2" appears as a coral pill in the top card, and "Step 1" appears again as green text heading the second card. The same step is labeled twice in different colors.
- The progress bar sits between the two cards, making it look disconnected — it floats in no-man's-land rather than anchoring to either card.
- The email input field has a rose/pink border which clashes with the green verification theme used everywhere else on this screen.

**Improvements:**
- Remove the duplicate step indicator — keep either the top pill or the section heading, not both.
- Move the progress bar to the top of the screen (below the title) or anchor it inside one of the cards.
- Align the input field border color with the verification green theme for consistency.

---

## 🟡 Achievements (`achievements`)

**What works:** Clear section organization (Unlocked vs Still building). Achievement cards have clean structure: icon chip, title, description, status pill, progress indicators. The "40% complete" progress bar in the hero is informative.

**Issues:**
- The hero card gradient (violet to pink) is very strong and saturated, dominating the first viewport. Per the design-language doc, gradients should be "purposeful" and reserved for "summaries, milestones, special status panels" — the hero qualifies, but the intensity is higher than the rest of the app's soft aesthetic.
- The individual achievement icon chips all use the same amber/gold treatment, making it hard to distinguish achievement categories at a glance.

**Improvements:**
- Soften the hero gradient — reduce saturation while keeping the violet-to-pink direction to maintain the celebratory feel.
- Consider varying the icon chip color by achievement category (e.g., teal for conversation milestones, rose for match milestones, amber for activity milestones) to add visual variety per the semantic color system.

---

## 🟡 Standouts (`standouts`)

**What works:** Server-provided reasons are displayed prominently ("Shared pace, music taste, and strong conversation chemistry."). The pick rank badges ("Top pick", "Pick #2", etc.) add useful differentiation. Location chips are present. A Grid/List view toggle already exists in the UI.

**Issues:**
- In list mode, the cards are moderately tall due to the full-width reason text taking significant vertical space. With letter avatars (test data), the cards feel text-heavy and lack visual punch.
- The grid mode exists but may not be the default — list mode shows first and feels like the weaker presentation for a "standouts" surface that should feel special and visually engaging.

**Improvements:**
- Default to grid view for standouts, which would create a more visually engaging gallery-style presentation (especially when real photos are available).
- In list mode, consider truncating the reason text to one line with "..." to reduce card height and improve density.

---

## 🟡 Pending Likers (`pending_likers`)

**What works:** The intro card communicates the situation clearly ("5 people liked you" with guidance text). The "Open profile first" chip sets user expectation. Person cards show name, age, bio snippet, location chip. Overflow menus (three-dot) are present per card for contextual actions.

**Issues:**
- The cards are plain — they have a rose-tinted avatar ring and basic text, but lack any visual signal about *why* this person liked you or what makes them interesting. The server-provided "Open profile first" nudge is the only context.
- The intro card uses a rose heart icon that blends with the card's pink tint, making the icon less visible.
- No timestamp or recency signal per pending liker — users don't know if the like is from today or two weeks ago.

**Improvements:**
- If the API provides any pending-liker signals (e.g., shared interests, activity level), surface them as compact chips on each card.
- Add a recency indicator (e.g., "Liked 2h ago") if the backend provides it.
- Increase the icon contrast in the intro card.

---

## 🟢 Other User Profile (`profile_other_user`)

**What works:** The profile snapshot card is well-structured with avatar, name/age, status chips (Active, location, distance). Like/Pass buttons are clearly visible in the hero. The "Shared sections" label follows the design pattern. The "Why this profile is shown" section with server reasons and checkmark-prefixed explanations is informative.

**Issues:**
- Photo thumbnails show letter placeholders ("R") — same issue as profile edit, though this is expected with test data.
- The "Why this profile is shown" section is duplicated here AND on the discover card, so users see the same reasoning twice if they navigate from discover → profile.

**Improvements:**
- When navigating from discover, consider collapsing or hiding the "Why this profile is shown" section on the profile page since the user already saw it.
- Ensure photo thumbnails have clear "no photo" states that look intentional rather than broken.

---

## 🟢 Stats (`stats`)

**What works:** This is a reference-quality screen per the design-language doc. The summary hero card is compact and informative (highlights count, status chips, achievements shortcut). The snapshot grid uses semantic colors correctly (coral for likes sent, rose for likes received, indigo for matches, etc.). The performance section tiles (conversations started, reply rate, response time) each have their own semantic color and mini visualization (bar chart, progress ring). Section labels are clean.

**Issues:**
- Very minor: no issues worth changing. This screen is design-locked per the previous review.

**Improvements:**
- None. This screen serves as the design reference alongside Notifications.
