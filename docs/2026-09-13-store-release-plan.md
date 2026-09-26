# Store-Release Plan — Frontend Workstreams & Backend Dependencies

**Date:** 2026-09-13
**Status:** Proposed — awaiting product decisions (see §8)
**Scope:** Google Play (Android-first), then iOS. Pending confirmation: no monetization, no presence/typing at launch.
**Sources:**
- Backend audit: `Date_Program/docs/BACKEND_STORE_RELEASE_AUDIT.md` (2026-09-13). Backend facts cited as `[BE]`.
- Frontend: direct code reading of this repo, cited by `file:line`.
- Prior planning: `docs/2026-04-30-path-to-first-alpha.md`, `docs/plans/feature-complete-2026-07/00-overview.md`.

Status labels: `[verified]` code-read · `[inferred]` necessary implication from code.

This document is the working plan for taking the frontend to a store release. It reconciles the backend audit with the frontend code and organizes the work by user journey. Items are marked either **FE** (frontend-only), **BE** (backend work required), or **FE+BE** (contract change consumed by frontend).

---

## 1. Current state (brief)

The app is functionally complete for a personal alpha: real auth (JWT + refresh + secure storage), full Discover → like/pass → match → chat journey, photos, profile edit, safety, notifications inbox, stats, verification, location. The visual system is mature. The 2026-04 "Path to first alpha" phases A1 (auth) and A3 (photos) are done; A2 (reachable HTTPS), A4 (onboarding funnel), and A5 (delete account) were never finished.

The backend audit confirms the backend is stronger than the frontend assumed in several places (auth, matching, safety, quotas, match quality, stats are real), and weaker in a few that matter at launch (no report body handling from the client, broken REST undo, anonymous profile enumeration, public unshrunk photos, no consent/email/push, simulated verification). Several backend responses compute exactly the data the frontend currently fakes (conversation unread/preview, badge counts, achievement progress) and then discard it — those enrichments are cheap.

The gap to a store release is therefore: 4 shipped breaks, a handful of compliance flows (consent, deletion, suspension, reset), the onboarding funnel, and consuming a batch of P0/P1 contract enrichments so the UI stops inventing data.

---

## 2. Confirmed shipped breaks (fix immediately, mostly FE-only)

### 2.1 Report always fails (FE, no backend change needed)

- Frontend sends an empty body: `lib/api/api_client.dart:333-347`.
- Backend requires `{reason, description?, blockUser}` and rejects without it: `[BE] SocialDtos.java:74`, `RestApiServer.java:1316-1336`.
- Current UI path: `lib/features/safety/safety_action_sheet.dart:172-175` → confirm → 400 error.
- **Fix:** build a report reason sheet with the backend taxonomy `SPAM, INAPPROPRIATE_CONTENT, HARASSMENT, FAKE_PROFILE, UNDERAGE, OTHER`, optional description, "also block this user" toggle; extend `reportUser` to send the body. Backend needs no change.

### 2.2 Undo is dead for REST likes (BE P0-2 + FE verification)

- Backend records undo state only in the desktop `processSwipe` path, not in `recordLikeWithinLock`; any REST like → `POST /undo` returns 409 "No recent swipe to undo" `[BE]`.
- Frontend undo affordance already handles failure (`browse_provider.dart` checks `result.success`), so the button currently always fails. Do not ship it pretending to work.
- **Fix:** wait for BE P0-2, then verify on device. No FE change should be required beyond testing.

### 2.3 Threads >50 messages show the oldest 50 and never the newest (FE+BE)

- Frontend always requests `limit=50, offset=0`: `lib/api/api_client.dart:718-742`, called without pagination from `lib/features/chat/conversation_thread_provider.dart:20-23`.
- Backend orders messages `created_at ASC` with LIMIT/OFFSET `[BE] JdbiConnectionStorage.java:551-563`, so page 1 is the **oldest** 50.
- Consequence: in a conversation longer than 50 messages, the newest messages are unreachable; polling refetches the same oldest page.
- **Interim (FE, now):** request `limit=100` (backend max) to reduce the window; document the limitation. **Real fix (BE P0-5):** add `order=desc` (or newest-window) + `totalCount`; then FE implements "load older" and switches pagination direction.

### 2.4 Error handling covers only 401/409 (FE)

- `lib/api/api_error.dart:10-29` passes through backend `message`; there is no dedicated copy for 429 (rate limit), 403 (blocked/non-participant), or session states.
- **Fix:** map 429 to a "Too many requests, try again shortly" message using `Retry-After`; map 403 to safety-appropriate copy; keep 409 messages verbatim (backend messages are user-readable, e.g. quota and no-active-match).

