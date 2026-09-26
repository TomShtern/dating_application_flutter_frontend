---
paths:
  - "test/**"
---

## Testing

The "no new tests during frontend work" rule lives in `AGENTS.md` because it must
apply *before* you open this directory. Re-read it there.

Tests mirror `lib/` under `test/`.

**FakeApiClient pattern** — test files extend `ApiClient` and override specific
methods to return controlled responses. Do **not** use Mockito or manual mocks.
See `test/features/browse/` for the reference example.

**Provider overrides** — wrap the widget under test in
`ProviderScope(overrides: [...])` to inject fakes.

For shared providers, models, API methods or app-shell changes, run broader tests
because many screens depend on those layers. For API contract changes, add or
update API client/model tests.

Before adding a regression test, name the concrete failure it prevents. Protect
real contracts, state transitions, routing safety, payload preservation and prior
bug fixes — not temporary layout structure, exact copy, or intermediate UI
detail. If the risk is mainly visual polish, use the screenshot workflow instead.
