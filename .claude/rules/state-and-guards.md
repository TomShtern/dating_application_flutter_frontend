---
paths:
  - "lib/features/**"
  - "lib/shared/providers/**"
  - "lib/app/**"
---

## Riverpod patterns

| Pattern | Use for |
|---|---|
| `FutureProvider` | async API-backed reads (browse, matches, messages) |
| `NotifierProvider` | mutable state with methods (preferences) |
| `Provider` | DI and sync derived values (ApiClient, SharedPreferences) |

Each feature folder holds `*_provider.dart` (providers) and `*_screen.dart`
(`ConsumerWidget` / `ConsumerStatefulWidget`). Controllers are plain classes
returned by a `Provider`.

Keep side effects (API calls, `ref.invalidate`) in providers and controllers.
Screens only read and watch. Keep widgets mostly declarative.

## Selected-user guard

`lib/shared/providers/selected_user_guard.dart` exposes three guards — pick by
call site. All three throw a typed error when no user is selected. Never bypass
or re-implement the check.

| Guard | Use in |
|---|---|
| `watchSelectedUser(ref)` | a `FutureProvider` body |
| `requireSelectedUser(ref)` | notifier / controller methods |
| `requireActionableTargetUser(ref, targetId)` | actions targeting another user |

## Profile edit — snapshot/request split

Read via `ApiClient.getProfileEditSnapshot()` → `ProfileEditSnapshot` (read-only
and editable fields together). Write only changed fields via
`ProfileUpdateRequest` (partial update).

## Photo edit

- Mutations go through `PhotoEditController`
  (`lib/features/profile/photo_edit_provider.dart`) via
  `ref.read(photoEditControllerProvider)` — action-only, not reactive state.
- **Primary photo = index 0.** There is no "set primary" endpoint;
  `setPrimary(id)` reorders so the target is first. Don't add one client-side.
- After any mutation the controller invalidates four providers —
  `userPhotosProvider`, `profileProvider`, `profileEditSnapshotProvider`,
  `otherUserProfileProvider` — so every photo-aware view stays in sync. Add new
  photo-consuming providers to that list rather than re-fetching ad hoc.
- Uploads take an `XFile` from `image_picker`; the controller falls back to
  in-memory bytes when the path is unreadable, so callers need not pre-read.

Preserve the selected dev user between launches.
