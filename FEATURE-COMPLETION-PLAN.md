# Feature Completion Plan — Flutter Dating App

**Date:** 2026-10-12
**Repo:** `flutter_dating_application_1`
**Status:** Verified and refined. Nothing implemented yet.

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` (recommended) or `executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close every gap that is verifiably absent from the current source, split into Flutter work that ships now and a precise backend contract the Java team can build against.

**Architecture:** The app is a strict thin client over a Java/Javalin backend (`AGENTS.md`). Most remaining gaps are either frontend-only, or backend-blocked and therefore only specified as a contract. The one true cross-repo defect — messages returned oldest-first — gets a documented client-side mitigation now and a formal handoff for the real fix.

**Tech Stack:** Flutter / Dart, Riverpod 3 (`flutter_riverpod: ^3.3.1`), Dio 5, Material 3, `AppTheme` tokens. Deps of note already present: `image_picker ^1.1.2`, `shared_preferences ^2.5.5`, `url_launcher ^6.3.3`, `app_links ^7.2.2`, `shorebird_code_push ^2.0.7`.

---

## Global Constraints

Copy these into every task. They apply to all implementation.

- **Thin client.** Never invent business logic, compatibility scores, moderation state, or data the API does not return. If a task is backend-blocked, write the contract and stop — do not fake the feature in Dart.
- **Design system.** Use `AppTheme` tokens: `cardRadius` / `panelRadius` / `chipRadius` (`app_theme.dart:34-36`), `cardGap` (`:42`), `cardPadding`, `sectionPadding()`, `sectionSpacing()` (`:529`), `surfaceDecoration(...)` (`:467`), `screenPadding()` (`:501`). No magic numbers for spacing, radius, or shadow.
- **Tappable surfaces** are `Material` + `InkWell`, never bare `GestureDetector`. Existing example: `_SettingsLinkTile` (`settings_screen.dart:876-880`).
- **Colors** use `.withValues(alpha: x)`. This codebase does **not** use the deprecated `.withOpacity`.
- **Riverpod 3.** Use `Notifier`/`NotifierProvider`, not `StateNotifier`. For `AsyncValue` use `.requireValue` where a value is guaranteed and `.value` where it may be null — both are used in this repo (see `conversation_thread_provider_test.dart:176,188` and `presence_provider`). There is no `valueOrNull`.
- **API layer stays centralized.** Endpoints go in `lib/api/api_endpoints.dart`, calls in `lib/api/api_client.dart`, using the existing helpers (`_expectMap`, `_expectList`, `Options(extra: {'userId': userId})`). Never add headers in feature code.
- **Backend photos need auth headers.** Load only through `AppNetworkImage` (`lib/shared/widgets/app_network_image.dart:14`) or `AuthenticatedPhotoImage` (`lib/shared/media/authenticated_photo_image.dart:18`), never `Image.network`.
- **Prefer existing dependencies over new ones.** A new native plugin cannot ship as a Shorebird patch — `scripts/patch.ps1` refuses native diffs, so a native dependency forces a full release. Use `url_launcher`, `image_picker`, `shared_preferences`, or Flutter framework APIs before adding a package.
- **Testing policy (user decision):** add tests for models, providers, DTOs, parsing, and pagination/merge logic. **No new widget or screenshot tests.** Existing tests that break from a refactor are repaired, never extended beyond the repair.
- **Verification per task:** `flutter analyze` reports `No issues found!`, plus `flutter test` on the task's own tests and any existing suite the change touches. Judge UI from screenshots, not assertions.
- **Keep diffs minimal.** Do not reformat code you are not changing. `analysis_options.yaml:10` includes `package:flutter_lints/flutter.yaml`.
- **Do not** touch `.env`, `.env.release`, `android/key.properties`, `shorebird.yaml`, or generated artifacts.
- This plan publishes nothing. Every release or patch publish needs your explicit OK, per invocation.

---

## Evidence Register

Every claim below was read from source, not from `README.md` or the stale `docs/2026-09-13-user-experience-gaps.md`. Line numbers are the anchors the tasks edit.

