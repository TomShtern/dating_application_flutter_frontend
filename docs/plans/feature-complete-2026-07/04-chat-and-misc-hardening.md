# Plan 04 — Chat & Misc Hardening

**Status:** ✅ COMPLETE — implemented and `flutter analyze` clean on 2026-07-05

Read `00-overview.md` first. Rules there apply. These are small, independent tasks; if one gets stuck, revert it and move on.

## Task 1 — Local message id collision fix

**File:** `lib/models/message_dto.dart` (the `MessageDto.localSending` factory — locate it; it currently derives `localId` from `microsecondsSinceEpoch` + content `hashCode`, which can collide when the same text is sent twice quickly).

Replace the id derivation with a monotonic sequence:

```dart
class MessageDto {
  // ...
  static int _localSequence = 0;
```

and inside `localSending`:

```dart
final localId =
    'local-${DateTime.now().microsecondsSinceEpoch}-${_localSequence++}';
```

Keep every other field of the factory exactly as-is. Do not change `copyWith`, merge logic, or `conversation_thread_provider.dart` — they key off `localId` equality and remain correct.

## Task 2 — Standouts view-mode survives navigation

**Files:** `lib/features/browse/standouts_provider.dart`, `lib/features/browse/standouts_screen.dart`.

The grid/list `ViewModeToggle` state currently lives in the screen's local `State`, so it resets every time the user re-enters the screen.

1. In `standouts_provider.dart` add:
   ```dart
   /// Session-scoped standouts view mode (true = grid). Intentionally not
   /// persisted to disk — a session-level preference is enough here.
   final standoutsGridViewProvider = StateProvider<bool>((ref) => false);
   ```
   **Set the default to whatever the screen's current initial value is** — open `standouts_screen.dart`, find the local boolean/enum backing the `ViewModeToggle`, and mirror its initial value (if the screen uses an enum for view mode, keep a `bool` provider anyway and map at the call site: grid == true).
2. In `standouts_screen.dart`, delete the local state field; read `ref.watch(standoutsGridViewProvider)` where it was used, and in the toggle's callback do `ref.read(standoutsGridViewProvider.notifier).state = <newValue>;` instead of `setState`. If removing the last local state lets the screen become a plain `ConsumerWidget`, you MAY simplify — but only if the change stays mechanical; otherwise leave it a stateful widget.

## Task 3 — Conversations search result count

**File:** `lib/features/chat/conversations_screen.dart`.

Find the search filtering region (there is an existing "No chats match" empty-state string near line ~129 — the filter logic is adjacent). When the search query is non-empty AND the filtered list is non-empty, render one line above the results list:

```dart
Text(
  filtered.length == 1 ? '1 chat found' : '${filtered.length} chats found',
  style: theme.textTheme.bodySmall?.copyWith(
    color: colorScheme.onSurfaceVariant,
    fontWeight: FontWeight.w600,
  ),
)
```

Placement: as the first child of whatever scrollable/Column renders the filtered conversation tiles, with the file's standard small gap below it (reuse a neighboring `SizedBox` value). Adapt `filtered` to the actual variable name. No count line when the query is empty.

## Task 4 — Pass-candidate snackbar consistency (tiny)

**File:** `lib/api/api_client.dart`, method `passUser` — it parses the message with a raw inline cast (`payload['message'] as String? ?? 'Passed'`) unlike every sibling that uses `_extractMessage`. Replace the two lines:

```dart
final payload = _expectMap(response.data, context: 'passing a candidate');
return payload['message'] as String? ?? 'Passed';
```

with:

```dart
return _extractMessage(response.data, fallback: 'Passed');
```

(Read `_extractMessage` first to confirm the signature — it exists and is used by `blockUser`/`unmatchUser` etc. If for some reason its behavior differs materially — e.g. it throws on non-map payloads where the old code didn't — keep the old code and note it.)

## Acceptance criteria

- `flutter analyze` → no issues after each task.
- Sending two identical messages back-to-back produces two distinct local bubbles (unique `localId`s by construction).
- Standouts: toggle to grid, navigate back, re-open → still grid (within the same app session).
- Conversations search shows an accurate count line only while searching.
