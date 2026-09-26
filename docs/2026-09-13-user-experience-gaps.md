# User Experience Gaps — What the User Feels and Sees

**Date:** 2026-09-13
**Lens:** strictly the user-facing product. No infrastructure, no release config, no accessibility audit.
**Method:** every screen read in code; claims cite `file:line`. Labels: `[verified]` code-read · `[inferred]` reasonable reading of UI code.
**Companion doc:** `docs/2026-09-13-store-release-plan.md` (contracts, sequencing, compliance). This file is the *product* counterpart: features and capabilities.

Status legend per item: **FE-only** = buildable today · **needs data** = blocked on a backend field/endpoint (named where known).

---

## 0. What already feels good (don't break these)

- Safety sheets with confirm dialogs; per-row busy locks on destructive actions.
- Like-match snackbar with a working "Message now" jump (`browse_screen.dart:148-170`).
- Empty states on Matches, Chats, Likers, Notifications with refresh and next-step hints.
- "Why this profile is shown" presentation context on browse/profile.
- Profile completeness checklist inside edit.
- Notification tiles that route to chat/profile, with honest display-only fallback for the rest.
- Unread counts on the Chats tab and conversation rows.

---

## 1. First five minutes: signup → welcome → "who am I here?"

**Today `[verified]`:** signup collects email + password + date of birth (`signup_screen.dart:22-27,103-131`) and drops the user straight into the full shell. No name step, no welcome, no guidance. Login says "Welcome back" (`login_screen.dart:355`) but signup says nothing at all.

**Missing:**
1. **A welcome moment.** No greeting, no value proposition, no "here's how this works" — the product starts with a populated Discover tab and the user has to infer the mental model. **FE-only.**
2. **A profile-creation funnel.** Name, photos, location, bio are scattered across Settings/Profile/Edit with no order and no gating. New users browse before they exist as a profile. The completion checklist exists but nothing walks anyone through it. **FE-only** (completion keys already returned by backend).
3. **Photo guidance.** "Add photo" button with zero advice (`profile_edit_screen.dart:1557`); no examples of good photos, no face-visible tips, no "profiles with photos get seen" nudge. Dating-app 101 and entirely content. **FE-only.**
4. **First-run coach marks.** Swipe cues exist on the card (`browse_screen.dart:593-598`) but nothing explains Discover on first visit, nothing celebrates the first like, first match, first message. **FE-only.**
5. **Login options.** Email + password only; no forgot-password path, no biometrics, no social sign-in. Users who mistype a password once have no recovery. (Reset needs backend; biometric/social are product decisions.) **Needs data for reset; FE-only for biometric prompt.**
6. **Permissions staging.** Camera/photos/typography of asks happen at point of use with no soft-ask; notifications permission has no "why" screen. **FE-only content.**

## 2. Discover: browsing, deciding, the match moment

**Today `[verified]`:** one card at a time ("1 of N ready", `browse_screen.dart:1079-1083`), Pass/Undo/Like buttons plus swipe cues, filters/standouts/likers reachable only through Discover header icons (`browse_screen.dart:293-316`). Cards show photo, name/age, summary, location pills when data exists; graceful fallbacks otherwise.

