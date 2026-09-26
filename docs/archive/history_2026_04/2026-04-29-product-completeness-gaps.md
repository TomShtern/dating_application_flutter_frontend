# Product Completeness — High-Level Gaps

Status: companion to [`design-critique-run-0119.md`](./design-critique-run-0119.md).

That file catalogued **visual / UI / UX** drift and per-screen defects.
This file catalogues everything **outside the pixel** — the systems,
flows, governance, and infrastructure a real dating app needs to ship.
Nothing here is repeated from the previous critique; if a topic was
covered there (auth screens, photo upload UI, age gate, account
deletion, premium UI, safety center, empty / error / loading states,
touch targets, modals, localisation, RTL, accessibility, search,
notification preferences, etc.) it is intentionally omitted.

Treated at category level. Each section is one paragraph of framing
plus a short list of the missing pieces. Not exhaustive within each
category — comprehensive in *coverage* of categories.

---

## 1. Identity & Account Lifecycle

The previous critique flagged "no signup screen exists." The deeper
gap is that the *full lifecycle* of an account is undefined. Sign-in
is one moment; identity is a continuous system.

- Session model: how long does a session live, how is it refreshed,
  what triggers logout (idle timeout? device change? password
  reset?).
- Multi-device: can a user be signed in on phone + tablet + web at
  once? Which device "owns" presence and read-state?
- Account recovery edge cases: lost phone, lost email, lost both,
  hijacked account.
- Suspension states: shadow-banned, soft-warned, temporarily-banned,
  permanently-banned — each needs a distinct UI surface.
- Re-join after self-deletion: cooling-off window, data resurrection
  policy, or hard wall.
- Account merge: same person signs up twice (different email/phone),
  duplicate detection, merge or block.
- Pause / hide profile temporarily — a softer alternative to
  deletion, common in dating apps.
- Device-trust: new device login confirmation via email/SMS.
- Concurrent-login conflicts and forced-logout-elsewhere flow.

---

## 2. Trust, Safety & Moderation — the Engine

Block / report / unblock are the *user-facing* tip of an iceberg.
Underneath, the product needs a moderation engine.

- Reporting taxonomy: spam, harassment, fake profile, underage,
  nudity, hate speech, scam, off-platform solicitation, other —
  with severity tiers.
- Moderator queue + decision SLAs.
- Behavioural scoring: rate-of-likes, rate-of-messages, rate-of-
  blocks-against, used to surface fake / abusive accounts.
- Soft warning escalation: "Your message was flagged…" before a
  hard ban.
- Shadow-ban: profile hidden from new users without telling the
  banned user.
- Catfish / fake-profile detection: photo reverse-search, photo-
  verification mismatch.
- Photo content moderation pipeline: NSFW classifier, face
  detection, ID-vs-selfie verification, deepfake hint.
- Message moderation: in-flight content scanning for harassment /
  threats / off-platform link sharing / age-related red flags.
- Doxxing prevention: phone numbers, addresses, social handles
  redacted from messages by default with a soft confirm.
- Scam detection: known scam phrasing patterns, off-platform-money
  request alerts.
- Block-then-show-similar avoidance: ML signal so blocked users'
  profiles don't reappear as look-alikes.
- Appeal flow: user-side surface to contest a moderation action.
- Underage protection: face-age estimator, age-claim mismatch flags.
- Coordinated abuse detection: same device fingerprint, same VPN /
  IP cluster, harvesting.
- Honey-pot accounts and trap signals.

---

## 3. Privacy & Data Governance

Block lists were UI; *data governance* is the policy layer.

- Granular consent management: marketing emails, push categories,
  analytics, personalisation — separately revocable.
- Photo EXIF stripping at upload (geolocation in EXIF is a doxxing
  vector).
- Audit log of "who saw my profile" — surface what the user can
  see; record what they cannot.
- Data export (GDPR Right of Access) — full ZIP including matches,
  messages, photos, profile history.
- Data erasure (GDPR Right to Erasure) — chained deletion across
  matches, messages, recommender state, backups.
- Data retention policy per category (messages 2y, profile photos
  90d after deletion, etc.) with surfaced summary.
- Apple App Tracking Transparency (ATT) prompt + the no-ATT
  experience.
- Location precision controls: city-level vs neighbourhood vs
  precise — user-selectable.
- Last-seen visibility and read-receipt visibility — toggles, not
  global product decisions.
- Incognito / browsing-mode (premium): see profiles without
  appearing in their viewers list.