---

## 3. What the backend audit settles

These backend facts change what we build and what we must not fake:

1. Auth is solid and store-credible: BCrypt-12, 15-min HS256 JWT, rotated/revocable hashed refresh tokens `[BE]`.
2. Account deletion exists in-app (`DELETE /api/users/{id}`), revokes all refresh tokens, and allows email reuse. Missing: photo-file cleanup and a web deletion path (Play requirement) `[BE] P0-6`.
3. Report works server-side with reason taxonomy, persistence, and auto-ban at 3 reports. There is no moderation console, no appeals, and no message-level reporting yet `[BE] F2`.
4. Photos: raw bytes stored unmodified, EXIF/GPS preserved, served with no auth `[BE] P0-4`. No variants, no moderation pipeline, client already parses fields the backend never sends (`lib/models/photo_dto.dart:36-53`).
5. Chat: conversation summaries throw away unread count/preview/sender that the backend already computes `[BE] P0-5`; `GET messages` silently clears unread (the frontend correctly relies on this) `[BE] D2`.
6. Daily quotas are real (100 likes / 1 super-like / unlimited passes per user-timezone day) `[BE] C4`; no way to display them yet.
7. Match quality and stats are real server-side; the frontend fakes progress bars and activity patterns (`lib/features/stats/stats_screen.dart:830-840`).
8. Verification is simulated: the API returns the dev code in the response `[BE] B8`. Not a trust signal.
9. No email delivery, no password reset, no push, no presence/typing/read receipts, no consent records, no data export `[BE]`.
10. `GET /api/users` and `GET /api/users/{id}` are anonymous reads; the former must not ship `[BE] P0-3`. The frontend dev picker (debug-only) is the only consumer.

---

## 4. The plan by journey

### 4.1 Trust & Safety (launch blocker)

**Outcome:** every safety action a store reviewer expects actually works and is honest.

| # | Work item | Type | Depends on |
|---|---|---|---|
| TS-1 | Report reason sheet (6 reasons + optional text + block toggle) and request body | FE | — |
| TS-2 | Report/block entry points from chat thread and match cards (today only profile-adjacent surfaces) | FE | — |
| TS-3 | Consent at signup: ToS/privacy checkbox + links; Settings → Legal surface | FE+BE | BE P0-7 (consent storage), legal content |
| TS-4 | Delete account flow: Settings → Account → destructive confirm → `DELETE /api/users/{id}` → wipe local session → login | FE | In-app endpoint exists `[BE]`; BE P0-6 for web path + file cleanup |
| TS-5 | Suspension/restricted-account surface mapped from `accountStatus` instead of generic logout | FE+BE | BE P1-14 |
| TS-6 | 429/403/409 error copy | FE | — |
| TS-7 | Blocked list enrichment: show photo + blocked-at date | FE | BE P1-5 |
| TS-8 | Hide simulated verification from release builds; no verified badge until real delivery exists | FE+BE | BE P1-6 (prod guard), decision D-2 |

Notes:
- TS-3 needs actual ToS/privacy documents and a hosted policy URL (product task, also required by Play).
- TS-8: the frontend already hides the dev-code card and autofill behind `kDebugMode` (`lib/features/verification/verification_screen.dart:178-184,250-252`), but in release the user would enter step 2 with no code ever delivered — a dead end. Hide the verification entry point from release until BE P1-7/P1-6 land.

### 4.2 Account lifecycle

**Outcome:** a user can create, recover, and remove an account without developer help.

| # | Work item | Type | Depends on |
|---|---|---|---|
| AL-1 | Onboarding funnel + gate: signup → name → gender/interestedIn → location → first photo → bio → Discover; resumable from Profile | FE | Backend completion state already returned `[BE] B1/B2` |
| AL-2 | Password reset screens: request + confirm | FE+BE | BE P1-7 (email), P1-8 (endpoints), decision D-1 |
| AL-3 | "Log out everywhere" (optional at launch) | FE+BE | BE A5 |
| AL-4 | Data export request (post-launch acceptable) | FE+BE | BE A12 |

Notes:
- AL-1: the gate was deliberately removed (`lib/features/home/app_home_screen.dart:48-54`); `AuthUser.isProfileComplete` exists but has zero consumers (`lib/models/auth_user.dart:12-14`). Backend completion keys are `name, bio, birthDate, gender, interestedIn, location, photoUrls, pacePreferences`; `birthDate` is collected at signup and is not user-actionable in the funnel.
- AL-2: no deep-link/router infrastructure exists, so an email **code** flow (enter 6-digit code in app) avoids App Links/Universal Links work. Recommended.