| # | Claim | Evidence |
| --- | --- | --- |
| E1 | Messages return oldest-first; client caps at 100 | `conversation_thread_provider.dart:20-28` (comment naming backend ticket BE P0-5), `:27` `limit: 100` |
| E2 | `getMessages` accepts `offset` but the caller never passes it | `api_client.dart:756-757` (defaults), `:762` (queryParameters), caller at `conversation_thread_provider.dart:24-28` |
| E3 | Merge/sort logic is reusable and located here | `conversation_thread_provider.dart:325-361`; comparator `:342-359` |
| E4 | Local optimistic messages are a separate provider | `:31-35`, `:37-54`, `:210-323` |
| E5 | Truncation is a hardcoded boolean, not server state | `conversation_thread_screen.dart:319`, `:981`, `:990`, `:1004-1010` |
| E6 | The truncation notice copy is factually wrong | `conversation_thread_screen.dart:1216-1217` — says "most recent messages" while E1 means oldest |
| E7 | Two list implementations; only one shows the notice | `:296` `useSparseLayout = messages.length <= 4`; `_MessageList` `:973`; `_SparseMessageList` `:1028-1083`; notice `:1186-1229` |
| E8 | Composer is text-only, no attach affordance | `conversation_thread_screen.dart:371-391` (`TextField`, `maxLines: 3`), send button `:394-400` |
| E9 | No photo cap constant anywhere in `lib/` | `grep maxPhotos\|photoLimit\|kMaxProfilePhotos` → no matches |
| E10 | The photo UI models **4** slots, not 6 | `profile_edit_screen.dart:1670-1675` (`emptySlots`, `effectiveCount >= 4`), `:1704` `_PhotoEmptySlot` |
| E11 | "Add photo" has no guard | `profile_edit_screen.dart:1429-1468` (`_handleAddPhoto`), button `:1626-1635` |
| E12 | Photo reorder is drag-only, no accessible alternative | `:1858-1908`, `DragTarget` `:1880`, `LongPressDraggable` `:1887` |
| E13 | `BrowseCandidate` carries **no** verification field | `browse_candidate.dart:3-35` — fields are `id, name, age, state, primaryPhotoUrl, photoUrls, approximateLocation, summaryLine` |
| E14 | Verification exists only on `UserDetail` and own-snapshot read-only | `user_detail.dart:13,26,48`; `profile_edit_snapshot.dart:214,222,231` (`ProfileEditReadOnly.verified`) |
| E15 | `DiscoveryPreferences` is the persistence seam for browse prefs | `discovery_preferences.dart:9-91`; `fromProfileEditSnapshot` `:30-41`; `toProfileUpdateRequest` `:43-51` |
| E16 | `ProfileUpdateRequest` builds an explicit payload | `:81-154`; the `interestedIn`/`interests` wipe rule `:4-11,55-79` |
| E17 | The `verifiedOnly` preference cannot round-trip through the backend | `ProfileEditEditable` (`profile_edit_snapshot.dart:34-109`) has no such field in ctor `:35-60` or `fromJson` `:81-108`, so there is no read path |
| E18 | Device-local preference pattern exists | `app_preferences.dart:23-56`; `app_preferences_provider.dart:28-32,34-49`; store `:8-11` |
| E19 | Screen-reader labels mostly exist as tooltips | 36 `tooltip:` uses across 13 files, e.g. `browse_screen.dart:574` "Undo last swipe", `:1113` "Super Like", `matches_screen.dart:616`, `conversation_thread_screen.dart:772,798,1246` |
| E20 | Only 3 explicit `Semantics`/`ExcludeSemantics` calls | `presence_widgets.dart:111`, `:161`; `update_banner.dart:167` |
| E21 | The swipe card is a `Dismissible` with no semantics | `browse_screen.dart:774-787`; cue labels `:764`, `:769` |
| E22 | `AppAsyncState` is a const `StatelessWidget` | `app_async_state.dart:7-27` — const ctors at `:8,13,17` |
| E23 | `SectionIntroCard` is not dismissible | `section_intro_card.dart:5-23`; no dismiss affordance, `trailing` `:78` |
| E24 | `MatchCelebrationDialog` has no match-count or `isMatch` param | `match_celebration_dialog.dart:14-28` |
| E25 | No localization plumbing at all | `pubspec.yaml` has no `flutter_localizations`/`intl`/`generate:`; no `l10n.yaml` in repo |
| E26 | `friend-request` notification types are registered but unreachable | `notification_item.dart:119-126`; `notification_preferences.dart:113-114`; `notifications_screen.dart:1210-1215`; no endpoint in `api_endpoints.dart` |
| E27 | Multipart upload pattern already exists to copy for chat media | `api_client.dart:958-976` (`uploadPhoto`), `:966` `FormData.fromMap` |
| E28 | Test files the plan needs already exist | `test/features/chat/conversation_thread_provider_test.dart` (fake with `getMessagesCalls` `:303`, override `:320-334`), `test/models/discovery_preferences_test.dart`, `test/features/profile/photo_edit_provider_test.dart`, `test/features/settings/app_preferences_provider_test.dart` |
| E29 | Existing screen tests will be affected by UI edits | `test/features/chat/conversation_thread_screen_test.dart`, `test/features/browse/browse_screen_test.dart`, `test/features/matches/matches_screen_test.dart`, `test/features/settings/settings_screen_test.dart` |

---

## What Changed From The First Draft

The first draft was written from partial reading and contained six errors that would have caused real damage. They are recorded here so nobody re-introduces them.

| Draft error | What is actually true | Consequence if shipped |
| --- | --- | --- |
| Task 4 filtered `List<BrowseCandidate>` on a `verified` flag | `BrowseCandidate` has no verification field (E13) | The task would not compile. Rewritten to preference-storage only (Task 4). |
| "Photo backend cap is 6" | No cap exists anywhere in code (E9). The UI models **4** slots (E10) | A fabricated limit would hide the real behaviour and the counter would be wrong. Rewritten with `kProfilePhotoSlots = 4` and honest copy (Task 2). |
| `Semantics` at `update_banner.dart:134`; "two calls in the entire app" | `Semantics` is at `update_banner.dart:167`; there is also `ExcludeSemantics` at `presence_widgets.dart:161` (E20) | Wrong anchor and a misleading picture of a11y coverage. |
| "Blind users cannot operate discovery, matches, or chat" | Icon actions are already labelled by 36 tooltips (E19) | Would have triggered a pointless rewrite of working code. Task 5 now targets only real gaps. |
| Tasks 1/2/4 "create" test files | Those test files already exist (E28) | Overwriting them would have deleted 350 lines of passing coverage. All three now say **extend**. |
| Task 10 keyed first-match copy off `isMatch` | `MatchCelebrationDialog` has no such param (E24) | Would not compile. Task 10 now adds a `matchCount` plumbing decision instead. |

---

## Review Focus

Failure modes no single task's tests catch. Each is assigned to the task that owns the code.

1. **A message arriving mid-pagination.** The user taps "load older" while a poll replaces the thread; a naive prepend duplicates or drops messages. — Task 1.
2. **`offset` past the end.** A stale offset after the other person deletes history returns an empty page mid-scroll; the list must not collapse. — Task 1.
3. **Pagination flips the layout branch.** `useSparseLayout` is `messages.length <= 4` (E7). Growing the list swaps `SingleChildScrollView` for `ListView.builder` mid-pagination and loses scroll position. — Task 1.
4. **The notice lies.** Today's copy claims "most recent messages" (E6) while the backend sends oldest-first. Any new copy must match reality. — Task 1.
5. **A drag-only reorder is unreachable.** A screen-reader or keyboard user cannot reorder photos at all (E12). — Task 5.
6. **RTL and long translations overflow.** German/French growth must not overflow composer, match cards, or settings rows; text must scale to 200%. — Task 6.
7. **A new native dependency blocks patching.** `share_plus` carries Android/iOS code, which `patch.ps1` refuses. — Task 3.