- Photo visibility tiers: public (Discover), match-only, request-only.
- Ban-evasion fingerprint storage rules.
- Background-check integrations (e.g. Garbo) where regional product
  decisions allow.
- Privacy-policy versioning + per-version consent log.

---

## 4. Legal & Regulatory Compliance

Beyond the age gate. Multi-jurisdictional product.

- 18+ age verification at signup — and at content-rating boundary
  re-prompts.
- Terms of Service + Privacy Policy versioning with per-version
  acceptance audit.
- Marketing consent (CAN-SPAM, GDPR Art. 6, CCPA opt-out).
- Apple IAP / Google Play Billing compliance — no off-platform
  payment paths for digital goods.
- Subscription disclosure: auto-renewal text, cancel instructions,
  trial-to-paid transitions, regional pricing.
- App Store content rating (Apple 17+, Google M).
- Country-specific feature gating: same-sex matching restrictions in
  some regions, dating-app bans, government identity requirements
  (e.g. India DPDP, UAE, Saudi Arabia).
- LGBTQ+ safety toggle for users travelling to or living in
  restrictive jurisdictions (auto-hide orientation).
- DMCA / copyright reporting for photos.
- EU AI Act: if recommender ML is "high-risk" (it isn't for dating,
  but disclosure may still apply).
- California Age-Appropriate Design Code where relevant.
- Texas / Utah / Florida age-verification laws.
- Right to be forgotten propagation to third-party processors.
- Children's privacy (COPPA-style) belt-and-braces.
- Records-of-processing-activity (ROPA) maintained internally.
- DSR (data subject request) backlog SLA + UI to track.

---

## 5. Real-time Messaging & Presence

The previous critique covered chat *features*. This is the
*architecture* underneath.

- Transport: WebSocket vs Server-Sent Events vs long-poll vs
  push-only.
- Message ordering and dedup across reconnects.
- Offline outbox queue: messages composed without connectivity,
  retried on reconnect, marked as "sending / failed / sent".
- Presence: online / typing / last-seen — propagation, throttling,
  privacy gating.
- Per-conversation read-state sync across devices.
- Message edit and delete semantics (with tombstones).
- Message expiration / disappearing-mode (optional product call).
- End-to-end encryption decision: most dating apps don't, but
  document why.
- Conversation pinning, archiving, muting.
- Backup of message history server-side vs device-only.
- Server-driven typing-indicator throttling to avoid spam.
- Message size limits, attachment size limits.
- Failed-delivery user feedback (silent failures are the worst).

---

## 6. Image, Media & Content Pipeline

Photo upload UX was mentioned. The pipeline behind it is its own
system.

- CDN strategy: which provider, signed URLs, regional edge.
- Responsive size variants per device DPR (1x / 2x / 3x) and
  viewport.
- Blur-up / low-quality placeholder during load (BlurHash, ThumbHash).
- Progressive JPEG / AVIF / WebP support.
- Video upload: codec choice, max duration, compression on device.
- Audio prompts (Hinge-style voice answers).
- Live-photo / motion-photo support.
- Photo upload progress UX, retry, server-side rejection feedback.
- Server-side content moderation in the upload pipeline (NSFW gate,
  face-required gate, group-photo detection — modern dating apps
  actually require a single-face photo as primary).
- Watermarking opt-in to prevent screenshot-and-repost.
- EXIF strip at intake (also a privacy concern — see §3).
- Photo verification ("selfie matching pose") flow, with liveness
  check.
- Stalking-prevention: prevent saving / screenshotting messages and
  profile photos in some markets.
- Image accessibility: AI-generated alt text for screen readers.
- Cache eviction policy on device.
- Ban on AI-generated profile photos (or labelling).

---

## 7. Push & Notification Infrastructure

Notification UI was mentioned. The infrastructure behind it is missing.

- Push provider strategy: FCM (Android), APNs (iOS), web push.
- Notification taxonomy with explicit content templates per type:
  new match, new message, like received (gated), profile view
  (gated), match expiring, conversation reply nudge, standouts
  ready, achievement unlocked, verification status, safety alert,
  legal update, promotional.
- Per-category opt-in matrix mapped to OS-level channels (Android
  notification channels).
- Quiet hours / Do Not Disturb integration.
- Deep-link routing per notification type with a tested target +
  fallback.
- Badge count synchronisation across devices.
- Stale-notification handling (user already read on web → mute
  push).
- Throttling: don't deliver 12 likes-received pushes; bundle.
- Localised notification copy.
- Rich push: photo / action buttons (Reply, Like back).
- Push delivery telemetry (sent vs delivered vs opened).
- Privacy-respecting push (no message content in lock-screen if
  user chooses).
