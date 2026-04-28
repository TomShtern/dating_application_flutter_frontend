Target file: lib/features/profile/profile_screen.dart

Design reference: docs/design-language.md (browse/social archetype for the
current-user tab variant; pushed-detail archetype for the other-user
variant; AppTheme tokens; semantic colour tokens; ShellHero usage)

You are a Flutter frontend engineer. Your task is to visually refine the
ProfileScreen at `lib/features/profile/profile_screen.dart`. Do not
change providers, controllers, models, API calls, navigation, or the
two-constructor split (`ProfileScreen.currentUser` vs
`ProfileScreen.otherUser`). Keep `_displayName`, `_headline`, `_bio`,
`_aboutTitle`, `_heroSummary`, `_profileReadiness`, `_gender`,
`_interestedIn`, `_approximateLocation`, `_distancePreference`, and
`_state` exactly as written.

Constraints (read first):
- The screen is BOTH a bottom-nav tab (current user) AND a pushed detail
  (other user). Treat the two variants distinctly:
  - **`_isCurrentUser == true`** → browse/social archetype: no `AppBar`,
    `ShellHero` is the anchor, body is a single scroll surface.
  - **`_isCurrentUser == false`** → pushed-detail archetype: keep an
    `AppBar` (for the back affordance and `SafetyActionsButton`), but
    drop its title text — the `_ProfileHeroCard` is the visual anchor.
- Use `AppTheme` tokens (`cardRadius`, `panelRadius`, `chipRadius`,
  `pagePadding`, `cardPadding`, `cardGap`, `sectionGap`,
  `screenPadding`, `sectionPadding`, `sectionSpacing`, `listSpacing`,
  `surfaceDecoration`, `softShadow`, `accentGradient`).
- Never inline a hex literal where an `AppTheme` semantic token already
  exists. If a token is not defined in `lib/theme/app_theme.dart`,
  leave the existing literal — do NOT invent a token name.
- Do NOT touch the `UserAvatarPhoto` or `_PhotoPlaceholder` widgets
  beyond what is explicitly called out — image loading is fragile.

---

# Change 1 — Variant-aware Scaffold chrome

Today both variants render the same `Scaffold(appBar: AppBar(title:
Text(title), actions: [...]))`. For the current-user tab, this duplicates
the `_ProfileHeroCard` "Your profile" eyebrow and creates a second AppBar
inside `SignedInShell`.

Restructure the build:

```dart
if (_isCurrentUser) {
  return SafeArea(
    top: false,
    child: profileState.when(
      data: (detail) => _CurrentUserBody(...),
      loading: () => const AppAsyncState.loading(message: 'Loading profile…'),
      error: ... // unchanged
    ),
  );
}

return Scaffold(
  appBar: AppBar(
    title: const SizedBox.shrink(),
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    actions: [
      SafetyActionsButton(...),       // unchanged
      IconButton(                       // refresh, unchanged behaviour
        tooltip: 'Refresh profile',
        onPressed: () => controller.refreshOtherUserProfile(userId!),
        icon: const Icon(Icons.refresh_rounded),
      ),
    ],
  ),
  body: SafeArea(child: ...),
);
```

The other-user AppBar still has actions (`SafetyActionsButton`,
refresh) — only the title is dropped.

---

# Change 2 — Current-user variant: ShellHero + scroll restructure

For the `_isCurrentUser == true` branch, replace the existing
`Padding(AppTheme.screenPadding) → SingleChildScrollView →
_ProfileContent` shape with:

```dart
Column(
  children: [
    ShellHero(
      eyebrowLabel: 'Your profile',
      title: _headline(detail),
      subtitle: readinessLabel,                  // see below
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Edit profile',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ProfileEditScreen(),
              ),
            ),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Refresh profile',
            onPressed: controller.refreshCurrentUserProfile,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    ),
    Expanded(
      child: SingleChildScrollView(
        padding: AppTheme.screenPadding(),
        child: _ProfileContent(
          detail: detail,
          isCurrentUser: true,
          // ... existing args
        ),
      ),
    ),
  ],
),
```

`readinessLabel` is `_profileReadiness(detail).label` — the same string
that is currently rendered below the linear progress bar inside
`_ProfileHeroCard`. With the readiness summary in the hero subtitle, the
hero card's "Profile ready · 4 of 4" trailing text becomes redundant —
keep ONLY the progress bar in the card (delete the trailing
`Text(readiness.label, …)` line; see Change 3).

Once the current-user variant has a `ShellHero` summarising who they
are (name + readiness), the `_ProfileHeroCard` no longer needs the
"Your profile" eyebrow. See Change 3.

