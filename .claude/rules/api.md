---
paths:
  - "lib/api/**"
  - "lib/models/**"
---

## API layer

Everything HTTP is centralized in `lib/api/`. Never add headers, retries or
JSON casts in feature code.

| Concern | File |
|---|---|
| Endpoint builders | `api_endpoints.dart` |
| Header injection | `api_headers.dart` |
| Calls + JSON parsing | `api_client.dart` |
| Error mapping | `api_error.dart` |
| Auth (token + 401 handling) | `clerk_auth_interceptor.dart` |

**The endpoint list is `api_endpoints.dart`.** Read it; do not trust an
enumeration in any doc. A previous copy in `AGENTS.md` had already drifted.

### Header rules (implemented in `api_headers.dart` — don't bypass)

- `GET /api/health` gets **no** shared secret. Every other path gets
  `X-DatingApp-Shared-Secret`.
- There is **no `X-User-Id` header**. The backend derives the caller from the
  token; the local user id only appears in `/api/users/{id}/...` paths.
- `Authorization: Bearer <Clerk session token>` goes on every path except
  `/api/health` (`ApiHeaders.needsBearer`).

### Token lifecycle

Clerk session tokens last ~60 s. `ClerkAuthInterceptor` asks Clerk for a fresh
token on **every request** — no caching, no secure storage, no refresh timer
in this app (the Clerk SDK manages its own session). Never store a token.

401 handling lives only in that interceptor:

- `NOT_PROVISIONED` → `POST /api/auth/session`, retry once.
- `UNAUTHORIZED` → fresh token, retry once; still 401 → `expireSession()`
  (Clerk sign-out).
- `403 FORBIDDEN` = wrong id in the path (client bug), not an auth problem.
  Never retried. Only `GET /api/users/{id}` may name another user; every other
  `/api/users/{id}/...` path must carry the caller's own id.
  `GET /api/users/{id}/presence` may name another user too, but only an active
  match with no block either way; anyone else is a deliberate 403, which
  `PresenceController` remembers per user instead of pausing all presence.
- `429` → wait `Retry-After` (default 2 s, capped 5 s) and retry a **GET** once.
  Writes are never retried by the interceptor; the caller sees the 429.
  On like/pass/super-like a 429 with code `RATE_LIMITED` is the daily limit, not a burst
  (`ApiError.isDailyLimit`) — show the backend message, never retry.
- **Passive requests** (`ClerkAuthInterceptor.passiveExtra`: photos, heartbeat,
  typing, presence) get the normal headers but their failures pass straight
  through — no retry, no provisioning, no sign-out. Callers swallow the error.
- A URL on another host is sent with `skipAuthExtra`: no shared secret, no
  token.

### Photos

`/photos/...` needs the same headers as the API, so images are **not** loaded
with `Image.network`. `AppNetworkImage` → `AuthenticatedPhotoImage` →
`ApiClient.getPhotoBytes`, which goes through the interceptor and so gets a
fresh token per request. Any failure shows the widget's fallback. Decoded
images live in Flutter's in-memory `ImageCache` only; there is no disk cache.

### Presence

All presence logic is `lib/features/presence/presence_provider.dart`
(`PresenceController`): own heartbeat, typing calls, and other users' status.
Widgets register interest through `PresenceObserver` / `PresenceDot` and only
while on screen. The intervals are the constants at the top of that file.
Presence is decoration — a failure hides the indicator and never surfaces.
- A retried request re-sends its body, so multipart uploads are cloned
  (`FormData` can be sent only once). Keep photo uploads going through Dio.

`POST /api/conversations/{id}/messages` needs `senderId` in the body and the
backend 403s unless it equals the caller — send the local UUID.

`/api/users/{id}/...` always takes the **local UUID** returned by
`POST /api/auth/session` (stored in `selectedUserProvider`), never the Clerk
`user_...` id. Sign-out is Clerk's `signOut` only.

### Parsing

Use `ApiClient`'s helpers — `_expectMap()`, `_expectList()`,
`_extractWrappedList()`. Never write raw `as Map` / `as List` casts inline.

### Base URL

Default `http://127.0.0.1:7070`, shared secret `lan-dev-secret`, all three
timeouts 10 s (`AppConfig`). Android emulator must use `http://10.0.2.2:7070` —
not `127.0.0.1`. A physical phone needs the laptop LAN IP.
`ApiError.fromDioException()` detects loopback URLs and suggests the emulator
address in its message.

Auth is Clerk-only: `SignInScreen` (Clerk's prebuilt UI, plus a debug-only
quick sign-in list from `CLERK_TEST_ACCOUNTS`). `AuthController` provisions the
local profile after sign-in and stores its id in `selectedUserProvider`.
`DevUserPickerScreen` is kept but unreachable — the backend no longer accepts
`X-User-Id`.

If a backend response shape is unclear, add or adjust DTO tests before making
broad UI changes.
