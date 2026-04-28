Target file: lib/features/chat/conversations_screen.dart

Design reference: docs/design-language.md (browse/social archetype, ShellHero
usage, AppTheme tokens, semantic colour tokens)

You are a Flutter frontend engineer. Your task is to visually refine the
ConversationsScreen at `lib/features/chat/conversations_screen.dart`. Do
not change providers, controllers, models, API calls, or navigation
logic. Keep `_openConversation`, the `Navigator.push` to
`ConversationThreadScreen`, the `conversationsControllerProvider`
contract, and the underlying `ConversationSummary` model untouched.

Constraints (read first):
- Browse/social archetype: a `ShellHero` is the visual anchor and lives
  OUTSIDE the scroll. Layout MUST be
  `Column → ShellHero → Expanded → RefreshIndicator → ListView`.
- This is a tab screen rendered inside `SignedInShell` — there must be
  no `Scaffold(appBar: AppBar(...))` wrapper. The `Scaffold` and AppBar
  are removed entirely; the parent shell already supplies the
  surrounding chrome.
- Use `AppTheme` tokens (`cardRadius`, `panelRadius`, `chipRadius`,
  `pagePadding`, `cardPadding`, `cardGap`, `sectionGap`,
  `screenPadding`, `listSpacing`, `surfaceDecoration`, `softShadow`,
  `accentGradient`, `matchAccent`, `matchTextPrimary`,
  `matchTextSecondary`, `matchTextTertiary`).
- Do NOT invent helper names. If a token is not defined in
  `lib/theme/app_theme.dart`, leave the existing literal — verify by
  reading the theme file before editing.
- The dev-mode preview helper `_conversationPreview` is intentionally
  a placeholder until the backend exposes real last-message previews —
  keep its function signature but improve its copy (Change 4).

---

# Change 1 — Drop the `Scaffold` + `AppBar` wrapper

Today the screen wraps its body in `Scaffold(appBar: AppBar(title:
Text('Conversations'), actions: [refresh])`. Inside `SignedInShell`,
this produces a second AppBar competing with the tab chrome.

Replace the outer `Scaffold` with a plain `SafeArea` (top: false) so the
shell owns the system insets:

```dart
return SafeArea(
  top: false,
  child: Column(
    children: [
      ShellHero(...),                  // Change 2
      Expanded(child: ...),            // Change 3
    ],
  ),
);
```

The refresh action moves into `ShellHero.trailing` (Change 2), so the
AppBar is fully redundant.

---

# Change 2 — Add a `ShellHero` as the screen anchor

Insert a `ShellHero` as the first child of the new `Column`:

```dart
ShellHero(
  eyebrowLabel: 'Messages',
  title: 'Chats',
  subtitle: switch (conversationsState) {
    AsyncData(:final value) when value.isEmpty =>
      'Start a conversation when you match.',
    AsyncData(:final value) =>
      '${value.length} ongoing ${value.length == 1 ? 'chat' : 'chats'}',
    _ => 'Your conversations',
  },
  trailing: IconButton(
    tooltip: 'Refresh conversations',
    onPressed: () =>
        ref.read(conversationsControllerProvider).refresh(),
    icon: const Icon(Icons.refresh_rounded),
  ),
),
```

If `ShellHero` does not expose `eyebrowLabel`/`subtitle`/`trailing`
under those exact names, read `lib/shared/widgets/shell_hero.dart` and
adapt to its real API — but the visual result must match: an eyebrow
label above a bold title, a state-aware subtitle, and a trailing
refresh affordance.

The subtitle must reflect the live count, not be a static blurb.

---

# Change 3 — List structure: hero outside, RefreshIndicator inside

Restructure the body so the list scrolls under a stationary hero:

```dart
Expanded(
  child: RefreshIndicator(
    onRefresh: () =>
        ref.read(conversationsControllerProvider).refresh(),
    child: conversationsState.when(
      data: (conversations) {
        if (conversations.isEmpty) {
          return AppAsyncState.empty(
            message:
                'No conversations yet — once you match and message someone, they\'ll show up here.',
            onRefresh: () =>
                ref.read(conversationsControllerProvider).refresh(),
          );
        }
        return ListView.separated(
          padding: AppTheme.screenPadding(),
          itemCount: conversations.length,
          separatorBuilder: (_, __) =>
              SizedBox(height: AppTheme.listSpacing()),
          itemBuilder: (context, index) => _ConversationCard(
            currentUser: currentUser,
            summary: conversations[index],
          ),
        );
      },
      loading: () => const AppAsyncState.loading(
        message: 'Loading conversations…',
      ),
      error: (error, stackTrace) => AppAsyncState.error(
        message: error is ApiError
            ? error.message
            : 'Unable to load conversations right now.',
        onRetry: () => ref.invalidate(conversationsProvider),
      ),
    ),
  ),
),
```

Important details:
- `RefreshIndicator` wraps the `when` so loading/error/empty states are
  pull-to-refreshable.
- The `ListView` carries `AppTheme.screenPadding()` itself — drop the
  outer `Padding(AppTheme.screenPadding)` that wraps the whole `Column`
  in the existing code.
- The empty state must use `AppAsyncState.empty` with `onRefresh` so
  pull-to-refresh works on an empty list.

---

# Change 4 — `_ConversationCard`: remove the redundant footer

Today every card renders a footer row that says "Tap anywhere to open"
on the left and a `FilledButton.icon('Open chat')` on the right. Both
trigger `_openConversation`, which is also what the card-wide `InkWell`
does. Three tap targets for one action is noise.

