# UI Overhaul Coordination Plan

> Audience: project manager, backend engineer, frontend implementer
> Date: 2026-04-25
> Purpose: make the next steps, owners, order, and blocking decisions obvious at a glance so execution can start cleanly instead of chaotically.

---

## What exists already

These three documents now define the work:

- `docs/superpowers/specs/2026-04-23-dating-app-ui-overhaul-design.md` — the approved frontend design direction
- `docs/2026-04-25-ui-overhaul-backend-handoff.md` — what the frontend needs from the backend, endpoint-by-endpoint
- `docs/superpowers/plans/2026-04-24-dating-app-ui-overhaul-implementation.md` — the frontend implementation plan

That means the project is **not** undefined anymore.

The project now needs **coordination and sequencing**, not more vague thinking.

---

## The simple operating model

There are only three tracks:

1. **Manager track** — decides priority, gets sign-off, keeps everyone aligned
2. **Backend track** — defines and ships the API/data contract the frontend needs
3. **Frontend track** — builds the UI and integrates real backend contracts

### One-line rule

- Backend owns **logic and data contracts**
- Frontend owns **UI and integration**
- Manager owns **priority, sign-off, and sequencing**

---

## Who does what

| Role                  | Owns                                                                                                | Does not own                                                                     |
|-----------------------|-----------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------|
| Manager               | priority, order, deadlines, sign-off, tradeoff decisions, phase gating                              | endpoint implementation, widget implementation                                   |
| Backend engineer      | endpoint paths, payloads, semantics, performance, seed data, dev/prod behavior clarity              | Flutter layout, component design, client-side UX states                          |
| Frontend implementer  | UI system, layout, widgets, loading/error states, DTO wiring, API integration, tests, visual review | business logic, recommendation logic, compatibility logic, server-side semantics |
| Shared responsibility | contract clarity, integration verification, dev-environment usefulness                              | pretending the other side can guess unspecified behavior                         |

---

## What needs to happen now

This is the immediate next-action list.

### Right now — manager

| Action                                                                        | Output                                  | Why                                                                        |
|-------------------------------------------------------------------------------|-----------------------------------------|----------------------------------------------------------------------------|
| Send `docs/2026-04-25-ui-overhaul-backend-handoff.md` to the backend engineer | backend has the contract request doc    | backend now has one clear source of frontend needs                         |
| Ask for written answers to the six immediate P0 contract questions below      | signed-off contract response            | prevents frontend from building rich surfaces on undefined data            |
| Set a short response deadline                                                 | coordination stays real, not open-ended | this is a contract decision gate, not an endless architecture conversation |

### Right now — backend engineer

| Action                                                      | Output                                         | Why                                                                     |
|-------------------------------------------------------------|------------------------------------------------|-------------------------------------------------------------------------|
| Review the backend handoff                                  | backend understanding of actual frontend needs | backend sees what is required without reading frontend design rationale |
| Reply to the six immediate P0 questions in writing          | contract decisions                             | frontend needs explicit answers, not assumptions                        |
| Mark each item as `Exists now`, `Will add`, or `Deferred`   | decision status per item                       | lets the manager sequence work cleanly                                  |
| If an item exists now, provide sample request/response JSON | integration-ready examples                     | frontend can wire DTOs without guesswork                                |

### Right now — frontend implementer

| Action                                                                               | Output                       | Why                                                               |
|--------------------------------------------------------------------------------------|------------------------------|-------------------------------------------------------------------|
| Start only backend-independent foundation work                                       | progress without waiting     | large parts of the UI overhaul do not need new backend data first |
| Do **not** start the richest data-dependent surfaces until P0 contract answers exist | avoids rework and fake logic | prevents bad assumptions from spreading                           |

---

## The six immediate P0 contract questions that must be answered first

These are the first decision gate.

The backend handoff lists more than six useful contract areas. For coordination, these six are the immediate P0 gate because they block correctness or the main people-first dating surfaces. Stats and achievements remain important, but they are tracked as P1 unless the project manager explicitly decides to prioritize those screens before the main matching/profile work.

1. **Match-to-conversation identity**
   - Is `matchId` the same value as `conversationId`?
   - If not, which payloads will return `conversationId`?
   - What should the frontend use when opening chat from matches or a new match?

2. **Photo strategy**
   - Will existing summary/list endpoints be enriched?
   - Or will there be a batch summary endpoint?
   - Or is temporary N+1 detail fetching the intended short-term bridge?

3. **Match quality**
   - Does a live `match-quality` endpoint already exist?
   - If yes, what is the exact path and response shape?
   - If no, will it be added now or deferred?

