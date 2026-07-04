# Plan 02 — Photo Upload UX (feedback + dismissal)

**Status:** ✅ COMPLETE — implemented and `flutter analyze` clean on 2026-07-05

Read `00-overview.md` first. Rules there apply.

## Why

Current behavior (audited):

- A successful upload's progress tile silently disappears (`_buildUploadTiles()` in `lib/features/profile/profile_edit_screen.dart` skips `succeeded` uploads) — the user gets no "it worked" signal.
- A **rejected** upload (moderation) sets state + reason in `PhotoUploadNotifier` (`lib/features/profile/photo_upload_provider.dart`, rejection handling around lines 106-120, inference at 168-184) but the tile lingers with no way to clear it.
- The rejection reason renders with `maxLines: 2` and can be cut off.

## Files you will touch

- `lib/features/profile/upload_state.dart`
- `lib/features/profile/photo_upload_provider.dart`
- `lib/features/profile/profile_edit_screen.dart` (only the `_PhotoEditSection` region)

## Task 0 — Read first (mandatory)

Read ALL of `upload_state.dart` and `photo_upload_provider.dart`, and the `_PhotoEditSection` + `_buildUploadTiles` region of `profile_edit_screen.dart`, before editing. The exact names below (state class shape, id field, status enum values) must be adapted to what you find — the *behavior* specified here is what's fixed, not the identifier spellings. Statuses referenced below: `preparing`, `uploading`, `succeeded`, `failed`, `rejected` (confirm actual enum names).

## Task 1 — `dismiss` on the upload notifier

In `photo_upload_provider.dart`, add a method to `PhotoUploadNotifier`:

```dart
/// Removes a finished (succeeded/failed/rejected) upload entry from view.
void dismissUpload(String uploadId) { ... }
```

Behavior:
- Remove the entry whose id equals `uploadId` from the notifier state collection (state is likely a list or map of upload entries — mirror the existing state-update style used by the other mutation methods in the same class: copy, modify, assign).
- If the entry is currently `preparing`/`uploading`, do nothing (never cancel an in-flight upload here).

## Task 2 — Success + rejection snackbars

In `profile_edit_screen.dart`, inside `_PhotoEditSection` (it is — verify — a `ConsumerWidget` or `ConsumerStatefulWidget`; if it's a plain Consumer widget without a place for `ref.listen`, do the listen in its `build` via `ref.listen(...)`, which is valid in build for both):

```dart
ref.listen(photoUploadProvider, (previous, next) { ... });
```

(Adapt the provider name to the actual one exported by `photo_upload_provider.dart`.)

Behavior — compare `previous` and `next` upload entries by id; for every entry whose status **transitioned** (previous status ≠ next status):

- → `succeeded`: `ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo added.')));`
- → `rejected`: snackbar with `Text(reason.isNotEmpty ? 'Photo rejected: $reason' : 'Photo rejected by moderation.')` where `reason` is the entry's rejection-reason field (trimmed).
- → `failed`: **no snackbar** (the tile already shows a retry affordance — don't double-report).

Guard: only fire for real transitions, not on every rebuild. If entries lack stable ids to diff on, diff on (id, status) pairs.

## Task 3 — Dismiss affordance on finished tiles

In `_buildUploadTiles()` (or the tile widget it delegates to):

1. **Failed tiles**: keep the existing Retry affordance; ADD a secondary dismiss — a small `IconButton` with `Icons.close_rounded`, `tooltip: 'Dismiss'`, calling the Task 1 `dismissUpload(entry.id)` via `ref.read(...notifier).`. Visual: `visualDensity: VisualDensity.compact`, icon size 16, `onSurfaceVariant` color.
2. **Rejected tiles**: same dismiss button. Also change the rejection-reason `Text` from `maxLines: 2` to `maxLines: 4` and wrap the reason `Text` in a `Tooltip(message: fullReason, child: ...)` so long reasons are recoverable.
3. **Succeeded tiles**: keep the current behavior (skipped from the tile list) — the snackbar from Task 2 is the success signal. Do NOT start rendering succeeded tiles.

## Task 4 — Rejected photos in the grid

Verify (read the code — `photo_upload_provider.dart` lines ~106-132): after a rejection the notifier invalidates `userPhotosProvider` etc. If the backend keeps a rejected photo in the photo list with a moderation status on `PhotoDto` (check `lib/models/photo_dto.dart` for a status/moderation field):

- If `PhotoDto` **has** a moderation/status field: in the photo grid tile of `_PhotoEditSection`, overlay a small bottom-aligned pill reading `'Rejected'` (error container colors: background `colorScheme.errorContainer`, text `onErrorContainer`, `AppTheme.chipRadius`) when that status equals the rejected value, and `'In review'` (`surfaceContainerHighest` / `onSurfaceVariant`) for a pending value if one exists. The existing delete action on grid tiles already lets users remove them.
- If `PhotoDto` has **no** such field: skip this task entirely and note it as a backend gap in your report. Do not fabricate a status.

## Acceptance criteria

- `flutter analyze` → no issues.
- Uploading a photo that succeeds ⇒ exactly one "Photo added." snackbar; tile disappears (unchanged behavior).
- Rejected/failed tiles each have a working ✕ dismiss that removes the tile immediately.
- No snackbar storms: transitions only, one per entry per transition.
- No behavior change to the upload/replace/reorder/delete flows themselves.