---

## Phase A — Critical correctness (do first)

### Task 1: Message history pagination

**Closes gap:** history caps at the *oldest* 100 messages; newer messages can be invisible in long threads, and the notice misdescribes what is on screen.

**Why this is first:** E1 documents backend ticket BE P0-5 — the messages endpoint returns oldest-first, so `offset=0` yields the *first* 100 messages. In a 500-message thread the newest messages never load. `ApiClient.getMessages` already accepts `offset` (E2), so the client work is possible now. This is the highest-value fix in the plan and it is also the one with real edge cases.

**Files:**
- Modify: `lib/features/chat/conversation_thread_provider.dart`
- Modify: `lib/features/chat/conversation_thread_screen.dart`
- Extend: `test/features/chat/conversation_thread_provider_test.dart` (**exists** — do not overwrite, E28)

**Interfaces:**
- Produces `class ConversationThreadPage { const ConversationThreadPage({required this.messages, required this.hasMore, this.isLoadingMore = false}); final List<MessageDto> messages; final bool hasMore; final bool isLoadingMore; }`
- Produces `conversationThreadPagedProvider` — `NotifierProvider.family<ConversationThreadPagingNotifier, ConversationThreadPage, String>`
- Produces `Future<void> ConversationThreadPagingNotifier.loadMore()`
- Produces `int get pageSize => 100;`
- Consumes `ApiClient.getMessages(conversationId:, userId:, limit:, offset:)`
- Reuses `_mergeConversationMessages` (`:325-361`) — do not duplicate its comparator

**Design decisions already made (do not re-litigate):**

- **Wrap, do not replace.** `conversationThreadProvider` (`:13-29`) and the 20 s poll in the screen stay exactly as they are. The paging notifier holds *history* pages and merges them with the live provider, so polling keeps working unchanged.
- **De-duplicate by `id`, and by `localId` for optimistic rows.** `_matchesLocalMessage` (`:317-322`) already shows both keys matter.
- **`hasMore` is derived from a short page, never from a counter.** A page returning fewer than `pageSize` rows means the tail was reached. Track it as `hasSeenEnd`.
- **Never trust `sentAt` ordering across pages for correctness.** Re-sort with the existing comparator after every merge (E3).

- [ ] **Step 1: Write the failing tests** in `test/features/chat/conversation_thread_provider_test.dart`. Extend `_FakeConversationThreadApiClient` (`:293-353`) to be **offset-aware**: record `lastOffset` and return the slice for that offset, rather than the current clamped-index behaviour at `:329-333`. Add:

  - `'a full first page reports hasMore'` — 100 rows → `hasMore == true`.
  - `'a short page clears hasMore'` — 37 rows → `hasMore == false`.
  - `'loadMore prepends the next window without duplicating ids'` — seed 100 at offset 0, `loadMore()` fetches offset 100, assert 200 messages and `ids.toSet().length == 200`.
  - `'loadMore is a no-op once hasMore is false'` — assert `getMessagesCalls` does not increase.
  - `'loadMore keeps optimistic local messages pinned at the end'` — queue one `MessageDto.localSending(...)`, `loadMore()`, assert it is still last.
  - `'a poll during loadMore neither duplicates nor drops messages'` — start `loadMore()`, trigger `refresh()` mid-flight, `await` both, assert no duplicate `id` and ascending `sentAt`. **(Review Focus 1)**
  - `'an empty page past the end keeps the list intact'` — force a short page then another `loadMore()` that returns `[]`; assert messages unchanged and no crash. **(Review Focus 2)**

- [ ] **Step 2: Run the tests to confirm they fail** — `flutter test test/features/chat/conversation_thread_provider_test.dart`. Expected: FAIL, `ConversationThreadPage` undefined.

- [ ] **Step 3: Implement the paging notifier.**

  Keep `conversationThreadProvider` (`:13-29`) untouched. Add the page class and a notifier that:
  - Holds the accumulated history list, `hasMore`, `isLoadingMore`.
  - `loadMore()` uses the number of server rows returned by earlier history pages as the next `offset` (not the merged count, which also holds optimistic and polled messages), calls `getMessages(limit: pageSize, offset: offset)`, merges via the existing comparator path, and sets `hasSeenEnd` when the page is short.
  - Exposes the merged view through `conversationThreadMessagesProvider` (`:37-54`) so local optimistic messages still win.

- [ ] **Step 4: Fix the oldest-first problem, and fix the copy that lies.**

  Because the backend returns the oldest window first (E1), page 1 is **not** the newest messages. Until BE P0-5 lands, the client must walk forward until it has seen the tail: `loadMore()` continues while `hasMore` is true, and only then is the thread genuinely complete. Drive the notice from `hasMore`/`hasSeenEnd`, **not** from `messages.length`.

  Replace the misleading text at `conversation_thread_screen.dart:1216-1217`. New copy, matching reality:
  - While walking: `Older messages are still loading.`
  - When complete: `You're at the start of this conversation.`
  Do not write "most recent messages" or "older history stays on the server" — both are false under E1/E6. **(Review Focus 4)**

- [ ] **Step 5: Wire the notice into both list implementations.**

  `_MessageList` takes `historyTruncated` (`:981`, `:990`, `:1004-1010`). `_SparseMessageList` (`:1028-1083`) has no such prop at all (E7). Give both the same source of truth. **(Review Focus 3)**

- [ ] **Step 6: Freeze the layout branch so pagination cannot flip it.**

  `useSparseLayout` is computed as `messages.length <= 4` (`:296`). Once pagination grows the list past 4, the branch flips from `SingleChildScrollView` to `ListView.builder` and the scroll position is lost. Change the predicate to depend on the *initial* load size only, captured once. **(Review Focus 3)**

- [ ] **Step 7: Run tests and analyzer.**

  `flutter test test/features/chat/conversation_thread_provider_test.dart test/features/chat/conversation_thread_screen_test.dart` then `flutter analyze`. Expected: PASS, `No issues found!`. Repair existing screen-test expectations to the new copy rather than weakening the tests.