4. **Presentation context**
   - How will the backend provide `Why this profile is shown`?
   - Dedicated endpoint or enriched payload?

5. **Profile edit read model**
   - Will `GET /api/users/{id}` become richer?
   - Or will there be a dedicated edit snapshot endpoint?

6. **Notification schema**
   - What notification types exist?
   - What `data` keys are guaranteed for each type?

### Why these six come first

Because they block the most product-defining frontend surfaces:

- `Discover`
- `Matches`
- correct `Message now` routing
- other-user profile reasoning
- `Profile edit`
- `Notifications`

### P1 contract areas to keep visible

These should be answered or scheduled, but they do not need to block the first frontend foundation pass or the core matching/profile integration unless the manager moves them up:

- grouped/typed `Stats`
- stable `Achievements` semantics
- conversation-summary enrichment
- persistent `Hide`
- verification resend/cooldown support

---

## Work that can start immediately without backend changes

The frontend does **not** need to wait for the backend to begin all work.

### Safe-to-start frontend work

- theme overhaul
- shell cleanup
- bottom-nav duplicate-strip removal
- shared component system
- overflow menu pattern
- developer-only framing cleanup
- shared card/list density improvements
- no-photo fallback visuals
- empty/loading/error states
- location UI polish using current contract
- conversation-thread polish
- blocked-users polish
- screenshot fixture/layout cleanup not dependent on new data

### Why this can start now

Because these are frontend-owned concerns and do not require new business logic or new endpoint semantics.

---

## Work that should wait for backend contract answers

These frontend tasks are contract-sensitive and should not start in full until the backend answers the P0 questions.

### Wait for backend before fully implementing

- `Discover` final rich card treatment
- compact `Daily pick` with high-quality content
- `Matches` final `Why we match` behavior
- other-user profile `Why this profile is shown`
- fully correct `Profile edit` prefilling
- `Notifications` quick actions / deep links

### Wait for P1 backend answers before fully implementing

- data-rich `Stats` and `Achievements` detail behaviors
- enhanced chat-list previews if they need new conversation-summary fields
- persistent `Hide`
- verification resend/cooldown UX

### Why they should wait

Because the frontend would otherwise either:

- fake server-owned logic, or
- build against guesses, then rewrite later

Both are bad.

---

## Phase order

This is the recommended execution sequence.

| Phase | Name                                    | Primary owner     | Can run in parallel?               | Blocks what comes after? |
|-------|-----------------------------------------|-------------------|------------------------------------|--------------------------|
| 0     | Contract sign-off                       | Manager + Backend | yes, with frontend foundation work | yes                      |
| 1     | Frontend foundation work                | Frontend          | yes, with backend P0 work          | partially                |
| 2     | Backend P0 contract work                | Backend           | yes, with frontend foundation work | yes                      |
| 3     | Frontend contract integration           | Frontend          | no, depends on phase 2 outputs     | yes                      |
| 4     | Secondary backend/frontend improvements | Shared            | partly                             | no, but improves quality |
| 5     | End-to-end verification and polish      | Shared            | no                                 | final gate               |

---

## Phase-by-phase instructions

## Phase 0 — Contract sign-off

### Owner
- Manager leads
- Backend answers
- Frontend reviews for integration safety

### Goal
Lock the P0 contract decisions.

### Inputs
- `docs/2026-04-25-ui-overhaul-backend-handoff.md`

### Outputs
- explicit answers for each P0 question
- exact endpoint paths
- sample request/response JSON where relevant
- status per item: `Exists now`, `Will add`, or `Deferred`

### Done when
- nobody is guessing about match-to-conversation identity, photos, match quality, presentation context, profile-edit read model, or notification schema

### Do not do yet
- do not start rich frontend integration that depends on unanswered P0 items

---

## Phase 1 — Frontend foundation work

### Owner
- Frontend implementer

### Goal
Ship all high-value UI/system work that is independent of new backend contracts.

### Inputs
- approved design spec
- frontend implementation plan

### Coordination note

The current frontend implementation plan is still a draft. If it asks for API/DTO wiring before backend answers exist, treat that wiring as blocked and start with backend-independent foundation work instead.

### Outputs
- new theme system
- shell cleanup
- shared widgets/components
- overflow menu migration
- developer-only treatment cleanup
- general density/layout improvements

### Done when
- the frontend has a strong visual/system foundation ready to receive richer data later

### Why this phase matters

It keeps frontend progress moving while backend decisions are being made.

---

## Phase 2 — Backend P0 contract work

### Owner
- Backend engineer

### Goal
Implement or confirm the core contracts the frontend needs for high-quality data-dependent surfaces.

### Inputs
- backend handoff doc
- manager sign-off on priorities