**Missing:**
1. **An "It's a Match!" moment.** A mutual like produces a snackbar. No celebration screen, no confetti, no side-by-side photos, no "say something" prompt. For a dating app this is *the* emotional peak of the product and it currently feels like a toast notification. **FE-only** (like result already returns `isMatch` + `matchId`).
2. **A way to stand out.** No Super Like, no Boost, no Roses, no "interested" signal — every expression of interest is identical. Users have no tool for the one profile they really care about, and the product has no attention mechanic at all. **Needs data** (new product surface + endpoints).
3. **Tappable daily pick.** The "Featured for today" card (`browse_screen.dart:908-1015`) is display-only — the most prominent card on the screen can't be opened, liked, or passed. Feels broken. **FE-only.**
4. **"Why this profile" on the card itself.** Presentation context exists one tap away but the card shows no reason chips inline; users can't learn what the product values about them. **FE-only.**
5. **Verified-only and intent filters.** Height/age/distance/dealbreaker filters exist; there is no "verified profiles only" and no "looking for" intent filter. Trust-seeking users can't express the most basic trust preference. **Needs data** (candidate filter).
6. **Rewind that works.** The undo button is always visible and currently always fails (backend doesn't record REST undo state). A permanently failing button reads as a broken product. Either fix the contract or show the button only when an undo is actually available. **Needs data; FE owns the honest state.**
7. **Swipe-away motion.** Swiping triggers like/pass (`Dismissible` at `browse_screen.dart:593-611`) but the card never animates away (`confirmDismiss` returns false) — the gesture feels dead and the queue visibly refetches. Cards should fly off and the next card should already be underneath. **FE-only.**
8. **Feedback on Pass.** Passing gives no confirmation of any kind — no subtle animation, no "you won't see them again" note. Users can't tell it did anything. **FE-only.**
9. **Like quota visibility.** Backend enforces 100 likes/day, but the UI never shows a count or reset. Users hit an invisible wall with a 409 message and no context. **Needs data** (`daily-status` endpoint proposed).
10. **Discovery beyond the queue.** No search, no "recently joined", no second-look surface for passed profiles. When the queue empties, the product is over for the day. **Needs data.**

## 3. Matches: list, understanding, acting

**Today `[verified]`:** cards open the profile on tap (`matches_screen.dart:506-509`), a message button jumps to the thread, All/New filters exist, archive + safety live in a menu. Empty state is good.

**Missing:**
1. **"Why did we match?"** `MatchFactorsSheet` is fully built and reachable nowhere (`match_factors_sheet.dart:16`). Users can never see compatibility, distance, or highlights — the single most differentiating surface in the app is dead code. **FE-only** (one wiring change).
2. **New-match guidance.** New matches show a "NEW MATCH" badge computed client-side from a 24h rule (`matches_screen.dart:931-934`) and the subtitle says "Say hi to start your first conversation" (`matches_screen.dart:770`) — but there is no suggested opener, no profile reminder of *why* you liked them, nothing to solve the blank-page problem. **FE-only** (static openers + server `isNewMatch` later).
3. **Search and sort.** All/New filters only; no name search, no "most recent", no "unread first". At 20+ matches the list is unscannable. **FE-only** (client-side filter on loaded page).
4. **Match list photos always load.** Cards fall back to initial-avatars whenever photo fields are absent; a wall of letter-avatars reads as empty even when it isn't. Needs the photo enrichment, but the skeleton/placeholder treatment can improve regardless. **Needs data + FE polish.**
5. **Match history honesty.** Archive/unmatch/graceful-exit exist, but there is no visible distinction afterward, no "you archived this" state, no way back from an accidental archive. **FE-only** (labels + confirm copy; un-archive needs backend).

## 4. Chat: the list and the thread

**The list today `[verified]`:** search across the loaded page, rows with name + generic fallback preview + time, real unread chips (`conversations_screen.dart:640-643`), initials avatars, tap to open. Empty state is good with a first-message nudge (`conversations_screen.dart:299`).

**The thread today `[verified]`:** a bare `TextField` (`conversation_thread_screen.dart:205-218`), optimistic send with retry, day grouping, header with initials avatar, the literal subtitle "Tap name to view profile" (`:625`), menu with view-profile/safety/refresh. Empty thread shows one static line (`:841`).

**Missing — the list:**
1. **Real previews and photos.** Rows show invented fallbacks ("Tap to continue…") and letter avatars because the summary lacks preview/sender/photo. A chat list where every row looks identical is unusable at a glance. **Needs data** (enrichment already computed server-side).
2. **Row management.** No swipe actions: archive, mute, pin, mark-read, delete. No long-press menu. Conversations can only accumulate. (Archive endpoint exists; mute/pin need backend.) **Partially FE-only.**
3. **Accurate unread.** Today the client trusts an undocumented server side effect to clear unread. If it ever misfires, badges lie. **Needs data** (explicit mark-read).

**Missing — the thread:**
4. **Anything beyond plain text.** No photo sharing, no GIFs, no stickers, no voice notes, no emoji affordance — the composer is a bare field. Even texting apps cleared this bar a decade ago; dating competitors all do photo + GIF + voice. **Needs data** (largest chat investment; phase it: photos first, then voice, then GIF provider).
5. **Copy/select text.** Messages aren't selectable (`SelectableText` appears nowhere in chat; the only one in the app is the verification code). Users can't copy an address, a joke, or a red flag to a friend. **FE-only.**
6. **Reactions and replies.** No emoji reaction, no quote-reply, no way to respond to one message in a fast thread. Conversations stay flat and context-free. **Needs data.**
7. **Delivery truth.** No sent/delivered/read ticks — only local sending/failed states (`message_dto.dart:11-22`). Users can't tell a sent message from a seen one. **Needs data.**
8. **Presence signals.** No online/last-active, no "typing…". The client hardcodes the activity indicator off with a TODO (`conversation_thread_screen.dart:54-55`). Chats feel like talking into a mailbox. **Needs data** (explicitly deferred at launch; keep the stub honest).
9. **Message management.** No edit, no unsend, no per-message report, no search-in-thread, no forward. The only recovery from a typo is another message. **Needs data** (delete-by-sender exists server-side; surface it first).
10. **Conversation starters.** The empty thread says "Start the conversation when you're ready" and stops. No icebreaker suggestions, no profile-based openers ("you both like…"), no first-message templates. **FE-only.**
11. **A header that respects the user.** "Tap name to view profile" as a permanent subtitle reads like a debug label. Replace with last-active time (when presence exists) or nothing. **FE-only.**
12. **Background arrival.** Messages only appear when Chats is open and polling runs. Users must remember to check. (Push is the technical answer; the *felt* gap is "the app never tells me anything.") **Needs data.**

## 5. Profiles: viewing others, your own, editing

**Viewing others today `[verified]`:** hero photo, conditional sections that vanish when data is missing, like/pass decision row that locks after one decision, presentation-context expander, verified badge, safety + refresh in the app bar.

**Your own today:** hero, details, completeness card, Edit + Refresh. **Editing today:** one long scrolling form with lifestyle grids, interest chips, photo tiles (set-primary/delete via menu, "Add photo" button), location via completion screen, checklist with scroll-to-section.

**Missing:**
1. **Profile preview ("see yourself as others see you").** No mode, no toggle — users publish blind. The single highest-leverage profile feature and it's just a view filter over existing data. **FE-only.**
2. **Photo fullscreen viewer.** The hero isn't tappable (no `onTap` anywhere in `profile_screen.dart`); photos can't be zoomed or swiped through fullscreen; the gallery section is a plain list (`profile_screen.dart:1339-1359`). Photos are the product and they're shown at thumbnail fidelity. **FE-only.**
3. **Expression depth.** No prompts-and-answers, no photo captions, no voice intros, no video. Every profile is name/age/photos/bio/interests — the format competitors won with (Hinge prompts) is absent. **Needs data.**
4. **Profile sharing.** No share-profile link, no "ask a friend" flow — yet dating decisions are social. **Needs data** (deep links) for outside-app; **FE-only** for screenshot-safe in-app share card.
5. **Decision-row forgiveness.** Liking/passing from a profile locks permanently with no inline undo — one mis-tap is final and the only recovery is leaving to Discover's (broken) undo. Add inline undo while the sheet is open. **FE-only.**
6. **Sparse-profile handling.** When someone has no bio/photos/location, sections disappear and the profile reads as broken rather than new. Show intentional "new here" states instead of holes. **FE-only.**
7. **Edit-form wayfinding.** A ~2000-line single scroll with no progress indicator: users can't tell what's left beyond the checklist card, and saving gives one snackbar. Add a sticky completeness meter + per-section save states. **FE-only.**
8. **Photo management.** Set-primary/delete only; no drag reorder, no visible "n of 6" cap, no primary badge on the tile itself. **FE-only** (reorder API exists).
9. **Distance and recency honesty.** "Active now" is inferred from account state, not presence; distance display depends on optional fields. Prefer hiding these signals over showing invented ones. **FE-only.**

## 6. Attention surfaces: likers, standouts, notifications

**Today `[verified]`:** pending likers and standouts live behind Discover header icons; likers force a profile open to decide (intro copy admits it); standouts open profiles; notifications list with mark-read and chat/profile routing, honest display-only fallback otherwise.

**Missing:**
1. **Quick decisions on likers.** No like/pass buttons on liker cards — every decision costs a full profile open. The highest-intent queue in the app has the slowest interaction. **FE-only.**
2. **Standouts meaning.** No refresh cadence ("fresh picks daily"), no countdown, no explanation of what a standout *is*; reasons are backend sentences the client rewrites by string matching. Add cadence copy + reason codes. **FE + needs data.**
3. **Friend-request actions.** `FRIEND_REQUEST` tiles show an icon but accept/decline UI doesn't exist anywhere, though four endpoints do. A notification type that can never be acted on. **FE-only** (endpoints exist).
4. **Notification richness.** No preview content beyond title/body, no images, no inline actions (like-back, reply). **Needs data.**
5. **Attention math.** No likes-you count, no "X people liked you" nudge, no standout-ready ping logic — the app never tells users they're wanted. Some of this is push (later); the in-app counts are available sooner. **Needs data.**

## 7. Trust, safety, and control (user-feel edition)

**Today `[verified]`:** safety sheets on browse/profile/thread, block/report/unmatch/graceful-exit with confirms, blocked list with unblock, verification two-step, Settings rows for stats/notifications/verification/blocked/achievements/appearance/session.

**Missing:**
1. **Report reasons.** One generic "Report user" with no reason options (`safety_action_sheet.dart:172-175`) — the user can't say *why*, and the report currently fails outright. Six options + optional note + block toggle. **FE-only** (contract already accepted server-side).
2. **A safety center.** No safety tips, no date-planning checklist, no "share your date plan", no check-in, no resources. Safety exists only as reactive buttons. Content + two small features. **Mostly FE-only content.**
3. **Verification users can understand.** The flow promises "clearer trust signal to matches" (`verification_screen.dart:64`) while the mechanism is a self-echoed code — and the badge just says "Verified". Either make it real or relabel it to what it proves ("contact confirmed") until then. **FE copy + backend guard.**
4. **Account control.** No pause-my-profile, no delete-account, no download-my-data. Users can't take a break, leave, or see what the product holds. (Delete endpoint exists; pause/export need backend.) **Partially FE-only.**
5. **Visibility controls.** No "hide my distance", no read-receipt toggles, no online-status toggle, no photo-visibility tiers. Privacy is all-or-nothing. **Needs data.**
6. **Support surface.** Settings contains zero help content — no FAQ, no contact, no about/version, no terms/privacy links (verified: no matches for help/faq/support/contact/about/version/feedback in `settings_screen.dart`). Users with a problem have nowhere to go inside the product. **FE-only content.**
7. **Language.** English only, no in-app language choice. **Needs data + product decision.**

## 8. Delight and polish

1. **Motion.** No card fly-away, no like burst, no match celebration, no micro-transitions between tabs. The app reads as correct but lifeless. **FE-only.**
2. **Haptics.** No tactile feedback on like, match, send, or destructive confirms. **FE-only** (one-line calls at decision points).
3. **Sounds.** No send/receive/match sounds (with a mute toggle). Optional but standard. **FE-only.**
4. **First-time magic.** Covered in §1.4; restating because it's the cheapest delight available: celebrate the first like, first match, first message explicitly.
5. **Stats with meaning.** Stats/achievements are buried under Settings with numbers that explain nothing ("why should I care?") and detail sheets that echo the number back. Either surface one meaningful insight where users live (e.g. profile views on your own profile) or cut the surface until it means something. **FE + needs data.**

---

## 9. Suggested build order (user-impact first)

T-shirt sizes: **S** ≤ a day · **M** ≤ 3 days · **L** ≤ a week. Ordered by what users feel most.

### P0 — feels broken or absent at the core
| # | Item | Size | Type |
|---|---|---|---|
| 1 | "It's a Match!" celebration screen with photos + message CTA (§2.1) | M | FE-only |
| 2 | Report reasons + working report (§2 break 1, §7.1) | M | FE-only |
| 3 | Copy/select message text (§4.5) | S | FE-only |
| 4 | Tappable daily pick (§2.3) | S | FE-only |
| 5 | Wire up "Why we matched" sheet (§3.1) | S | FE-only |
| 6 | Chat pagination that shows the newest messages (§2 break 3) | M | FE interim now; full with data |
| 7 | Welcome + profile-creation funnel (§1.1, §1.2) | L | FE-only |
| 8 | Photo fullscreen viewer (§5.2) | M | FE-only |
| 9 | Profile preview mode (§5.1) | M | FE-only |
| 10 | Quick like/pass on liker cards (§6.1) | M | FE-only |

### P1 — the product starts feeling real
| # | Item | Size | Type |
|---|---|---|---|
| 11 | Icebreaker suggestions in empty threads + new-match guidance (§3.2, §4.10) | M | FE-only |
| 12 | Swipe-away card motion + pass feedback (§2.7, §2.8) | M | FE-only |
| 13 | Haptics at decision points (§8.2) | S | FE-only |
| 14 | Search matches; row management for chats (archive/mark-read) (§3.3, §4 list 2) | M | FE-only |
| 15 | Friend-request accept/decline (§6.3) | M | FE-only (endpoints exist) |
| 16 | Photo tips + first-run coach marks (§1.3, §1.4) | S | FE-only content |
| 17 | Safety center content + date-plan sharing (§7.2) | M | FE-only content |
| 18 | Support surface: FAQ/contact/about/terms links (§7.6) | S | FE-only content |
| 19 | Real conversation previews/photos/unread (§4 list 1–3) | M | Needs data |
| 20 | Like quota visibility (§2.9) | S | Needs data |
| 21 | Server `isNewMatch` + badges (§3 follow-ups) | S | Needs data |
| 22 | Delete-account + pause-profile UI (§7.4) | M | Partially FE-only |
| 23 | Consent + legal surfaces (§7 follow-ups) | S | Needs data + content |

### P2 — depth and differentiation
| # | Item | Size | Type |
|---|---|---|---|
| 24 | Super Like / Boost attention signals (§2.2) | L | Needs data + product design |
| 25 | Prompts & answers, photo captions (§5.3) | L | Needs data |
| 26 | Voice intros; video loops later (§5.3) | L+ | Needs data |
| 27 | Photo/GIF/voice messages, phased (§4.4) | L+ | Needs data |
| 28 | Reactions + quote-reply (§4.6) | M | Needs data |
| 29 | Delivery ticks + typing/presence (§4.7, §4.8) | M | Needs data |
| 30 | Message edit/unsend/report; thread search (§4.9) | M | Needs data |
| 31 | Verified-only + intent filters (§2.5) | M | Needs data |
| 32 | Visibility/privacy controls (§7.5) | M | Needs data |
| 33 | Video/voice calls, date planning, who-viewed-me | L+ | Needs data + product design |

---

## 10. Explicitly not in this file

Release plumbing, backend internals, accessibility remediation, and compliance paperwork live in `docs/2026-09-13-store-release-plan.md`. Anything here marked "needs data" names its contract there (§10 Appendix B) or in the backend audit.