- [ ] **Step 8: Commit.**

  ```bash
  git add lib/features/chat/conversation_thread_provider.dart lib/features/chat/conversation_thread_screen.dart test/features/chat/conversation_thread_provider_test.dart test/features/chat/conversation_thread_screen_test.dart
  git commit -m "feat(chat): paginate message history and correct the truncation notice"
  ```

---

## Phase B — Fast wins

### Task 2: Profile photo slots, counter, and guard

**Closes gap:** no indication of how many photos are expected or allowed; "Add photo" (`profile_edit_screen.dart:1634`) always looks available (E11).

**Verified facts:** there is no backend cap constant anywhere (E9), and the UI already models **4** slots (`:1670-1675`, `:1704`) (E10). So the honest change is to name the constant the UI already assumes, show a counter, and stop the picker opening when the slots are full. Do **not** invent a limit of 6 — the first draft did, and it was wrong.

**Files:**
- Modify: `lib/models/photo_dto.dart`
- Modify: `lib/features/profile/profile_edit_screen.dart:1626-1635,1670-1675`
- Extend: `test/features/profile/photo_edit_provider_test.dart` (**exists**, E28)

**Interfaces:**
- Produces `const int kProfilePhotoSlots = 4;` in `lib/models/photo_dto.dart`
- Produces `bool canAddPhoto(int currentCount) => currentCount < kProfilePhotoSlots;`
- Produces `String photoSlotLabel(int currentCount)` → `'1 of 4'` … `'4 of 4'`

- [ ] **Step 1: Write the failing tests** — `canAddPhoto` true at 3, false at 4; `photoSlotLabel(1) == '1 of 4'`; `photoSlotLabel(4) == '4 of 4'`; a test that the upload count (not just stored photos) is what is counted.

- [ ] **Step 2: Confirm they fail** — `flutter test test/features/profile/photo_edit_provider_test.dart`. Expected: FAIL, symbols undefined.

- [ ] **Step 3: Implement the constant and helpers** in `lib/models/photo_dto.dart`, next to `PhotoListResponse` (`:89-119`).

- [ ] **Step 4: Count uploads, not only stored photos.** `:1670-1674` already computes `effectiveCount` by adding in-flight uploads. Reuse that expression for both the counter and the guard so a pending upload cannot be bypassed by tapping "Add photo" again.

- [ ] **Step 5: Gate the button and show the counter.** Replace the unconditional button at `:1626-1635`:
  - Below the cap: `FilledButton.tonalIcon` as today, plus the counter text beside it.
  - At the cap: a disabled tile reading `That's all 4 photo slots.` and no picker call.
  Put the counter in the section header so it is always visible, not only after tapping.

- [ ] **Step 6: Add a test that the picker is never opened at the cap** — assert `_handleAddPhoto` returns before `showModalBottomSheet` when `!canAddPhoto(effectiveCount)`. This is the local-refusal check from Review Focus 3.

- [ ] **Step 7: Run tests and analyzer.** Expected: PASS / clean.

- [ ] **Step 8: Commit.**

  ```bash
  git add lib/models/photo_dto.dart lib/features/profile/profile_edit_screen.dart test/features/profile/photo_edit_provider_test.dart
  git commit -m "feat(profile): show photo slot count and block uploads past it"
  ```

---

### Task 3: Share profile without a native dependency

**Closes gap:** no share-profile affordance, and dating decisions are social.

**Verified constraint (Review Focus 7):** `share_plus` carries Android/iOS platform code. `scripts/patch.ps1` refuses native diffs, which means shipping it can only happen as a full release — never as a patch. `url_launcher: ^6.3.3` is already a dependency and is already used at `app_release_provider.dart:206-208`. So the implementation uses `url_launcher` plus the framework's `Clipboard`, and adds **no new package at all**.

**Files:**
- Create: `lib/shared/sharing/profile_share_text.dart`
- Modify: `lib/features/profile/profile_screen.dart` (overflow menu, next to the existing "See how others see you" action at `:265`)
- Create: `test/shared/sharing/profile_share_text_test.dart`

**Interfaces:**
- Produces `String buildProfileShareText({required String displayName, required int? age, required String? city})` — pure, localization-ready
- Produces `Future<bool> copyProfileSummary({required String text})` — wraps `Clipboard.setData`, returns success
- Consumes `formatDisplayLabel` (`lib/shared/formatting/display_text.dart:1`)

- [ ] **Step 1: Write the failing test** — includes display name; includes age when present and omits the segment when null; uses `formatDisplayLabel` for city; never emits a trailing separator for a missing city; handles an empty name with the existing `formatDisplayLabel` fallback rather than producing a blank line.

- [ ] **Step 2: Confirm they fail.** Expected: FAIL, function undefined.

- [ ] **Step 3: Implement the pure text builder.** Keep it free of `BuildContext` so it is testable and so it survives Task 8's localization extraction cleanly.

- [ ] **Step 4: Build the action as copy-first, not a share sheet.** A `showModalBottomSheet` with two rows: "Copy profile summary" (always works, `Clipboard`) and "Share via email or SMS" (`url_launcher` with `mailto:` / `sms:` and a pre-filled body). This avoids both the native dependency and a dead-end on platforms where no share target exists.

- [ ] **Step 5: Wire it into the profile overflow menu** at `profile_screen.dart:265`, matching the existing `AppOverflowMenuButton` pattern (`lib/shared/widgets/app_overflow_menu_button.dart:27`).

- [ ] **Step 6: Run tests and analyzer.** `flutter pub get` is **not** required — no dependency was added.

- [ ] **Step 7: Commit.**

  ```bash
  git add lib/shared/sharing/profile_share_text.dart lib/features/profile/profile_screen.dart test/shared/sharing/profile_share_text_test.dart
  git commit -m "feat(profile): add copy-and-share profile summary without new dependencies"
  ```

---

### Task 4: Verified-only preference, stored honestly

**Closes gap:** there is no way to express a verification preference. **This task deliberately does not filter anyone**, and that is the correct outcome.