### Outputs
- confirmed `matchId` / `conversationId` semantics
- enriched summary/list payloads or agreed alternative strategy
- `match-quality` contract
- presentation-context contract
- profile-edit read model solution
- notification schema documentation or implementation

### Done when
- frontend has enough real contract clarity to integrate rich UI honestly

### Important note

Backend should focus on the contract and data quality, not on frontend visuals.

---

## Phase 3 — Frontend contract integration

### Owner
- Frontend implementer

### Goal
Wire the newly confirmed backend contracts into the real data-rich surfaces.

### Inputs
- backend P0 outputs from phase 2

### Outputs
- DTO updates
- API client updates
- model/API tests
- correct chat-opening behavior from matches and new-match flows
- rich `Discover`
- rich `Matches`
- profile reason sheets
- better notifications integration
- fully correct profile-edit prefilling

### Done when
- the frontend is using real backend data instead of placeholders or assumptions

---

## Phase 4 — Secondary improvements

### Owner
- Shared, but split by domain

### Backend side may handle
- grouped/typed stats improvements
- richer achievements semantics
- optional conversation-summary enrichment
- optional blocked-user enrichments
- optional verification resend/cooldown support
- optional persistent `Hide`

### Frontend side may handle
- richer stats/achievements presentation
- better chat-list density if new data exists
- enhanced blocked-user rows if new data exists
- nicer verification flow if resend/cooldown data exists

### Done when
- all non-P0 but meaningful improvements are either shipped or explicitly deferred

---

## Phase 5 — End-to-end verification and polish

### Owner
- Shared

### Goal
Verify the whole loop with real data and real contracts.

### Backend should verify
- payloads match agreed shapes
- photo URLs work reliably
- dev data is stable and useful
- performance is acceptable on enriched list endpoints

### Frontend should verify
- `flutter analyze`
- relevant widget tests
- full `flutter test`
- visual review suite
- manual smoke flow through the main product surfaces

### Done when
- the contracts are stable
- the UI is visually correct
- the data is believable and useful
- no fake client-side business logic remains

---

## What the backend should send back to unblock frontend integration

For each P0 item, backend should return:

1. `Exists now`, `Will add`, or `Deferred`
2. exact endpoint path
3. sample request JSON if relevant
4. sample response JSON
5. guaranteed fields
6. nullability / enum notes
7. identity mapping notes if needed
8. expected availability date or priority

This is the minimum useful contract packet the frontend needs.

---

## What the frontend should **not** do before contracts are clear

The frontend should not:

- invent compatibility logic
- invent recommendation reasons
- infer profile-presentation logic from random fields
- guess notification routing from undocumented payloads
- assume profile-edit data that the backend never promised
- hardcode temporary hacks as if they are long-term truth

---

## Manager checklist

This is the clean checklist for the person managing the work.

### Do now

- [ ] Send backend handoff to backend engineer
- [ ] Ask for written answers to the six immediate P0 questions
- [ ] Set a decision deadline
- [ ] Tell frontend to start only backend-independent foundation work

### Do after backend responds

- [ ] Review backend answers for completeness
- [ ] Confirm what is `Exists now`, `Will add`, and `Deferred`
- [ ] Approve the contract set for frontend integration
- [ ] Tell frontend which rich surfaces are officially unblocked

### Do before final sign-off

- [ ] Confirm backend seed/dev data quality
- [ ] Confirm media URL reliability
- [ ] Confirm dev-only behavior is clearly labeled and not mistaken for production behavior
- [ ] Confirm frontend passed analysis/tests/visual review on the relevant phases

---

## Backend checklist

- [ ] Review backend handoff doc
- [ ] Answer the six immediate P0 contract questions
- [ ] Provide example JSON for every approved P0 contract
- [ ] Implement or schedule the agreed P0 changes
- [ ] Confirm stable dev data is available
- [ ] Confirm media URLs work in mobile development environments

---

## Frontend checklist

- [ ] Start foundation work immediately
- [ ] Avoid data-rich contract-dependent implementation until phase 0/2 outputs exist
- [ ] Update DTOs/API client only after backend answers are explicit
- [ ] Build the rich surfaces against real sample payloads
- [ ] Verify with tests + visual review + smoke flow

---

## If time is tight, use this order only

If you want the shortest, least-confusing execution order, use this exact sequence:

1. manager sends backend handoff
2. backend answers six immediate P0 questions
3. frontend starts only backend-independent foundation work
4. backend ships or confirms P0 contract changes
5. frontend integrates P0-backed rich surfaces
6. shared team handles P1 improvements
7. final QA and visual review

That is the cleanest path from today to execution.