### 4.3 Core loop quality

**Outcome:** the daily Discover → match → chat loop stops feeling improvised and stops showing invented data.

**Chat**

| # | Work item | Type | Depends on |
|---|---|---|---|
| CH-1 | Consume enriched conversation DTO: real avatar, last-message preview, last sender, unread | FE | BE P0-5; add `otherUserPhotoUrl` to `ConversationSummary` (`lib/models/conversation_summary.dart` parses preview/unread/sender but not photo) |
| CH-2 | Explicit mark-read call on thread open (stop relying on GET side effect) | FE | BE P1-2 |
| CH-3 | Message pagination: newest window + "load older"; fix auto-scroll on prepend | FE | BE P0-5 (`order=desc`, `totalCount`); interim mitigation in §2.3 |
| CH-4 | Stop full-screen loading flash on 20s poll refresh | FE | — |
| CH-5 | Presence/typing: keep the existing TODO stub; out of scope at launch | — | Decision D-6 |

**Discover**

| # | Work item | Type | Depends on |
|---|---|---|---|
| DI-1 | Daily pick card becomes actionable (open profile / like) | FE | BE P1-1 for mark-viewed; liking already works via the normal like endpoint |
| DI-2 | Remaining-likes indicator + quota messaging using `daily-status` | FE | BE P1-3 |
| DI-3 | Use candidate `bio`, `distanceKm`, `verified` when the backend adds them | FE | BE §5 DTO enrichment |

**Matches**

| # | Work item | Type | Depends on |
|---|---|---|---|
| MA-1 | Open the already-built `MatchFactorsSheet` from match cards (dead UI today, `lib/features/matches/match_factors_sheet.dart:16`) | FE | — |
| MA-2 | Replace the client-invented 24h "new match" rule with server `isNewMatch` (`lib/features/matches/matches_screen.dart:931-934`) | FE | BE P1-4 |
| MA-3 | Server-driven tab badges (`isNewMatch` + unread counts) instead of client sums (`lib/features/home/signed_in_shell.dart:42-64`) | FE | BE P1-4 |

**Notifications**

| # | Work item | Type | Depends on |
|---|---|---|---|
| NO-1 | Accept the notifications envelope + pagination; keep existing deep-link routing | FE | BE P1-13 |
| NO-2 | Keep device-local preference toggles until server-side preferences exist; do not add the OS permission prompt until there is something that fires (today channels/permission exist but nothing calls `show()`) | FE | BE P1-9 (push), decision D-6 |
| NO-3 | Wire tap handling for OS notifications when push/local delivery lands | FE | BE P1-9 |

### 4.4 Profile depth & polish

**Outcome:** profile and engagement surfaces read as a real product rather than placeholders.

| # | Work item | Type | Depends on |
|---|---|---|---|
| PR-1 | Other-user profile: lifestyle, interests, height (backend already computes; add to the read side) | FE | BE P1-12 |
| PR-2 | Stats/achievements: real `progressCurrent/progressTarget`; delete hash-based fake activity bars | FE | BE P1-10 |
| PR-3 | Standouts: map `reasonCode` to local copy; delete the string-matching humanizer (`lib/features/standouts/standouts_screen.dart:763-769`) | FE | BE P1-11 |
| PR-4 | Photo variants: use thumbnail/medium URLs when served; delete client fallbacks once fields arrive | FE | BE E1 |
| PR-5 | Shell-level connectivity/health banner (today only inside Browse diagnostics, `lib/features/browse/browse_screen.dart:469`) | FE | — |
| PR-6 | Gate/remove the `DeveloperOnlyCalloutCard` from release Settings (`lib/features/settings/settings_screen.dart:354-355`) | FE | — |
| PR-7 | Photo reorder UI (API wired, no drag UI) or remove the dangling path | FE | — |
| PR-8 | Accessibility pass: zero `Semantics` in `lib/features` + `lib/shared`; fixed-height layouts and color-only statuses on core flows | FE | — |
| PR-9 | Profile-completion checklist consistency: use backend `missingProfileFields` labels everywhere (`lib/models/profile_completion_info.dart` already parsed) | FE | — |

### 4.5 Release-day UX

**Outcome:** build, install, and first-run behave like a shipped app.

| # | Work item | Type | Depends on |
|---|---|---|---|
| RX-1 | Maintenance + minimum-version screens with soft-forced update | FE | BE P1-16 |
| RX-2 | Env fail-fast in release (today defaults bake `http://127.0.0.1:7070` + `lan-dev-secret`, `lib/app/env.dart:4-12`); point release builds at the HTTPS host | FE+BE | BE P0-8 |
| RX-3 | App identity: real applicationId/bundle id, release signing, app name/icon/splash, versioning | FE | — |
| RX-4 | Crash reporting (e.g. Sentry) with release tags; remove raw error `debugPrint`s | FE | — |
| RX-5 | First-run empty states / coach marks for Discover, first like, first match, first message | FE | — |