**Verified facts that force this shape:**
- `BrowseCandidate` carries no verification flag (E13), so a client-side filter over the browse deck cannot be written — the field does not exist.
- Verification is only known for `UserDetail` (E14) and the viewer's own snapshot. Getting it for each candidate would mean an N+1 request per card, which the thin-client rule forbids and which would be a performance disaster.
- The preference cannot round-trip through the profile endpoint either, because `ProfileEditEditable` has no read path for it (E17).

So: store the preference locally so it is ready, and put server-side filtering in the backend contract. Building a filter now would be fabricating data, which `AGENTS.md` explicitly forbids.

**Files:**
- Modify: `lib/models/app_preferences.dart:23-56`
- Modify: `lib/features/settings/app_preferences_provider.dart:34-49`
- Test: `test/models/app_preferences_test.dart` (**exists**, E28) and `test/features/settings/app_preferences_provider_test.dart` (**exists**)

**Interfaces:**
- Produces `AppPreferences({..., bool verifiedOnly = false})` with the field added to ctor, `fromJson`, `toJson`, `copyWith`, `==`, `hashCode`
- Produces `AppThemeModePreference`-parallel `enum AppVerifiedOnlyPreference { any, verifiedOnly }` — mirroring the existing `AppThemeModePreference` shape at `app_preferences.dart:3-21`, including a `fromStorageValue`
- Produces `Future<void> AppPreferencesController.setVerifiedOnlyPreference(...)`
- Consumes `AppPreferencesStore` (`app_preferences_provider.dart:8-11`)

- [ ] **Step 1: Write the failing tests** — default is `any`; round-trips through `toJson`/`fromJson`; survives `copyWith`; `==`/`hashCode` distinguish the two values; the store persists it.

- [ ] **Step 2: Confirm they fail.** Expected: FAIL, no such field.

- [ ] **Step 3: Implement** following `AppThemeModePreference` exactly (`:3-21`) so the storage convention is identical. Do not add `verifiedOnly` to `ProfileUpdateRequest` — E16/E17 mean it would be a write-only field, and unknown JSON in the profile PUT risks a backend 4xx.

- [ ] **Step 4: Add the control to Discovery Preferences** as a disabled-by-default toggle with honest copy: `Show me verified profiles only — available once the server supports it.` The control must be visibly non-functional rather than silently doing nothing. Do not describe it as filtering anything today.

- [ ] **Step 5: Run tests and analyzer.** Expected: PASS / clean.

- [ ] **Step 6: Commit.**

  ```bash
  git add lib/models/app_preferences.dart lib/features/settings/app_preferences_provider.dart lib/features/browse/discovery_preferences_screen.dart test/models/app_preferences_test.dart test/features/settings/app_preferences_provider_test.dart
  git commit -m "feat(browse): store verified-only preference pending backend support"
  ```

---

## Phase C — Accessibility

**Scope correction that matters:** the first draft claimed blind users "cannot operate discovery, matches, or chat" because there are only two `Semantics()` calls in the app. That is wrong and would have caused a wasteful rewrite. In reality, icon-only actions across all major screens are already labelled through `tooltip:` (E19) — Flutter exposes a tooltip to the accessibility tree automatically. The real gaps are narrower and are listed below.

### Task 5: Screen-reader semantics for composite content

**Closes gap:** labels exist for *actions* but not for *content*. Whole cards, bubbles, and photo tiles are read as a stream of disconnected fragments or not at all.

**Files:**
- Create: `lib/shared/semantics/app_semantics.dart`
- Modify: `lib/features/browse/browse_screen.dart:774-787`
- Modify: `lib/features/matches/matches_screen.dart` (match cards)
- Modify: `lib/features/chat/conversations_screen.dart` (rows, unread counts)
- Modify: `lib/features/chat/conversation_thread_screen.dart` (bubbles, composer)
- Create: `test/shared/semantics/app_semantics_test.dart` — *label-construction tests on the pure helpers only*

**Interfaces:**
- Produces `AppSemantics.swipeCardLabel({required String name, required int age, required String? city})`
- Produces `AppSemantics.matchCardLabel({required String name, required int age, required String? lastMessage, required int unreadCount})`
- Produces `AppSemantics.messageBubbleLabel({required String senderName, required String content, required String timeLabel, required bool isMine, required bool failed})`
- Produces `AppSemantics.photoTileLabel({required String name, required int index, required int total, required bool isPrimary})`
- Produces `AppSemantics.unreadRowLabel({required String name, required int count})`

- [ ] **Step 1: Write the failing tests** on the pure helpers — non-empty output, includes name and age, includes "unread" only when count > 0, includes "failed to send" only when failed, includes "primary photo" only for the first tile.

- [ ] **Step 2: Confirm they fail.** Expected: FAIL, file missing.

- [ ] **Step 3: Create the shared helpers.** Centralize label construction so screens stay declarative and the wording is reviewable in one file. Follow the existing `presence_widgets.dart:111` pattern.

- [ ] **Step 4: Label the swipe card — the highest-value single fix.** The `Dismissible` at `browse_screen.dart:774-787` has no semantics, so a screen-reader user gets no hint that the card can be swiped at all (E21). Wrap `_CandidateCard` in `Semantics(label: AppSemantics.swipeCardLabel(...), customSemanticsAction: ...)` and keep the existing Like/Pass cues at `:764`, `:769` as the action labels. The visible action buttons already carry tooltips (E19) — do not re-label those.

- [ ] **Step 5: Label composite content.** Match cards, conversation rows (with unread counts), message bubbles, and photo tiles. Each becomes one readable node rather than a pile of text.

- [ ] **Step 6: Keep tooltips as the action pattern.** Do not add `Semantics` to buttons that already have `tooltip` (E19). Adding a duplicate `Semantics` label to a tooltipped `IconButton` is a no-op at best and a double-announcement at worst.

