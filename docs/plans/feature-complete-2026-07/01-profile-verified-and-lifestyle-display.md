# Plan 01 — Verified Badge & Lifestyle Display on Profiles

Read `00-overview.md` first. Rules there apply.

## Why

Verification status (`verified`, `verificationMethod`, `verifiedAt`) is parsed in `ProfileEditReadOnly` (`lib/models/profile_edit_snapshot.dart:223-250`) but the ONLY place a user ever sees it is a small pill on the edit screen header. The own-profile and other-user profile screens never show it. Likewise, the lifestyle fields users can now edit (smoking, drinking, kids, looking for, education, interests) are never displayed back on the own profile screen, so editing them feels pointless.

## Files you will touch

- `lib/models/user_detail.dart`
- `lib/features/profile/profile_screen.dart`
- `lib/features/profile/profile_edit_screen.dart`
- `lib/models/profile_edit_snapshot.dart`

Key existing anchors in `lib/features/profile/profile_screen.dart` (line numbers approximate — locate by class name):

- `_ProfileContent` (~line 253) — renders, in order: hero card, presentation context, details card, photos. Line ~312: `_ProfileDetailsCard(detail: detail, isCurrentUser: isCurrentUser),`
- `_ProfileHeroCard` (~line 429) — takes `detail` (a `UserDetail`) + `isCurrentUser`; contains a `Wrap` (~line 505) of `_ProfileMetaPill` widgets (state pill, location pill, distance pill).
- `_ProfileMetaPill` (~line 740) — `{required IconData icon, required String label, required Color color}`.
- `_ProfileSection` (~line 1116) — generic titled section container used by the details/photo sections.
- File-level color constants near the top: `_profileSky`, `_profileViolet`, `_profileMint` (and possibly others — reuse, don't add new hues).

---

## Task 1 — `UserDetail.verified` (optional field)

In `lib/models/user_detail.dart`:

1. Add `final bool verified;` and constructor param `this.verified = false` (NOT required — keeps all existing constructions compiling).
2. In `fromJson`, add: `verified: json['verified'] as bool? ?? false,`
3. Add `other.verified == verified` to `operator ==` and add `verified` to the `Object.hash(...)` list.

Rationale (do not change): if the backend user-detail DTO doesn't include `verified`, this stays `false` and no badge renders — safe either way. Do not invent any other fields.

## Task 2 — Verified pill on the profile hero

In `lib/features/profile/profile_screen.dart`:

1. `_ProfileHeroCard` — add a parameter: `final bool showVerifiedBadge;` with constructor param `this.showVerifiedBadge = false`.
2. Inside its `Wrap` of meta pills, insert **as the first child**:
   ```dart
   if (showVerifiedBadge)
     _ProfileMetaPill(
       icon: Icons.verified_rounded,
       label: 'Verified',
       color: _profileMint,
     ),
   ```
3. The existing state pill currently uses `Icons.verified_user_outlined` (~line 510) which would be visually confusable with the new badge. Change that state pill's icon to `Icons.shield_outlined`. Change nothing else about it.
4. Wire the value at the `_ProfileHeroCard(...)` call site(s) inside `_ProfileContent`:
   - `_ProfileContent` is currently a `StatelessWidget`. Change it to `ConsumerWidget` (add `WidgetRef ref` to `build`). Import is already `flutter_riverpod` in this file (verify; add if missing).
   - Compute:
     ```dart
     final snapshotVerified = isCurrentUser
         ? (ref.watch(profileEditSnapshotProvider).value?.readOnly.verified ??
               false)
         : false;
     final showVerifiedBadge = snapshotVerified || detail.verified;
     ```
     `profileEditSnapshotProvider` comes from `profile_provider.dart`, already imported by this file (verify).
   - Pass `showVerifiedBadge: showVerifiedBadge` to `_ProfileHeroCard`.

   Decision (final): for the current user the truth source is the edit snapshot (it definitely carries `verified`); for other users it is `detail.verified` (renders only if the backend sends it). Do not fetch the edit snapshot for other users — it is a self-only endpoint.

## Task 3 — Lifestyle section on the OWN profile

Still in `profile_screen.dart`. Other users' `UserDetail` does not carry lifestyle fields (backend gap — skip for them). For the current user, source them from the edit snapshot.

1. Create a new private widget at file scope:

   ```dart
   class _LifestyleSection extends ConsumerWidget {
     const _LifestyleSection();

     @override
     Widget build(BuildContext context, WidgetRef ref) {
       final editable = ref.watch(profileEditSnapshotProvider).value?.editable;
       if (editable == null) {
         return const SizedBox.shrink();
       }

       final facts = <(IconData, String, String)>[
         if (editable.smoking != null)
           (Icons.smoking_rooms_outlined, 'Smoking', formatDisplayLabel(editable.smoking!)),
         if (editable.drinking != null)
           (Icons.local_bar_outlined, 'Drinking', formatDisplayLabel(editable.drinking!)),
         if (editable.wantsKids != null)
           (Icons.child_care_outlined, 'Kids', formatDisplayLabel(editable.wantsKids!)),
         if (editable.lookingFor != null)
           (Icons.favorite_border_rounded, 'Looking for', formatDisplayLabel(editable.lookingFor!)),
         if (editable.education != null)
           (Icons.school_outlined, 'Education', formatDisplayLabel(editable.education!)),
         if (editable.heightCm != null && editable.heightCm! > 0)
           (Icons.height_rounded, 'Height', '${editable.heightCm} cm'),
       ];

       if (facts.isEmpty && editable.interests.isEmpty) {
         return const SizedBox.shrink();
       }
       // ... render below
     }
   }
   ```

   `formatDisplayLabel` is from `../../shared/formatting/display_text.dart` — already imported in this file (verify).

2. Render: wrap in the same section chrome the file already uses. **Look at how `_ProfileDetailsCard` composes `_ProfileSection` / its card decoration and mirror it exactly** (same `DecoratedBox`/`AppTheme.surfaceDecoration` pattern, same paddings). Content:
   - Section title: `'Lifestyle'` (match how existing section titles are styled in `_ProfileDetailsCard`).
   - Each fact: a `Row` of icon (16–18px, `_profileSky` color) + label in `bodySmall`/`onSurfaceVariant` + value in `bodyMedium` w600. Reuse `_ProfileFactTile` (~line 909) **if its constructor fits an (icon, label, value) shape** — inspect it first; if it fits, use it instead of a hand-rolled row.
   - Interests: below the facts, if `editable.interests.isNotEmpty`, a `Wrap(spacing: 8, runSpacing: 8)` of small chips. Use the existing `HighlightTagRow` shared widget (`lib/shared/widgets/highlight_tag_row.dart`) if it accepts a plain `List<String>` — inspect it; otherwise plain `Chip`-free `DecoratedBox` chips matching the app's chip pattern (`AppTheme.chipRadius`, tinted background `.withValues(alpha: 0.10)`, `labelMedium` text).
3. Insert into `_ProfileContent`'s children **immediately after** the `_ProfileDetailsCard(...)` entry, gated:
   ```dart
   if (isCurrentUser) ...[
     SizedBox(height: AppTheme.listSpacing()),
     const _LifestyleSection(),
   ],
   ```
   Match the exact spacing widget the neighboring entries use (if they use something other than `AppTheme.listSpacing()`, copy that instead).

## Task 4 — Verified detail line on the edit screen header

In `lib/features/profile/profile_edit_screen.dart`, `_ProfileEditHeader` (~line 850+, locate by name) already shows a verified pill sourced from `snapshot.readOnly`. Add, when `snapshot.readOnly.verified` is true and `snapshot.readOnly.verifiedAt != null`, a small caption under the existing header row:

```dart
Text(
  'Verified via ${formatDisplayLabel(snapshot.readOnly.verificationMethod ?? 'unknown')} · ${formatShortDate(snapshot.readOnly.verifiedAt!)}',
  style: theme.textTheme.bodySmall?.copyWith(
    color: colorScheme.onSurfaceVariant,
  ),
),
```

`formatShortDate` is in `../../shared/formatting/date_formatting.dart` — add the import if the file doesn't have it. Fit this into `_ProfileEditHeader`'s existing Column; place it directly after whatever row/widget renders the verified pill, preceded by `const SizedBox(height: 4)`.

## Task 5 — Delete the dead `toUpdateRequest()`

`ProfileEditSnapshot.toUpdateRequest()` (`lib/models/profile_edit_snapshot.dart:32-45`) is not called from `lib/` and is now out of sync with the edit form (it omits the lifestyle fields). Decision (final): **delete the method** and the now-possibly-unused `import 'profile_update_request.dart';` if the analyzer flags it.

Before deleting, run:
```
rg -n "toUpdateRequest" --glob "*.dart"
```
If any file under `test/` references it, remove those specific usages/assertions minimally (this is the one permitted test edit — see overview rule 8). If a file under `lib/` references it, STOP — report instead of deleting.

## Acceptance criteria

- `flutter analyze` → no issues.
- `UserDetail` compiles with `verified` defaulting to false; equality/hash updated.
- Own profile shows: Verified pill (only when snapshot says verified) + Lifestyle section (only rows with data; whole section hidden when empty).
- Other-user profile shows Verified pill only if the API returns `verified: true` in user detail.
- No new colors introduced; only existing `_profile*` constants used.