---

## 5. Sequencing and dependencies

Order is chosen so frontend work never blocks on backend work and shipped breaks are fixed first.

| Wave | Contents | Gate |
|---|---|---|
| **W0 — Immediate fixes** | TS-1, TS-2, TS-6, CH-4, PR-6, PR-5, §2.3 interim | None (FE-only) |
| **W1 — Compliance flows** | TS-3 (behind field), TS-4 (in-app), AL-1, TS-8 decision implementation | In-app delete + completion state already exist; consent field needs BE P0-7 |
| **W2 — Contract consumption begins** | CH-1, CH-2, DI-1, MA-1, MA-2, MA-3, NO-1, TS-7, PR-1..PR-3 | BE P0-5, P1-1..P1-5, P1-10..P1-13 |
| **W3 — Reset & release plumbing** | AL-2, TS-5, RX-1, RX-2, RX-3, RX-4 | BE P1-7/P1-8, P0-6, P0-8, P1-14, P1-16 |
| **W4 — Polish** | CH-3 full pagination, DI-2/DI-3, PR-4, PR-7..PR-9, RX-5 | BE P0-5, P1-3, E1 |
| **W5 — Verify & harden** | On-device pass of every journey against release backend; a11y; performance | All P0s |

Rule: nothing in W2+ gets "mocked up" against a contract the backend has not committed to. The audit's proposed contracts (§9 Appendix B) are specific enough that backend and frontend can implement in parallel once the proposals are accepted.

---

## 6. Out of scope at launch (explicit)

- Presence, typing indicators, read receipts (BE D5/D6) — keep the existing TODO stub.
- Push notifications (FCM) — keep in-app list; do not ask for OS notification permission until delivery exists.
- Monetization, subscriptions, boosts/superlikes (BE H2/H3) — declare "no purchases" at launch.
- Friend requests UI and profile notes (endpoints exist; no consumer contract) `[BE]`.
- Message attachments, edit/delete/tombstone, pin/mute (BE D7/D8).
- Data export (BE A12) — post-launch acceptable; Play only requires deletion, not export.
- iOS parity beyond the build working — Android first.
- WebSocket/real-time transport.

---

## 7. Store-compliance checklist (frontend/product view)

| Item | Status | What remains |
|---|---|---|
| In-app account deletion | Works (`DELETE /api/users/{id}`) | Delete-account UI (TS-4) |
| Web deletion path | Missing | Backend page + email flow (BE P0-6); a product-hosted URL |
| Block/report enforcement | Backend real | Fix report UI/body (TS-1); moderation console and appeals are post-launch |
| Age assurance 18+ | Enforced at signup | Lock DOB editing (BE B9); underage-report action flow |
| Consent records | Missing | Consent UI + storage (TS-3, BE P0-7) |
| Privacy policy URL | Missing | Product-hosted doc; link in signup + Settings |
| Photo privacy | Broken | EXIF strip + serving hardening (BE P0-4) |
| Data safety disclosure | Missing | Derive from BE audit J4; includes Nominatim lookup disclosure |
| Content rating | Ready | Declare dating/UGC; moderation = report + auto-ban |
| Payments | N/A | Declare no purchases |

---

## 8. Decisions needed (with recommended defaults)

| # | Decision | Recommended default |
|---|---|---|
| D-1 | Password reset UX: email **code** vs link | Code — no deep-link infra exists |
| D-2 | Verification at launch: hide vs ship as non-trust "contact added" | Hide from release until real delivery (BE P1-7) |
| D-3 | Onboarding gate strictness | Hard-gate Discover/Matches/Chats until `profileCompletionState == complete`; land user in Discover afterward |
| D-4 | Sequential vs parallel against proposed contracts | Fix W0 now; accept the audit's DTO proposals so FE and BE implement in parallel (no new clients in the wild yet, so envelopes can break) |
| D-5 | Legal content (ToS/privacy) exists? | Must exist before TS-3 and Play submission |
| D-6 | Confirm no presence/typing and no push at launch | Confirm; keep the stubs and skip the notification permission prompt |
| D-7 | Confirm Play-first, no monetization | Confirm |
| D-8 | Deliverable follow-up: execution plan with per-file tasks + coding-agent prompt | To be produced after decisions above |