- Server-driven notification preferences source-of-truth (so
  switching device preserves opt-ins).

---

## 8. Monetization & Billing

Premium UI was mentioned. The billing system is broader.

- Subscription tier definition: free / plus / premium / VIP — with
  feature matrix.
- Single-use IAP: Boosts, Roses, Super-likes, Profile-views-pack.
- Trial offers, trial-to-paid conversion telemetry, win-back offers.
- Restore purchases flow.
- Family Sharing eligibility (Apple) and Google Play Family.
- Regional pricing tiers (App Store / Play console price tiers).
- Promo codes and gift codes.
- Refund handling and refund-policy surface.
- Subscription management deep-link (Apple / Google subscription
  pages).
- Cancel / pause / downgrade flow inside the app.
- Churn flow: "before you cancel, here's what you'll lose…" — done
  ethically, no dark patterns.
- Receipt validation (server-side, anti-piracy).
- Tax / VAT compliance.
- Payment method update prompts (expired card recovery).
- Anti-abuse: shared-account detection on premium tiers.
- Paywall placement strategy: which surfaces gate which features.
- Paywall variant testing infrastructure (see §13).

---

## 9. Onboarding & First-Run Experience

Sign-up was mentioned. Onboarding is everything that comes after.

- Aspirational welcome / value-prop reveal — what makes this app
  different.