---

# Change 3 — `_ProfileHeroCard`: declutter the duplicate eyebrow / readiness

For the current-user variant, the new `ShellHero` already shows "Your
profile" + name + readiness in the subtitle. Inside `_ProfileHeroCard`:

a) Remove the eyebrow `Text(isCurrentUser ? 'Your profile' : 'Profile
   snapshot', …)` line entirely. The `_headline` Text becomes the
   first child of the right-hand column.

b) Replace the headline `headlineSmall` with `titleLarge` so it does
   not compete with the new ShellHero title above the card.

c) When `isCurrentUser == true`, keep the `LinearProgressIndicator` but
   delete the `Text(readiness.label, …)` line below it — the label
   now lives in the ShellHero subtitle.

d) Replace the literal `EdgeInsets.all(18)` … wait, the card already
   uses `AppTheme.sectionPadding()`. Leave that.

e) The trailing `_ProfileMetaPill`s (Active / Tel Aviv / 50 km) stay,
   but bump the `Wrap.spacing` to use `AppTheme.cardGap` if it is
   exposed numerically; otherwise leave the existing `8`.

For the OTHER-user variant, keep the eyebrow as `'Profile snapshot'` —
that variant has no ShellHero, so the in-card eyebrow is useful.

---

# Change 4 — `_ProfileCompletenessCard`: collapse redundant pills when complete

The complete-state branch renders two pills `'4 essentials complete'`
+ `'Ready for discovery'` directly below body copy that already says
"All of the essentials are in place. Refresh it whenever you want to
keep things feeling current." This is a triple-statement of the same
fact (body + pill 1 + pill 2).

Collapse the complete-state body to:

```dart
if (isComplete) ...[
  // No pills row — the body copy already says "all essentials are in place".
] else ...[
  ClipRRect(...),                    // existing progress bar
  SizedBox(height: AppTheme.sectionSpacing()),
  ...checklist.entries.map(...),     // existing checklist tiles
],
SizedBox(height: AppTheme.cardGap),
Wrap(
  spacing: AppTheme.cardGap,
  runSpacing: AppTheme.cardGap,
  children: [
    FilledButton.tonalIcon(
      onPressed: onEditProfile,
      icon: const Icon(Icons.edit_outlined),
      label: const Text('Review details'),
    ),
    if (missingLocation)
      FilledButton.tonalIcon(
        onPressed: onFixLocation,
        icon: const Icon(Icons.location_on_outlined),
        label: const Text('Fix location'),
      ),
  ],
),
```

Replace the literal `EdgeInsets.all(18)` on the outer Padding with
`EdgeInsets.all(AppTheme.cardPadding)`. Replace the literal
`SizedBox(height: 8)` immediately above the Wrap with the
`AppTheme.cardGap` SizedBox shown above.

The card title "Profile ready" / "Profile completeness" stays as
`titleLarge`. The leading icon chip's `BorderRadius.circular(16)` and
inner `EdgeInsets.all(10)` stay.

---

# Change 5 — `_PresentationContextCard`: tokenise paddings

This card uses `EdgeInsets.all(18)` outer padding, an icon container
with `BorderRadius.circular(16)` + `EdgeInsets.all(10)`, and several
`SizedBox(height: 12)` spacers between sections.

Replace:
- Outer `EdgeInsets.all(18)` → `EdgeInsets.all(AppTheme.cardPadding)`.
- The two `SizedBox(height: 12)` between header → summary → tags →
  details → each detail line stay as `12` only if `cardGap` is not 12
  in the project; otherwise switch them to `SizedBox(height:
  AppTheme.cardGap)`. Read the actual `cardGap` numeric value in
  `app_theme.dart` before deciding.
- Detail-line icon: change `Icon(Icons.check_circle_outline, size: 16)`
  to use `colorScheme.primary` so the row aligns visually with the
  header icon.

The `HighlightTagRow` call is correct — leave it. The summary `Text`
needs no style override.

---

# Change 6 — `_PhotoSection`: tokenise paddings, no header chrome change

The photos card has `EdgeInsets.all(18)` outer padding and a
`SizedBox(height: 16)` between the header row and the horizontal photo
list.

Replace:
- Outer padding → `EdgeInsets.all(AppTheme.cardPadding)`.
- Header→list spacer → `SizedBox(height: AppTheme.cardGap)`.

The horizontal photo list itself stays at `height: 126` with
`UserAvatarPhoto(height: 126, width: 156)` and
`BorderRadius.circular(18)` clip — those numbers are tuned to the photo
aspect ratio and do not need tokenisation.

