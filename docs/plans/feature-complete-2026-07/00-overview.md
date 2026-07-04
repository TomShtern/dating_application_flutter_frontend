# Feature-Complete Push — Overview & Ground Rules

**Date:** 2026-07-04
**Status:** ✅ **ALL PLANS COMPLETE** — implemented and `flutter analyze` clean on 2026-07-05
**Repo:** `flutter_dating_application_1` (Flutter frontend; thin client over a Java backend)
**Audience:** an implementing AI agent. Follow these plans literally. Where a plan gives a decision, that decision is final — do not re-litigate it.

## How to work through these plans

Execute the plan files **in numeric order**. Within a plan, execute tasks in the order written. After **every** task:

```powershell
flutter analyze
```

It must report `No issues found!`. If it doesn't, fix the issue you introduced before moving on. If you cannot fix it within a few attempts, **revert that task's edits and record it as skipped in your final report** — do not leave the tree broken, and do not "fix" analyzer errors by deleting unrelated code.

### Absolute rules

1. **No tests.** Do not write new tests. Do not run `flutter test` (not even the visual/screenshot suite). Verification = `flutter analyze` + code reading. This overrides anything CLAUDE.md says about running tests.
2. **Thin client.** Never invent business logic, compatibility scores, moderation states, or data the API does not return. If a plan says "backend gap — skip", skip it.
3. **Design system.** Use `AppTheme` tokens (`AppTheme.cardRadius`, `AppTheme.cardGap`, `AppTheme.compactSectionGap`, `AppTheme.surfaceDecoration(...)`, etc.) — no magic numbers for spacing/radius/shadows. Use `Material` + `InkWell` for tappable surfaces, never bare `GestureDetector`. Colors use `.withValues(alpha: x)` (this codebase does NOT use the deprecated `.withOpacity`).
4. **Riverpod 3.** `AsyncValue` has **no** `valueOrNull` — use `.value` (returns null when not in data state). `Notifier`/`NotifierProvider` style, not StateNotifier. Screens watch providers; controllers (plain classes behind a `Provider`) do side effects and `ref.invalidate(...)`.
5. **API layer stays centralized.** New endpoints go in `lib/api/api_endpoints.dart` + `lib/api/api_client.dart` using the existing helpers (`_expectMap`, `_extractMessage`, `Options(extra: {'userId': userId})`). Never add headers in feature code.
6. **Private widget constructors:** when you need to pass a `key` to a private widget (e.g. `_Foo`), add `super.key` to its constructor first — most private widgets here don't declare it.
7. Don't reformat or "clean up" code you aren't changing. Keep diffs minimal.
8. Don't touch `.env`, generated artifacts, `visual_review/`, or anything under `test/` (except: if `flutter analyze` flags an error **in a test file caused by your change** — e.g. you deleted a method a test imports — fix that reference minimally).

## What is ALREADY DONE (do not redo)

A previous session already implemented and verified (analyze-clean) all of the following. If a plan step seems to overlap with these, the plan wins; otherwise leave this work alone:

- **API:** `gracefulExit` + `archiveMatch` endpoints and `ApiClient` methods (`lib/api/api_endpoints.dart`, `lib/api/api_client.dart`).
- **Shell:** data-driven bottom-nav badges — Matches dot when a match is <24h old, Chats numeric badge from summed `unreadCount` (`lib/features/home/signed_in_shell.dart`, now a `ConsumerStatefulWidget`).
- **Auth:** password show/hide toggles + shared email regex validator (`lib/shared/forms/input_validators.dart`) in login/signup; formatted DOB label in signup.
- **Safety:** `gracefulExit` action in `SafetyActionSheet` (with confirmation); report now also requires confirmation; `SafetyAction` enum gained `gracefulExit`.
- **Matches:** card kebab is now `_MatchCardMenuButton` with "Archive match" (confirm dialog → `MatchesController.archiveMatch` → invalidates `matchesProvider`) and "Safety actions".
- **Chat:** thread screen invalidates `conversationsProvider` once after the thread first loads (unread badge sync). Optimistic send bubbles and per-group timestamps already worked — leave them.
- **Browse:** undo checks `result.success` and styles the failure snackbar; discovery preferences screen: removed the three dead "Not supported by the backend yet" sections, added min/max height + max-age-difference dealbreaker fields, added post-save snackbar.
- **Profile edit:** new "Lifestyle" section (smoking, drinking, kids, looking for, education — single-select grids; interests — chip editor with add field); all wired into the save `ProfileUpdateRequest`; checklist taps now scroll for `pace`/`gender`/`interestedIn`/`bio`/`photo`.
- **Verification:** confirm success invalidates `profileEditSnapshotProvider` + `profileProvider`; verified outcome card has a "Done" button that pops.

## Plan files

| File                                           | Scope                                                                                                                          | Risk                                | Status         |
|------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------|-------------------------------------|----------------|
| `01-profile-verified-and-lifestyle-display.md` | Verified badge on profiles; lifestyle facts on own profile; small edit-screen header addition; delete a dead model method      | Low                                 | ✅ Complete    |
| `02-photo-upload-ux.md`                        | Upload success/rejection feedback; dismiss for failed/rejected upload tiles                                                    | Medium                              | ✅ Complete    |
| `03-notifications-and-settings.md`             | Unread pill on Settings→Notifications row; client-side notification category muting; debug-only seeded-user switch in Settings | Medium                              | ✅ Complete    |
| `04-chat-and-misc-hardening.md`                | Local message id collision fix; standouts view-mode persistence; conversations search result count                             | Low                                 | ✅ Complete    |
| `05-secure-token-storage.md`                   | Move auth tokens to `flutter_secure_storage` with migration                                                                    | **High — do last, gate every step** | ✅ Complete    |

## Explicitly OUT OF SCOPE (do not attempt)

These were consciously excluded. Each is a backend contract gap or a product decision; building them now would mean inventing contracts.

- **Friend requests UI** (`/api/users/{id}/friend-requests*`): endpoints exist server-side but no response contract is documented anywhere in this repo. The notification registry already routes `FRIEND_REQUEST` types to profile/chat, which is enough for now.
- **Profile notes** (`/api/users/{authorId}/notes*`): documented as a moderation/admin surface — not a consumer feature of this app.
- **Account deletion**: no backend endpoint exists.
- **Presence/activity status in chat**: the `_showActivityIndicator => false` TODO in `conversation_thread_screen.dart` stays; backend has no presence data.
- **Device push tokens / backend-synced notification preferences**: no endpoints exist. Preferences remain device-local (plan 03 makes them *do* something locally).
- **`blockedAt` / block reason on blocked users screen**: `BlockedUserSummary` only has `userId`, `name`, `statusLabel` — the API doesn't return more.
- **Pagination UI** for matches/conversations/messages: the client methods accept `limit`/`offset` but product hasn't asked for infinite scroll; leave defaults.
- **Fixing existing widget tests**: the earlier session's UI changes (match card menu, signup DOB label, discovery prefs sections) may have broken some widget tests. Per the no-tests rule, do NOT run or repair them in this push; the user will schedule a separate test-repair pass.

## Final report format

When all plans are done, produce a summary listing per plan: tasks completed, tasks skipped (with the exact error that forced the skip), and files touched. Do not claim anything is "verified end-to-end" — you only have `flutter analyze` and code reading.
