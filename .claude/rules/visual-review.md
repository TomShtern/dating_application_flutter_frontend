---
paths:
  - "test/visual_inspection/**"
  - "visual_review/**"
  - "docs/visual-review-workflow.md"
---

## Visual review

Full spec: `docs/visual-review-workflow.md`.

```powershell
flutter test test/visual_inspection/screenshot_test.dart
```

Renders every covered screen at a fixed `412 x 915` phone surface and writes
`visual_review/latest/` (plus `index.html`, `manifest.json`), archiving each run
under `visual_review/runs/` with a monotonic run number.

Fixtures: `test/visual_inspection/fixtures/{visual_fixture_catalog,visual_fixture_builders,visual_scenarios}.dart`.
Font loading happens via `test/visual_inspection/flutter_test_config.dart`.

After any UI change: run the suite, open `visual_review/latest/index.html` — the
fastest way to review all screens at once — and check the result against
`docs/design-language.md` before closing the task.