- [ ] **Step 7: Give photo reordering a non-drag route (Review Focus 5).** `_ReorderablePhotoTile` (`:1858-1908`) is reachable only by long-press-drag (E12). Add explicit "Make primary" (already exists at `:1470-1478`) and "Move left"/"Move right" buttons to `_PhotoTile` (`:1910`), so ordering is possible without any drag gesture. Keep drag as the fast path; just stop it being the *only* path.

- [ ] **Step 8: Announce async state.** `AppAsyncState` is a const `StatelessWidget` (E22), so converting it to stateful would break every const call site. Instead add a small stateful `AsyncAnnouncer` wrapper in `app_async_state.dart` that calls `SemanticsService.announce` on a state change, and wrap the loading/error usages. Do not touch the const constructors.

- [ ] **Step 9: Run tests and analyzer.** Expected: PASS / clean.

- [ ] **Step 10: Verify manually — this cannot be skipped.** Enable TalkBack (Android) or VoiceOver (iOS) and walk: Discover (swipe card announces name/age, actions discoverable), Matches (card reads as one node), Chats (row reads unread count), Chat (bubble reads sender/time), Profile (reorder via buttons). Semantics tests prove a label is constructed, not that anything is announced.

- [ ] **Step 11: Commit.**

  ```bash
  git add lib/shared/semantics/app_semantics.dart lib/features/browse/browse_screen.dart lib/features/matches/matches_screen.dart lib/features/chat/conversations_screen.dart lib/features/chat/conversation_thread_screen.dart lib/features/profile/profile_edit_screen.dart lib/shared/widgets/app_async_state.dart test/shared/semantics/app_semantics_test.dart
  git commit -m "feat(a11y): label composite content and add non-drag photo reordering"
  ```

---

### Task 6: Text scaling and layout resilience

**Closes gap:** untested at large text sizes; fixed-height rows overflow.

**Verified starting point:** `_SettingsLinkTile` already uses `ConstrainedBox(minHeight: 56)` (`settings_screen.dart:882`) and `AppAsyncState` uses `SingleChildScrollView` (`app_async_state.dart:74`), so the pattern to copy exists. The risk is concentrated in the composer and the card grids.

**Files:**
- Modify: `lib/features/chat/conversation_thread_screen.dart:365-391` (composer)
- Modify: `lib/features/matches/matches_screen.dart` (cards)
- Create: `test/shared/scaling_contract_test.dart`

- [ ] **Step 1: Write the failing tests.** Pump the composer and a match card at `textScaler` 1.0, 1.5, and 2.0 with a deliberately long German string and assert zero overflow. Prefer `textScaler` over the deprecated `textScaleFactor`. **(Review Focus 6)**

- [ ] **Step 2: Confirm they fail.** Expected: FAIL with `RenderFlex` overflow.

- [ ] **Step 3: Fix the layouts.** Replace fixed heights with `minHeight`, allow labels to wrap, keep `AppTheme` spacing. Where a row must stay single-line, ellipsize rather than clip.

- [ ] **Step 4: Run tests and analyzer.** Expected: PASS / clean.

- [ ] **Step 5: Commit.**

  ```bash
  git add lib/features/chat/conversation_thread_screen.dart lib/features/matches/matches_screen.dart test/shared/scaling_contract_test.dart
  git commit -m "fix(layout): survive 200% text scaling without overflow"
  ```

---

## Phase D — Localization (largest task; run last)

### Task 7: Localization foundation

**Closes gap:** zero localization plumbing (E25) — no `flutter_localizations`, no `intl`, no `l10n.yaml`, no `generate:` flag.

**Files:**
- Modify: `pubspec.yaml` (dependencies, `generate: true`)
- Create: `l10n.yaml`
- Create: `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`
- Create: `test/l10n/localization_coverage_test.dart`

**Interfaces:**
- Produces `AppLocalizations` (generated) with `AppLocalizations.localizationsDelegates` and `AppLocalizations.supportedLocales`
- Produces `LocalePreference` + `AppPreferencesController.setLocalePreference(...)` — extends Task 4's work in `app_preferences.dart`, **not** a parallel mechanism

- [ ] **Step 1: Add dependencies** — `flutter pub add flutter_localizations --sdk=flutter` and `flutter pub add intl:any`. Set `generate: true` under `flutter:` in `pubspec.yaml`. Note this adds no *native* code, so it does not block patching (Review Focus 7 does not apply).

- [ ] **Step 2: Create `l10n.yaml`** — `arb-dir: lib/l10n`, `template-arb-file: app_en.arb`, `output-localization-file: app_localizations.dart`, `output-class: AppLocalizations`, `synthetic-package: false`, `nullable-getter: false`.

- [ ] **Step 3: Seed `app_en.arb` with high-traffic keys** so the generator produces a working class before mass extraction: `appTitle`, `navDiscover`, `navMatches`, `navChats`, `navProfile`, `navSettings`, `actionSend`, `actionCancel`, `actionRetry`, `errorGeneric`.

- [ ] **Step 4: Generate and wire** — `flutter gen-l10n`. In `lib/app/app.dart` add `localizationsDelegates`, `supportedLocales`, and `locale:` from the preference provider. Add the locale picker to `settings_screen.dart` next to the existing theme-mode control (which is the pattern to copy, `settings_screen.dart:199`).

- [ ] **Step 5: Write the failing coverage test** — every key in `app_en.arb` has a non-empty `app_de.arb` counterpart, and `AppLocalizations.of(context)` resolves under `Locale('de')`.

- [ ] **Step 6: Verify** — `flutter analyze` clean and the coverage test passes once Step 7 runs.

- [ ] **Step 7: Commit.**

  ```bash
  git add pubspec.yaml pubspec.lock l10n.yaml lib/l10n lib/app/app.dart lib/models/app_preferences.dart lib/features/settings/app_preferences_provider.dart lib/features/settings/settings_screen.dart test/l10n
  git commit -m "feat(i18n): add localization foundation with English and German"
  ```

---

### Task 8: Extract all user-facing strings to ARB

**Closes the rest of the localization gap.** Mechanical but large, and deliberately sequenced after Tasks 1-6 because those tasks edit the same files.