Product decisions the backend audit asks for (accept defaults unless changing):
envelope adoption for list responses (accept), "new match" = 24h and no messages (accept), undo window 30s (accept), rematch cooldown 168h (accept), no match expiry at launch (accept), auto-ban at 3 reports (accept), additive-only API policy until v2 (accept).

---

## 9. Appendix A — Backend P0/P1 register (condensed)

Full detail: `Date_Program/docs/BACKEND_STORE_RELEASE_AUDIT.md`.

**P0 (blocks store release):**

| ID | Gap | Frontend impact |
|---|---|---|
| P0-1 | Client sends no report body | Report UI + body (TS-1) |
| P0-2 | REST likes never record undo state | Undo dead until fixed |
| P0-3 | Anonymous `GET /api/users`, `GET /api/users/{id}` | Dev picker dies; profile read requires auth (client already sends it) |
| P0-4 | EXIF/GPS preserved; `/photos/*` public, no cache headers | Photo trust + data-safety disclosure |
| P0-5 | Conversation/message DTOs lack unread/preview/sender/photo; messages oldest-first; no totals | CH-1/CH-3, §2.3 |
| P0-6 | No web deletion path; photo files orphaned on delete | TS-4, Play compliance |
| P0-7 | No consent records | TS-3 |
| P0-8 | Release config defaults (JWT/shared secrets, localhost binding) | RX-2 |

**P1 (credibility):** P1-1 daily-pick viewed; P1-2 explicit mark-read; P1-3 daily quota status; P1-4 `isNewMatch`/badges; P1-5 blocked-list enrichment; P1-6 honest verification; P1-7 email delivery; P1-8 password reset; P1-9 push tokens; P1-10 achievement progress; P1-11 standout `reasonCode`; P1-12 other-user lifestyle/interests; P1-13 notifications envelope; P1-14 `accountStatus`; P1-15 auth throttling; P1-16 maintenance/min-version.

---

## 10. Appendix B — DTO enrichment proposals the frontend will consume

Exact shapes proposed by the backend audit (existing fields unchanged; additions only):

1. `GET /api/users/{id}/conversations` → `{conversations:[{id,otherUserId,otherUserName,otherUserPhotoUrl,messageCount,lastMessageAt,lastMessagePreview,lastSenderId,unreadCount}],totalCount,limit,offset,totalUnreadCount}`.
2. `GET /api/conversations/{id}/messages` → `{messages:[...],totalCount,limit,offset,oldestFirst}` or `order=desc`.
3. `MatchSummary` + `isNewMatch`, `unreadCount`, `lastMessageAt`.
4. `UserSummary` (browse/pending likers) + `verified`, `bio`, `distanceKm`.
5. `StandoutDto` + `reasonCode`.
6. Like response + `dailyStatus{likesUsed,likesRemaining,superLikesUsed,superLikesRemaining,resetsAt}`.
7. `BlockedUserDto` + `blockedAt`, `primaryPhotoUrl`.
8. Notifications envelope `{notifications,unreadCount,totalCount,limit,offset}`.
9. Achievements + `progressCurrent`, `progressTarget`, `catalogVersion`.
10. `AuthUserDto` + `accountStatus`, `verified`, `state`.
11. `PhotoDto` sends `thumbnailUrl`, `mediumUrl`, `moderationStatus`, `rejectionReason`, `primary`, `sortIndex`, `createdAt` (client already parses these).
12. `UserDetail` + `interests`, `lifestyle{...}`, `heightCm`.

---

## 11. Appendix C — Frontend endpoint inventory (current)

See `lib/api/api_endpoints.dart` for the authoritative list. 32 endpoints: health, auth (5), users/profile (5), photos (4), location (3), safety (6), discovery (6), matches (3), conversations/messages (3), engagement (3), notifications (3), verification (2).

Headers today: shared secret on all `/api/` except health; bearer on all protected routes; legacy `X-User-Id` still attached on user/conversation routes (`lib/api/api_headers.dart:10-50`). Backend treats bearer subject as identity and requires `X-User-Id` to match when present `[BE]`.

---

## 12. Documentation debt

- `README.md` and `FLUTTER_PROJECT_HANDOFF.md` still claim "no real auth/JWT, no signup, no photos; push out of scope" — false since the July feature-complete push. Update when this plan is accepted.
- `docs/plans/feature-complete-2026-07/00-overview.md` §"Explicitly OUT OF SCOPE" is now partially outdated (secure token storage, onboarding state, and several enrichments landed or are planned). Mark superseded by this document.
- Backend `docs/API-SPECIFICATION.md` contradicts backend code on error shape, password minimum, and scope `[BE]` — fix on the backend side.
