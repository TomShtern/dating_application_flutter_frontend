# UI Complaints — Plain Language Edition

Status: third pass. Companion to:

- [`design-critique-run-0119.md`](./design-critique-run-0119.md) — visual /
  UI / UX critique with per-screen detail.
- [`2026-04-29-product-completeness-gaps.md`](./2026-04-29-product-completeness-gaps.md) — high-level
  systems and infrastructure missing from the product.

This file contains things **not in either of those docs**. It is the
"how the app *feels*" pass, written in two voices side by side:

- The **UI term** — for designers / engineers.
- The **plain-language** translation — for everyone else.

Format per item:

> **UI term**: short technical critique.
> *Plain*: same idea in normal-person words.

Read top to bottom. The complaints get more abstract as you scroll —
concrete-pixel issues first, mood and feel issues last.

---

## 1. Card City

> **Uniform card chrome on every surface**: every screen is a vertical
> stack of rounded-rectangle cards with the same radius, padding, and
> shadow. There is almost no edge-to-edge content, no full-bleed media,
> no asymmetric layout.
> *Plain*: every piece of information lives in its own little floating
> box. The whole app looks like a page of business cards. There is
> nothing big, nothing wide, nothing breaking out of the grid.

> **No z-axis hierarchy**: cards all sit at the same elevation, with the
> same drop-shadow weight.
> *Plain*: nothing on the page looks more important than anything else.
> Imagine a desk where every item is the same size — you don't know
> what to pick up first.