**Files:** every file under `lib/features/**` and `lib/shared/**` containing user-facing copy.

**Interfaces:**
- Consumes `AppLocalizations` from Task 7.

- [ ] **Step 1: Inventory** — `grep -rn "Text('" lib/ --include=*.dart` and `grep -rn "label: '" lib/ --include=*.dart` plus `tooltip:` and `hintText:`. Produce a per-file list before editing.

- [ ] **Step 2: Exclude backend contract values — this is the thin-client rule.** Do **not** localize enum values verbatim from the backend: `lib/models/gender_options.dart`, `pace_preferences.dart`, `lifestyle_options.dart`, `report_reason.dart`, and any `switch` on backend keys such as `ProfileCompletionInfo.fieldOrder` (`profile_completion_info.dart:16-25`). Route them through `formatDisplayLabel` (`display_text.dart:1`) instead, which already handles canonicalization.

- [ ] **Step 3: Extract in batches, one feature directory per commit**, in this order: `auth` → `browse` → `matches` → `chat` → `profile` → `notifications` → `settings` → `safety` → `stats` → `verification` → `onboarding` → `location` → `shared`. For each batch: add keys to `app_en.arb`, extract German to `app_de.arb`, run `flutter gen-l10n`, then `flutter analyze`.

- [ ] **Step 4: Handle interpolation explicitly.** Strings with values become ARB parameters, e.g. `"unreadCount": "{count, plural, =1{1 unread message} other{{count} unread messages}}"`. Use plurals for counts rather than string concatenation — several existing strings already interpolate a name, e.g. `pending_likers_screen.dart:610` `'More actions for ${liker.name}'`, `matches_screen.dart:616` `'Message ${match.otherUserName}'`, `conversation_thread_screen.dart:380` `'Message ${widget.conversation.otherUserName}'`.

- [ ] **Step 5: Re-run the coverage test after each batch.** Expected: PASS at every commit.

- [ ] **Step 6: Final sweep** — `flutter analyze`, then `flutter test test/models test/features test/api test/shared test/l10n`. Expect failures in existing tests that assert on the old hardcoded English copy (E29); repair those expectations to the localized strings. That is repair, not new tests.

- [ ] **Step 7: Commit per batch**, e.g. `git commit -m "refactor(i18n): extract chat feature strings to ARB"`.

---

## Phase E — Backend contract handoff (no Flutter code)

### Task 9: Write the backend contract handoff

**Closes gaps:** chat media, delivery state, reactions, quote-reply, profile prompts, voice intros, server-side verified filtering, and the BE P0-5 ordering defect.

Per the user's decision this is a **document**, not Java code — the backend is a separate repo.

**Files:**
- Create: `docs/specs/backend-feature-contract-2026-10.md`

**Interfaces:**
- Consumes `lib/api/api_endpoints.dart` as the current surface of record (133 lines; the complete endpoint list).
- Produces a document the Java team can implement from without reading Dart.

Write each section with: the endpoint, method, request shape, response shape, the Flutter field it maps to, and the thin-client statement.

- [ ] **Step 1: BE P0-5 message ordering — do this first, it is a live bug.** `GET /api/conversations/{id}/messages` must gain `order=asc|desc` (default `asc` for compatibility) plus `totalCount`, so the client can fetch the newest page. Note that today's oldest-first behaviour (E1) is what forces the client to walk forward, and that Task 1 is only a mitigation.

- [ ] **Step 2: Message media.** `POST /api/conversations/{id}/messages` accepts `multipart/form-data` with an optional `photo` part alongside `content`. Response `MessageDto` gains `attachments: [{id, url, width, height, contentType}]`. Point at `uploadPhoto` (`api_client.dart:958-976`) as the multipart pattern to mirror, and note that messages then need the same auth-header image path (E: `AppNetworkImage`).

- [ ] **Step 3: Delivery state.** `MessageDto` gains `status` and `deliveredAt`/`readAt`. State explicitly that the existing `MessageLocalState` (`message_dto.dart:1`) is client-only and must not be conflated with server state — the two are different axes.

- [ ] **Step 4: Reactions.** `PUT`/`DELETE /api/conversations/{id}/messages/{messageId}/reaction` with an emoji key; message payload gains `reactions: [{emoji, count, reactedByMe}]`.

- [ ] **Step 5: Quote-reply.** `sendMessage` gains optional `replyToMessageId`; payload gains `replyTo: {id, senderId, excerpt}`.

- [ ] **Step 6: Profile prompts.** `ProfileEditSnapshot.editable` gains `prompts: [{id, promptText, answerText}]`, with either a prompt catalogue endpoint or the catalogue embedded in the snapshot. Both profile view and profile edit render it. Flag this as a product decision, not just a technical one.

- [ ] **Step 7: Voice intros.** Optional `voiceIntroUrl` + duration on user detail, uploaded via the same multipart path as photos.

- [ ] **Step 8: Friend requests.** `GET /api/users/{id}/friend-requests`, `POST /api/users/{id}/friend-requests/{targetId}`, `DELETE` to decline. Cite E26: the notification registry already registers `FRIEND_REQUEST` and `FRIEND_REQUEST_ACCEPTED` (`notification_item.dart:119-126`, `notification_preferences.dart:113-114`, handled at `notifications_screen.dart:1210-1215`) but no endpoint exists, so those notification types can never be acted on.

- [ ] **Step 9: Server-side verified filtering.** `browse` gains `verifiedOnly`, and `BrowseCandidate` gains a `verified` field. Reference Task 4 — the client-side filter is impossible precisely because of E13, and the read path is impossible because of E17.

- [ ] **Step 10: State the thin-client boundary per item.** For every section: the Flutter client renders exactly what the backend returns and will not synthesize, infer, or default any of it.

- [ ] **Step 11: Commit.**

  ```bash
  git add docs/specs/backend-feature-contract-2026-10.md
  git commit -m "docs: specify backend contracts for chat media, delivery state, reactions, prompts and friend requests"
  ```

---

## Phase F — Optional product work

### Task 10: Photo guidance and first-match copy