Delete the entire footer `Row` (the one starting with `Text('Tap
anywhere to open', …)` and ending with the `FilledButton.icon`).
Replace it with a single trailing chevron tucked into the metadata row
so the card still signals tappability without competing CTAs:

In the metadata row (currently `[mail icon] [messageSummary]`), append
a trailing chevron:

```dart
Row(
  children: [
    Icon(Icons.mail_outline_rounded, size: 18,
         color: colorScheme.onSurfaceVariant),
    const SizedBox(width: 8),
    Expanded(
      child: Text(
        messageSummary,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
      ),
    ),
    Icon(
      Icons.chevron_right_rounded,
      size: 20,
      color: colorScheme.onSurfaceVariant,
    ),
  ],
),
```

Also delete the `SizedBox(height: 12)` that previously separated the
metadata row from the now-removed footer.

The card padding stays at `EdgeInsets.all(AppTheme.cardPadding)` —
**replace the literal `EdgeInsets.all(16)`** with the token.

---

# Change 5 — `_ConversationCard`: tighten the preview / count typography

The card body currently renders, in this order:

1. Name (titleLarge)  +  date (labelLarge muted)
2. `_conversationPreview` text (titleMedium w600)
3. `messageSummary` row (bodyMedium muted)

Two issues:

a) The preview text uses `titleMedium` weight 600, which optically
   competes with the name. Until the backend exposes real last-message
   previews, the placeholder copy should read like a SUBTITLE, not a
   second headline. Change to:

   ```dart
   Text(
     preview,
     maxLines: 2,
     overflow: TextOverflow.ellipsis,
     style: Theme.of(context).textTheme.bodyMedium?.copyWith(
       color: colorScheme.onSurface,
       fontWeight: FontWeight.w500,
     ),
   ),
   ```

b) Soften the placeholder copy so it doesn't pretend to be a real
   message excerpt. Update `_conversationPreview` to:

   ```dart
   String _conversationPreview(ConversationSummary summary) {
     return switch (summary.messageCount) {
       0 => 'No messages yet — say hi when you\'re ready.',
       1 => 'One message so far. Pick the chat back up.',
       2 || 3 || 4 => 'A few messages exchanged — keep it going.',
       _ => 'An ongoing conversation.',
     };
   }
   ```

   Same intent, less "marketing copy" tone, no false claim of an
   "active conversation waiting for your next reply" when we don't
   know that.

c) Bump the `SizedBox(height: 10)` between the name row and the
   preview to `SizedBox(height: 6)` — with the lighter preview weight,
   the larger gap reads as a section break instead of a continuation.

The `messageSummary` switch (`'New match, ready for the first message'`,
`'1 message so far'`, etc.) is fine — leave it.

---

# Change 6 — Avatar + name row alignment

The `UserAvatar(name: summary.otherUserName, radius: 28)` sits at
`CrossAxisAlignment.start` against a multi-line text column, which
pushes the avatar to the very top while the name baseline is one line
down. Switch the outer Row's `crossAxisAlignment` to
`CrossAxisAlignment.center` so the avatar centres against the name
row visually.

Verify the avatar size is consistent with other surfaces — the matches
card uses 96px hero avatars; conversations should use 56px (radius 28)
which is already correct. Do NOT change `radius`.

If `UserAvatar` accepts a parameter for a thin accent ring (read
`lib/shared/widgets/user_avatar.dart` to confirm the actual parameter
name — do NOT invent one), pass it with `AppTheme.accentGradient(context)`
to subtly tie the conversation list to the matches card visual
language. If the widget exposes no such parameter, leave the avatar
plain — do not wrap it in an extra ring container.

---

# Change 7 — Card surface decoration: drop the inline gradient

The card currently passes a manual `LinearGradient(colors:
[surface, surfaceContainerLow])` into `surfaceDecoration`. The default
`surfaceDecoration(context)` already provides the screen's neutral
surface — the explicit gradient creates a sheen that competes with the
preview text on light mode.

Replace with the bare helper call:

```dart
DecoratedBox(
  decoration: AppTheme.surfaceDecoration(context),
  ...
)
```

If `surfaceDecoration` requires an explicit `gradient:` argument
(verify in `lib/theme/app_theme.dart`), pass `null` or leave the
existing one — but ONLY if the helper has no zero-arg form.

---

# Acceptance checklist

- The screen no longer wraps its body in `Scaffold` or `AppBar`. The
  refresh action lives in `ShellHero.trailing`.
- Layout is `SafeArea(top: false) → Column → ShellHero → Expanded →
  RefreshIndicator → ListView/empty/error/loading`.
- `ShellHero` subtitle pluralises against the live conversation count.
- The "Tap anywhere to open" caption AND the "Open chat" `FilledButton`
  in the card footer are deleted. A single chevron in the metadata row
  signals tappability.
- `EdgeInsets.all(16)` on the card body is replaced with
  `EdgeInsets.all(AppTheme.cardPadding)`.
- `_conversationPreview` copy is softened (no more "active conversation
  waiting for your next reply"), and the preview text style is
  `bodyMedium w500`, not `titleMedium w600`.
- The avatar/name row uses `CrossAxisAlignment.center`.
- The card uses bare `AppTheme.surfaceDecoration(context)` with no
  inline manual gradient (unless the helper signature requires one).
- Empty list state uses `AppAsyncState.empty` with `onRefresh` and the
  refreshed copy.
- `flutter analyze` is clean.
- A visual review run produces a `shell_chats__run-XXXX…png` whose
  hierarchy reads: ShellHero with refresh → list of conversation cards,
  each with a 56px avatar, name + short date, two-line preview, mail
  icon + count + trailing chevron — no extra footer button.
