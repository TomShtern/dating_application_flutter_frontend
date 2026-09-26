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
| Token state | `auth_token_holder.dart` |

**The endpoint list is `api_endpoints.dart`.** Read it; do not trust an
enumeration in any doc. A previous copy in `AGENTS.md` had already drifted.

### Header rules (implemented in `api_headers.dart` — don't bypass)

- `GET /api/health` gets **no** shared secret. Every other path gets
  `X-DatingApp-Shared-Secret`.
- `X-User-Id` is added when `Options.extra['userId']` is set **and** the path
  starts with `/api/users/` or `/api/conversations/` (`_isUserScoped`).
- `Authorization: Bearer <token>` goes on every protected route.
  `/api/auth/{signup,login,refresh,logout}` deliberately receive no Bearer —
  they carry credentials in the body (`_acceptsBearer`).

### Token lifecycle

`AuthTokenHolder` drives **single-flight refresh**: concurrent 401s share one
refresh future, and `clear()` (logout) invalidates any in-flight refresh via a
generation counter. The Dio interceptor reads it; the auth controller writes it.
Re-implementing refresh anywhere else reintroduces the thundering-herd bug this
design exists to prevent.

### Parsing

Use `ApiClient`'s helpers — `_expectMap()`, `_expectList()`,
`_extractWrappedList()`. Never write raw `as Map` / `as List` casts inline.

### Base URL

Default `http://127.0.0.1:7070`, shared secret `lan-dev-secret`, all three
timeouts 10 s (`AppConfig`). Android emulator must use `http://10.0.2.2:7070` —
not `127.0.0.1`. A physical phone needs the laptop LAN IP.
`ApiError.fromDioException()` detects loopback URLs and suggests the emulator
address in its message.

Two auth entry points converge: `DevUserPickerScreen` (dev quick-select) and the
real signup/login flow both end at a `selectedUserProvider` value. Downstream
code must not branch on which was used.

If a backend response shape is unclear, add or adjust DTO tests before making
broad UI changes.