**Closes gap:** "Add photo" appears with no advice, and the first match gets the same dialog as every other match.

**Verified facts:** `SectionIntroCard` is not dismissible (E23), so dismissal must be added or a different pattern used. `MatchCelebrationDialog` has no match-count or `isMatch` param (E24) — the first draft referenced one that does not exist. The current user's total match count is not obviously available to the client either, so this needs a decision rather than an assumption.

**Files:**
- Modify: `lib/features/profile/profile_edit_screen.dart:1626-1635`
- Modify: `lib/shared/widgets/section_intro_card.dart`
- Test: none — copy-only. Do not add a widget test (testing policy).

- [ ] **Step 1: Add photo guidance** below the photo section using `SectionIntroCard` with three short lines: show your face clearly, use a recent photo, one activity per photo. Persist dismissal through `AppPreferences` (Task 4/7 mechanism), adding an `onDismiss` affordance to `SectionIntroCard` rather than a bespoke widget.

- [ ] **Step 2: Decide the first-match question before writing copy.** The client cannot tell "first ever match" from "tenth match" without a count from the backend. Either add match count to the contract in Task 9, or scope the copy to something the client *does* know — that this is a mutual match — and leave "first match" out. Do not fabricate the distinction.

- [ ] **Step 3: Verify** — `flutter analyze` clean; confirm via the screenshot workflow.

- [ ] **Step 4: Commit.**

  ```bash
  git add lib/features/profile/profile_edit_screen.dart lib/shared/widgets/section_intro_card.dart
  git commit -m "feat(profile): add photo guidance copy"
  ```

---

## Dependency Order

```text
Task 1  (chat pagination)     ─┐
Task 2  (photo slots)         │
Task 3  (profile share)       ├─ independent, can run in parallel
Task 4  (verified-only pref)  │
Task 9  (handoff doc)         ─┘

Task 5  (semantics)  ── needs 1,2 done (edits the same files)
Task 6  (scaling)   ── needs 5 done
Task 7  (l10n base) ── needs 1-6 done (touches every file)
Task 8  (l10n mass) ── needs 7 done
Task 10 (photo copy)── needs 2 done
```

Tasks 1-4 and 9 are unblocked now. Task 5 onward should wait for the feature work to land, since both touch the same files and doing them out of order guarantees conflicts.

---

## Test Impact Map

Which existing suites a task can break. Repair expectations; do not delete coverage.

| Task | Existing suites at risk |
| --- | --- |
| 1 | `test/features/chat/conversation_thread_provider_test.dart`, `test/features/chat/conversation_thread_screen_test.dart`, `test/features/chat/conversations_provider_test.dart` |
| 2 | `test/features/profile/photo_edit_provider_test.dart`, `test/features/profile/profile_edit_screen_test.dart`, `test/models/photo_dto_test.dart` |
| 3 | `test/features/profile/profile_screen_test.dart`, `test/models/user_summary_test.dart` |
| 4 | `test/models/app_preferences_test.dart`, `test/features/settings/app_preferences_provider_test.dart`, `test/models/discovery_preferences_test.dart`, `test/features/browse/discovery_preferences_screen_test.dart` |
| 5 | `test/features/browse/browse_screen_test.dart`, `test/features/matches/matches_screen_test.dart`, `test/features/chat/conversations_screen_test.dart` |
| 6 | `test/features/chat/conversation_thread_screen_test.dart`, `test/features/matches/matches_screen_test.dart` |
| 7 | `test/app/app_test.dart`, `test/features/settings/settings_screen_test.dart` |
| 8 | Essentially every screen test — string assertions will fail en masse |
| 10 | `test/features/profile/profile_edit_screen_test.dart`, `test/shared/widgets/section_intro_card_test.dart` |

---

## Risk Register

| Risk | Likelihood | Mitigation |
| --- | --- | --- |
| Pagination duplicates or drops a message when a poll lands mid-`loadMore` | Medium | Deduplicate by `id`/`localId` after every merge; re-sort with the existing comparator (E3); explicit test (Review Focus 1) |
| `useSparseLayout` flips mid-pagination and scroll position resets | High | Freeze the predicate on initial load size (Review Focus 3) |
| Notice copy stays wrong after the refactor | Medium | Single source of truth for `hasMore`; three explicit copy strings (Review Focus 4) |
| Extraction breaks hundreds of string assertions at once | High | Per-directory commits so a failure is bisectable; coverage test runs every batch |
| `verifiedOnly` added to the profile PUT causes a backend 4xx | Low | Do not add it to `ProfileUpdateRequest`; device-local only (E16, E17) |
| A new native dependency silently blocks patching | Low | No new package added; `url_launcher` reused (Review Focus 7) |
| Accessibility "fix" double-announces tooltipped buttons | Medium | Only label composite content; leave `tooltip` actions alone (E19) |
| Fabricating a photo cap of 6 | Eliminated | Constant derived from the UI's own slot model, not invented (E9, E10) |

---

## Explicitly Not In This Plan

- **Any Java backend code.** Separate repo. Task 9 specifies the contract only.
- **Chat media, reactions, quote-reply, delivery ticks, prompts, voice intros, friend-request UI.** All blocked on Task 9. Building them now would mean fabricating contracts.
- **Client-side verified filtering.** Impossible without E13/E17 landing. Task 4 stores the preference and stops.
- **A photo cap of 6.** Not supported by any evidence (E9).
- **Push notifications / FCM.** No Firebase in `pubspec.yaml` or Gradle config, by design.
- **WebSockets.** Not present, by design.
- **New widget or screenshot tests.** Governed by `AGENTS.md`. Existing broken tests are repaired only.
- **Publishing a release or patch.** Both `scripts/release.ps1` and `scripts/patch.ps1` need explicit per-invocation OK.

---

## Verification Commands

Run after every task:

```powershell
flutter analyze
flutter test <the task's own tests>
```

`flutter analyze` must report `No issues found!`. Judge UI from screenshots, not widget assertions. Never claim end-to-end verification without exercising the real path.