- Photo upload guide with examples ("face visible, no group
  photos as primary, no sunglasses").
- Profile-completion scoring with concrete next-steps surfaced.
- Permissions soft-asks staged: notifications first, location
  second, camera at upload time only.
- Coach-marks for first interaction with each major surface.
- "First like" celebration moment.
- "First match" celebration moment.
- "First message" celebration moment + suggested icebreakers.
- Empty-state-as-onboarding: when the user has no matches, that
  state can teach the gesture / behaviour.
- Re-onboarding when major versions ship.
- Returning-user re-engagement onboarding.
- Photo verification prompt early to lift trust signals.

---

## 10. Engagement, Lifecycle & Retention

Long-term mechanics that keep a real product alive.

- Daily quotas: free-tier likes-per-day with reset banner.
- Match expiration: e.g. 24h to send the first message, otherwise
  match expires (Bumble, Hinge).
- Streak mechanics (controversial — handle ethically).
- Standouts / Daily picks windows with a reset cadence.
- "You missed N likes / N matches" digest re-engagement push.
- Inactivity hints: "It's been 5 days. New profiles are waiting."
- Win-back flow for churned users.
- Email digest as a fallback channel.
- Cross-promo within owned product family (if applicable).
- Re-ranking after long inactivity (don't surface the user as
  "active" if they haven't opened the app).
- Seasonal / event surfaces (Valentine's, Pride, New-year-new-me).
- Inactivity-grace before considering the account dormant.

---

## 11. Recommender Feedback Loop & Match Quality

"Why this profile is shown" exists. The reverse, and the inputs,
do not.

- Explicit feedback signal: "Less like this" / "More like this"
  from a profile or after a pass.
- Block-then-deprioritise-similar: blocked users seed a vector
  used to dampen look-alikes.
- "Not seeing what you wanted?" survey after N passes.
- Recommender explainability beyond the existing chips.
- Discovery freshness budget: never show the same profile twice
  in N days unless deliberate.
- Mutual-pass dampening (we both passed → don't resurface).
- Travel / passport mode: temporarily search a different city.
- Deal-breaker filters separate from preferences.
- Must-haves vs nice-to-haves separated in filter UX.
- Profile-completeness filter: hide low-completion profiles
  (premium).

---

## 12. Profile Expression Beyond Basics

Bio + photos was mentioned. Modern dating profiles are richer.

- Prompts and answers (Hinge / Bumble's signature feature).
- Voice prompt answers (Hinge "audio").
- Video moments / loops.
- Photo captions per photo.
- Lifestyle attributes: drinking, smoking, kids, religion,
  politics, diet, languages, height, education, occupation.
- Looking-for: relationship intent, casual vs serious vs
  marriage-track.
- Conversation prompts the user can pre-load.
- Compliments-on-prompt mechanics (Hinge "comment then like" UX).
- Profile templates / starter prompts for first-time users.
- Profile preview mode: see your profile as others see it.
- Per-photo "primary" selection.
- Drag-to-reorder photos.
- "About me" guided fields (favourite spot, weekend ritual, etc.).

---

## 13. Communication Surfaces Beyond Text

Chat input was mentioned to need attach / emoji / voice. Bigger
picture:

- Voice notes with waveform + transcript.
- Photo / video attachment with disappearing-mode option.
- GIF / sticker library.
- Reaction emojis on individual messages.
- Reply-to / quote-bubble for context.
- Long-press message actions: copy, react, reply, report, delete.
- Voice / video call (with safety: in-app only, blurred until
  consent, no save).
- Schedule a date inline (calendar handoff).
- Share-location for date with timed expiry.
- "Bring a friend" mention or screenshot-of-conversation share to
  a vetting friend (popular for safety).
- Saved replies / icebreaker presets.
- Translation in-bubble for cross-language matches.

---

## 14. Date Planning & Post-Match Care

After a match → before / after a date.

- Date scheduling helper, calendar invite.
- Suggested date venues (3rd-party integrations: Yelp, Google
  Places).
- Pre-date safety check-in: "Tell a friend where you'll be."
- Post-date check-in: "How did it go?" feedback used as a
  recommender signal.
- "We met!" mechanic (Hinge): paused / unmatched outcome capture.
- Post-date compatibility refinement.
- Anniversary moments for long matches.
- Unmatch-after-bad-experience flow with optional report.
- Saved date ideas.

---

## 15. Customer Support & Self-Service

What does a user do when something is wrong?

- In-app help center with searchable articles.
- Contact support — chat / email / form / ticket.
- Status page link — "Service degraded? Check status here."
- Force-update flow when the server requires a minimum app version.
- Soft-update prompt for non-breaking versions.
- Maintenance-mode banner.
- Bug-report with attached log / screenshot / device info.
- In-app feedback widget for product-team listening.
- FAQ for billing, blocking, reporting, deleting account.
- Account-frozen explanation surface with appeal CTA.
- Error-code dictionary mapped to user-readable messages.

---

## 16. Engineering Infrastructure & Observability

The internal scaffolding needed to operate the app.

- Build flavors: dev / staging / prod with separate
  config / signing / icons.
- CI/CD pipeline: unit + analyse + build per push, signed builds
  per branch, Play / TestFlight upload automation.
- Crash reporting (Sentry / Crashlytics) — symbolicated, with
  release tags.
- Performance monitoring (Firebase Perf, Datadog RUM) — cold start,
  TTI, screen-render times, network latency per endpoint.
- Logging strategy: structured logs with PII redaction.
- Feature flags / remote config: kill-switch any feature without
  shipping a build.
- A/B testing infrastructure: experiment framework, assignment
  service, exposure logging.
- Performance budgets: cold-start <2s, TTI Discover <1s, memory
  <200 MB on mid-tier device.
- Image / build size budget; warn on regressions.
- Secret management: no secrets in repo; rotation plan.
- Code-signing identity ownership and rotation.
- Crash-free-session SLO and dashboards.
- Backend-error rate alerting integration.
- Release notes pipeline.
- Hotfix rollback strategy.

---

## 17. Analytics, Growth & Attribution

Without telemetry, the product flies blind.

- Event taxonomy: name, schema, owner, retention.
- Critical funnels defined and instrumented: signup completion,
  first-photo upload, first-like, first-match, first-message,
  D1 / D7 / D30 retention.
- Cohort analytics dashboards.
- Mobile-measurement-partner attribution (AppsFlyer / Adjust /
  Branch).
- Universal Links / Android App Links for deep-linking from web.
- Referral / invite-a-friend mechanics with attribution.
- Viral surfaces: shareable match cards, profile share-link.
- Paywall A/B exposure logging.
- Recommender quality metrics (offline + online).
- Search-term analytics (when search is added).
- North-star metric definition (e.g. "weekly active mutual
  matches").
- Privacy-respecting analytics defaults (no PII).

---

## 18. Cross-Platform Strategy

CLAUDE.md says "Android first" — that is a starting point, not a
plan.

- iOS parity timeline and feature delta tolerance.
- Web presence: profile share-page, signup, even if logged-in
  experience stays mobile.
- Tablet / foldable layout decisions (or explicit
  "phone-only" lock).
- Wear OS / Apple Watch surfaces for new-match notifications.
- Device-specific feature gating (e.g. iOS-only ATT).
- Codebase strategy: pure Flutter cross-platform vs platform-
  channel native bridges.
- Offline-first design where possible vs always-online assumption.
- Low-end-device fallback: animation reduction, image quality
  reduction, fewer concurrent loaders.
- Right-now minimum supported OS versions and deprecation policy.

---

## 19. Backend Contract Hardening

CLAUDE.md is clear that the backend owns logic. The *contract* is
where dating-app-specific risk lives.

- Pagination contracts: cursor-based vs offset, stable ordering
  across reloads.
- Idempotency keys for likes / blocks / matches / payments — never
  let a flaky network duplicate a charge or a like.
- Rate limits per endpoint, with user-visible feedback.
- Schema versioning strategy for the API.
- Backwards compatibility guarantees (server cannot break older
  clients without forced-update).
- Long-poll / WebSocket / push contract (see §5).
- Conflict resolution for concurrent edits across devices.
- Sync watermarks for incremental fetches.
- Server-driven UI signals where appropriate (e.g. promo banners).
- Graceful degradation: which features can run if specific
  services are down.
- Health-check endpoints surfaced to the client for adaptive
  retry.

---

## 20. Inclusivity, DEI & Responsible Design

The pieces beyond just gender pills.

- Pronoun field separate from gender.
- Sexual-orientation depth: multi-select where relevant.
- Gender-expansive matching: who-shows-to-whom logic for non-binary
  users.
- LGBTQ+ safety toggle (auto-hide orientation in restrictive
  countries — see also §4).
- Body-positive defaults in copy and imagery.
- Accessibility-first design assumed (rather than added late).
- Skin-tone diversity in default illustration / emoji.
- Languages and locales beyond English.
- "Take a break" / pause-account as a wellness tool.
- Mental-health resource link surfaced in safety center.
- Harassment-recovery workflow: counselling resources after a
  reported incident.
- Screen-time controls and gentle nudge reminders.
- Dark-pattern audit: no fake countdowns, no fake "X people are
  looking at you", no manipulative empty states.
- Match-fatigue handling: stop pushing notifications when a user
  is clearly overwhelmed.

---

## 21. Documentation & Design System Foundation

`docs/design-language.md` is excellent. The next layer doesn't
exist yet.

- Token catalogue exported from `AppTheme` to a single canonical
  doc with light + dark swatches and intended use.
- Component catalogue (Widgetbook / Storybook) — every shared
  widget rendered in every variant.
- Figma sync between design tokens and code tokens.
- Contribution guide for adding a shared widget.
- Accessibility annotations per component (semantic role,
  expected screen-reader output, contrast pairs).
- Usage do / don't gallery per component.
- Migration / deprecation log for replaced widgets.
- Visual regression baseline beyond the current screenshot set
  (golden tests at the *component* level once design is locked).
- Page-level pattern documentation: when to use a hero, when to
  use a compact intro, when to use a section label — with code
  examples.
- Onboarding doc for new contributors covering the full
  thin-client philosophy.
- Architecture decision records (ADRs) for non-trivial choices
  (state-management, navigation, image pipeline, etc.).
- Backend-contract changelog cross-referenced from the client
  side.

---

## 22. The "Hidden" Surfaces

Surfaces a user almost never thinks about, but the product
absolutely needs.

- App-icon variants per build flavor (so dev / staging are
  distinguishable on-device).
- Splash / launch screen with brand mark.
- Maintenance / forced-upgrade screen.
- "App update available" soft prompt.
- "We've updated our terms" forced-acceptance banner.
- "Your subscription is about to renew" reminder.
- "Receipt sent to your email" surface.
- "We've sent you a security alert" surface.
- Confirmation receipts for legally-significant actions
  (account deletion, data export request, age update).
- Cookie / tracking consent banner for any web companion.
- Deep-link landing pages with smart fallbacks (open app if
  installed, else App Store / Play / web).
- Email templates (welcome, reset, verification, weekly digest,
  match notification, billing) — these are part of the product
  even if not in the app binary.

---

## Closing Note

The previous critique tells you what's wrong with the screens you
*have*. This file tells you what's missing from the product you
*don't have yet*. Both are needed before "lock-in" means anything
beyond visual.

The shortest credible path to a real, shippable v1 is, in order:

1. Lock the visual language (the previous critique's Tier A).
2. Pick a v1 feature scope from §1, §2, §3, §4, §8 here — these
   are the categories that, if missing, make the app
   un-shippable rather than incomplete.
3. Pick a v1 engineering scope from §5, §6, §7, §16, §19 — these
   are what make the app stable rather than fragile.
4. Defer §9–§15 and §17–§20 to a v1.x roadmap, but document
   their intent now so the system can grow into them.
5. §21 should run in parallel with §1; the design system
   foundation gets cheaper to build the earlier you start.

*Generated 2026-04-29. Companion to `design-critique-run-0119.md`.*