> **Card-in-card nesting**: secondary content (like "Why this profile
> is shown") gets its own card *inside* a parent card, doubling up
> chrome.
> *Plain*: there are boxes inside boxes. You can see the edge of the
> inner box and the edge of the outer box, and your brain has to
> decide which one matters.

> **Radius is the same everywhere**: same ~16-20 px corner radius on
> every card, button, pill, image holder.
> *Plain*: every corner of every shape is rounded the same amount. So
> a tiny chip looks like a baby version of a big card. There is no
> playfulness in the geometry.

---

## 2. Faceless People

> **Avatar fallback dominance**: nearly every user is rendered as a
> coloured-gradient circle with a monogram letter. There are no real
> photos in the captured run.
> *Plain*: this is a dating app and almost no one has a face. You see
> coloured blobs with a single letter — "N", "M", "L". You cannot
> imagine going on a date with a letter.

> **Big photo placeholder dominates Discover**: the primary candidate
> card on Discover gives more than half its height to the photo
> fallback rectangle.
> *Plain*: when someone hasn't uploaded a photo, the empty space
> *grows* to fill the slot they would have filled. The absence is
> louder than the presence.

> **Story-ring avatar styling**: the avatar circles have a
> multi-coloured ring around them — visually similar to Instagram
> Stories.
> *Plain*: the rings around the people-circles look borrowed from
> Instagram. It is a known visual that means "tap to see story" on
> Instagram, and it doesn't mean that here. Confusing.

---

## 3. Sameness Between Screens

> **Inter-tab visual collision**: Matches and Chats list-card layouts
> are nearly isomorphic — same avatar treatment, same body line, same
> chevron, same card chrome.
> *Plain*: if you opened the app at random, you couldn't tell whether
> you were on the Matches screen or the Chats screen until you read
> the title. They look like the same screen with different words.

> **Three primary tabs share a hero hue**: Discover, Matches, Profile
> all open with rose-tinted hero cards.
> *Plain*: tap-tap-tap through the bottom nav and three of the five
> tabs greet you with the same shade of pink. The app feels small.

> **Bottom-nav bias**: the rose-tinted active state, plus the rose
> heroes, plus the rose status pills, biases the entire visual budget
> toward one colour.
> *Plain*: pink is the loudest voice in the room. Even when other
> colours show up, pink is everywhere.

---

## 4. No Personality / No Voice

> **No brand mark on any surface**: app name, logo, wordmark, mascot —
> none are visible on any captured screen.
> *Plain*: you cannot tell what this app is called from the app
> itself. Open the screenshots and try to name it — you can't.

> **Generic copy register**: hero titles are nouns ("Discover",
> "Matches", "Stats"). No taglines, no nicknames, no warmth in
> microcopy beyond bios.
> *Plain*: the words in the app are the same words a settings menu
> would use. The app does not speak to you like a friend.

> **No mascot, illustration, or signature graphic moment**: every
> drawn element is a Material icon in a coloured chip.
> *Plain*: there is no character, no drawing, no *thing* you would
> recognise as belonging only to this app. Nothing memorable.

> **Mood is uniform**: every screen — Discover, Chats, Settings,
> Stats — is the same emotional temperature.
> *Plain*: looking for love and changing the theme should not feel
> the same. Right now they feel the same.

---

## 5. Pacing & Density Whiplash

> **Sparse-vs-dense oscillation**: Discover shows one giant candidate
> card at a time; Stats stacks 8 dense tiles in the first viewport.
> *Plain*: some screens feel almost empty (you scroll and there is
> nothing). Others feel cramped (everything is tiny and demanding
> attention at once). It is not a steady rhythm.

> **No discovery-deck depth cue**: only one card is visible at a
> time on Discover, with no peek of the card behind, no progress
> indicator, no "1 of 5" tick.
> *Plain*: Discover looks like there is exactly one person to look
> at. You know there are five only because the header says so.

> **Hero size is constant**: every primary tab opens with a similarly
> sized hero card.
> *Plain*: every screen begins with a "title card" of about the same
> height. None of them earns special treatment. None of them tells
> you "this is the important one."

---

## 6. Pill Saturation

> **Status-pill density**: most cards stack 3-5 small coloured pills
> per row.
> *Plain*: tiny coloured tags everywhere. Each card has half a dozen
> badges. Your eye has to scan and decide which to read first.

> **Information layering reaches diminishing returns**: title + body
> line + 3 pills + chevron + overflow per row is too much for a list
> tile.
> *Plain*: each row in a list is doing too many jobs. Headline, sub-
> headline, three badges, a "tap me" arrow, and a "more options"
> button — for one person. Real apps trim this to one or two signals.

> **Same fact in three forms**: e.g. "12 messages exchanged in this
> conversation" + a pill saying "12 messages" + a number "12" in
> the timestamp area.
> *Plain*: the same information appears as a sentence, a label, and
> a number, all on the same card. Repetition without reinforcement.

---

## 7. Buttons That Don't Behave Like Buttons

> **Affordance ambiguity on tappable text**: "Unblock", "See full
> profile", "Mark all read" appear as plain text but function as
> primary actions.
> *Plain*: things you are supposed to tap look like ordinary words.
> You don't know they are buttons until you press them.

> **Asymmetric primary action sizing**: Pass and Like on Discover are
> different widths, weights, and visual treatments.
> *Plain*: the "no" button looks small and timid. The "yes" button
> looks big and bright. Saying no feels like a smaller, weaker
> action than saying yes — which subtly pressures you toward yes.

> **Gradient over-use on commits**: Save changes, Like, Send code,
> Use this location all use multi-stop gradient fills.
> *Plain*: too many buttons use the same fancy colour-fade effect.
> When everything is fancy, nothing is.

---

## 8. Generic Material Default Tells

> **Stock chevrons everywhere**: every navigable row ends in the same
> Material right-chevron.
> *Plain*: little arrows pointing right at the end of every row.
> Looks like a settings menu. Not like a love story.

> **Kebab `⋮` overflow menus**: every card uses the same vertical
> three-dots overflow.
> *Plain*: the "more" button is the same engineer-y three-dots icon
> on every card. It looks like a developer's checkbox of an icon
> rather than a designed thing.

> **Material chip / pill defaults peeking through**: subtle but
> visible — paddings, focus rings, pill heights echo the Material
> defaults.
> *Plain*: parts of the app feel like Google's default sample app,
> not a custom product.

---

## 9. The Bottom Nav Carries Too Much

> **5-label bottom navigation**: Discover, Matches, Chats, Profile,
> Settings — five icon-and-label pairs at the bottom.
> *Plain*: the bottom of every screen is permanently busy with five
> small icons and five small words. That's a lot of real estate
> spent on getting around.

> **Opaque unread indicator**: only one tab (Matches) carries a small
> dot. The dot's meaning is unstated.
> *Plain*: a tiny pink dot appears on the Matches icon. What does
> the dot mean? Why isn't there a dot on Chats too? You don't know.

> **Active-state pill behind icon**: the selected tab gets a rose-
> tinted pill behind its icon, lifting visual weight.
> *Plain*: the tab you're on glows pink. It is a bit shouty. You
> already know which tab you're on because you opened it.

---

## 10. Colour Without Mood Modulation

> **Always sunny in light mode**: every surface is a tinted pastel.
> No deep, no dark, no surprise contrast moment in light theme.
> *Plain*: it's always a bright sunny day inside this app. There is
> no night, no candlelight, no quiet moment. It is *cheerful all the
> time*.

> **No anchor surface**: there is no neutral surface that lets the
> colour breathe — every card is tinted, no card is plain.
> *Plain*: every wall in every room is painted. There is no white
> wall to rest your eyes on. After scrolling for a minute, your
> eyes get tired.

> **Saturated CTAs against soft backgrounds**: the Like button and
> the Save changes button are saturated rose against pale rose
> cards.
> *Plain*: the buttons are *very* loud and the things around them
> are *very* quiet. There's nothing in the middle.

---

## 11. The App Feels Static

> **No motion language**: no animation visible across the captures —
> no count-ups, no card-in transitions, no swipe-cue motion.
> *Plain*: nothing moves. The app is a series of still images. When
> you tap, you don't get a satisfying *response* — only the next
> still image.

> **No haptic / sound suggestions**: no on-screen cue that haptic
> feedback is wired up to like / match / unmatch.
> *Plain*: the app doesn't tap back at you when you tap it. There
> is no buzz on a match, no chime on a message, no pulse on a like.
> It feels silent.

> **No loading rhythm**: no skeletons, no shimmers, no progressive
> reveals.
> *Plain*: when content loads, you don't see *anything* loading.
> One moment empty, next moment full. No sense of motion.

---

## 12. The App Feels Staged, Not Lived-in

> **Round numbers**: 5 candidates, 5 standouts, 5 chats, 5 likes-you.
> Everything is fives.
> *Plain*: every count is exactly the same nice round number. Real
> apps have 1 of this, 47 of that. The roundness gives away that
> this is sample data.

> **Curated bios**: "Museum dates, espresso, and dry humor." / "Sunset
> swims and vinyl shopping." Bios sound like ad copy, not like real
> people.
> *Plain*: the bios are too perfectly written. Nobody actually writes
> "Sunset swims and vinyl shopping" about themselves. They write
> "idk lol" or "ask me about my dog."

> **Synthetic timestamps**: every chat aligns to neat 5-minute
> intervals — 1:30, 1:35, 1:40.
> *Plain*: the conversation looks like a robot wrote it. Real chats
> have replies at 1:33 and 2:07 and "yesterday."

> **Bios consistent length**: every bio is one short sentence.
> *Plain*: every person speaks in exactly the same length of
> sentence. Real people are wordy or terse or weird.

---

## 13. The First Impression

> **Cold open on dev sign-in**: the entry surface is a developer-
> picker card stack with a yellow developer-only callout.
> *Plain*: the very first thing a new user would see is a big yellow
> warning sticker that says "Developer only." That is not a welcome.

> **No onboarding moment**: no value-prop screen, no aspirational
> imagery, no "tell me about yourself" reveal.
> *Plain*: the app does not greet you. It does not introduce itself.
> It does not tell you why you should stay. It just dumps you into
> the picker.

> **No app-name anywhere**: no logo, no wordmark, no greeting.
> *Plain*: imagine downloading an app and using it for ten minutes
> without ever seeing the app's name. That's this app.

---

## 14. The Mood Is the Same on Every Screen

> **No emotional modulation across surfaces**: Discover (excitement),
> Chats (intimacy), Settings (calm), Stats (reward), Verification
> (trust) all use the same pastel palette and same hero structure.
> *Plain*: the place where you fall for someone and the place where
> you change your password should not feel the same. Right now they
> feel the same.

> **No surface earns a "wow" moment**: no centerpiece screen, no
> set-piece animation, no celebratory state.
> *Plain*: the app is consistently good at being calm. It is never
> spectacular. It does not sell a moment.

> **Dating-app excitement is missing**: a dating app should feel
> hopeful, optimistic, slightly nervous. This one feels organised.
> *Plain*: it feels like a CRM for romance. It does not feel like
> butterflies.

---

## 15. Navigation Feels Engineered, Not Designed

> **Identical entry pattern across tabs**: every tab opens with the
> same hero → filter → list rhythm.
> *Plain*: every screen starts the same way. Title at top, a couple
> of pills, a list below. Predictable to the point of monotony.

> **No "you are here" cue beyond tab tint**: aside from the active
> bottom-nav pill, there is no breadcrumb, no animation, no
> contextual back.
> *Plain*: when you go from Matches into a profile and then back, you
> don't *feel* the journey. The app forgets where you came from.

> **Pushed routes feel like islands**: secondary screens pop up
> without route chrome (already covered in the visual critique) and
> also without a sense of being *part of* a parent.
> *Plain*: when you open a sub-screen, it doesn't feel like opening a
> drawer in your kitchen — it feels like teleporting into a different
> kitchen.

---

## 16. Things That Look Wrong On Quick Glance

These are first-impression hits that don't fit the categories above.

> **Discover candidate photo plate**: looks like a corrupted JPEG
> rather than a "no photo yet" state.
> *Plain*: the place where you'd see a face is a muddy yellow-green
> blur. It looks broken, not empty.

> **Conversation thread header is tiny**: the person you're talking
> to has a 32 px avatar at the top.
> *Plain*: the human you're chatting with is shrunk to the size of a
> dime. Their profile picture is smaller than any of the message
> bubbles below it.

> **"Photo pending" floats over the photo plate**: it sits as a
> separate translucent layer above the gradient.
> *Plain*: a label saying "Photo pending" floats over the empty
> photo space. So now you have an empty photo *with* a label saying
> the photo is empty.

> **Profile-edit slider track has rose dots at every interval**:
> the track underneath the distance slider has a row of pink dots.
> *Plain*: the distance slider has a row of tiny pink polka dots
> running underneath it. It looks decorative for no reason.

> **Settings hero uses meta-info as content**: the hero shows the
> user's name, their profile state, *and* the active theme.
> *Plain*: the top of Settings tells you which theme you are using.
> But you can change the theme right below. So the top is showing you
> a fact you control on the same screen.

---

## 17. The Things You'd Miss If You Squinted

These are concerns about what *isn't* there visually.

> **No moment of "I want to use this app daily."**
> *Plain*: nothing on any screen makes you want to come back tomorrow.

> **No moment of "this is mine."**
> *Plain*: nothing on any screen feels personal to *you*. The Profile
> tab shows your name, but it doesn't feel like *your* corner of the
> app.

> **No moment of "this is fun."**
> *Plain*: nothing makes you smile. Nothing surprises you. Nothing
> rewards you for being there.

> **No moment of "this app understands me."**
> *Plain*: the app shows you data *about* you (stats, achievements)
> but never reflects *who you are* back at you in a way that feels
> seen.

---

## 18. Summary in Three Sentences

If a friend asked "what's wrong with this app's UI?", here is what
I'd say:

1. **It looks organised, but it doesn't look alive.** Every screen is
   tidy, every card is in the right place, and nothing makes you
   feel anything.
2. **It looks like the same app five times.** Three of the five tabs
   open with the same pink panel, two of the lists look identical,
   and every interactive element is the same shape.
3. **It looks like a database of people, not a place to meet them.**
   The faces are missing, the playfulness is missing, the brand is
   missing — and that's the part of a dating app that has to be
   present for any of the other parts to matter.

The previous two docs tell you *what to fix*. This doc tells you
*what is missing in the soul of the thing.*

*Generated 2026-04-29. Companion to `design-critique-run-0119.md` and
`2026-04-29-product-completeness-gaps.md`.*