---

# Change 7 — `_ProfileSection` (About card): align typography with sibling cards

The About card uses a `ListTile` inside a `Card`, which produces a
slightly different vertical rhythm and leading-icon size than the
sibling section cards (`_PresentationContextCard`,
`_PhotoSection`, `_ProfileDetailsCard`).

Convert `_ProfileSection`'s body from `Card → ListTile` to
`Card → Padding → Row(icon chip + Column(title, value))` so it visually
matches its siblings:

```dart
Card(
  child: Padding(
    padding: const EdgeInsets.all(AppTheme.cardPadding),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.all(Radius.circular(16)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: colorScheme.primary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    ),
  ),
)
```

Drop the wrapping `Padding(EdgeInsets.only(bottom: AppTheme.listSpacing()))`
around the Card — section spacing is already handled by the parent
`_ProfileContent` Column via its `AppTheme.sectionSpacing()` SizedBoxes.

---

# Change 8 — `_ProfileDetailsCard`: token-align inner Wrap

The fact tiles `Wrap(spacing: 10, runSpacing: 10)` is fine, but the
section title→subtitle→Wrap spacers (`SizedBox(height: 4)` and
`AppTheme.sectionSpacing(compact: true)`) are mixed.

Verify both spacers AFTER the title/subtitle pair use the same token
rhythm. Change the `SizedBox(height: 4)` between title and subtitle to
`SizedBox(height: AppTheme.cardGap / 2)` ONLY if a half-gap helper
exists; otherwise leave the literal `4`.

The `_ProfileFactTile` constraints `minWidth: 142, maxWidth: 168` and
inner `EdgeInsets.all(12)` stay — they are tuned to fit two tiles per
row at 412dp width.

---

# Change 9 — Empty-state copy: photos and bio

The bio empty fallback is `'No bio added yet.'` and the photos empty
fallback is `'No photos added yet.'`. For the current-user variant,
soften these to suggest action without nagging:

```dart
String _bio(UserDetail detail, {required bool isCurrentUser}) {
  final bio = detail.bio.trim();
  if (bio.isEmpty) {
    return isCurrentUser
        ? 'Add a short bio so people get a feel for you.'
        : 'No bio shared yet.';
  }
  return bio;
}
```

Update the `_bio` callers to pass `isCurrentUser`. Apply the same
treatment to the `'No photos added yet.'` fallback inside `_PhotoSection`
— but that requires threading `isCurrentUser` through. If that change
balloons the diff, keep the photos fallback as-is.

For the OTHER-user variant, both fallbacks read the same as today.

---

# Acceptance checklist

- Current-user variant has NO `AppBar` and uses a `ShellHero` whose
  trailing slot holds the edit + refresh icons. Body is `Column →
  ShellHero → Expanded → SingleChildScrollView`.
- Other-user variant keeps its `AppBar` (with `SafetyActionsButton` +
  refresh) but the AppBar title is `SizedBox.shrink()` — the
  `_ProfileHeroCard` is the anchor.
- Inside `_ProfileHeroCard`, the `Text('Your profile', …)` eyebrow is
  removed for the current-user variant, the headline drops to
  `titleLarge`, and the readiness label below the progress bar is
  removed (it now lives in the ShellHero subtitle).
- `_ProfileCompletenessCard` complete-state no longer renders the two
  redundant `_ProfileMetaPill`s. Outer padding is
  `EdgeInsets.all(AppTheme.cardPadding)`.
- `_PresentationContextCard` outer padding is
  `EdgeInsets.all(AppTheme.cardPadding)`. The detail-line check icon
  uses `colorScheme.primary`.
- `_PhotoSection` outer padding is `EdgeInsets.all(AppTheme.cardPadding)`
  and the header→list gap is `AppTheme.cardGap`.
- `_ProfileSection` (About) is converted from `ListTile`-in-`Card` to
  `Padding → Row(icon chip + title/value column)` so it visually
  matches `_PresentationContextCard` and `_PhotoSection`.
- `_bio` returns "Add a short bio so people get a feel for you." for
  the current user when bio is empty; the OTHER user variant still
  reads "No bio shared yet.".
- `flutter analyze` is clean.
- A visual review run produces a `shell_profile__run-XXXX…png` whose
  hierarchy reads: ShellHero with edit + refresh → hero card with
  avatar + headline + meta pills + (current user) progress bar →
  About card → completeness card with progress and CTAs (no redundant
  pills) → details card → photos card.
