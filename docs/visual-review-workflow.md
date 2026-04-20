# Visual Review Workflow

This repository now uses an **observability-first** screenshot workflow.

The goal is simple:

1. change code
2. run the visual review suite
3. inspect the newly rendered screenshots
4. understand what the UI looks like right now

This workflow is **not** about comparing old screenshots to new screenshots.
It is about producing a fresh, reviewable snapshot of the current UI for humans and AI agents.

## Canonical entrypoint

Run the visual suite with:

```bash
flutter test test/visual/screenshot_test.dart
```

When driving this from automation or an AI agent, prefer running the command with a timeout so a hung test process cannot stall the workflow indefinitely.

## What each run produces

Every invocation:

- allocates the next monotonic run number from `build/visual_review/archive_state.json`
- clears and recreates `build/visual_review/latest/`
- writes a fresh PNG for every covered screen into `build/visual_review/latest/`
- names latest screenshots like `shell_matches__run-0007.png`
- writes a fresh HTML gallery to `build/visual_review/latest/index.html`
- writes a fresh manifest to `build/visual_review/latest/manifest.json`
- archives the same run under `build/visual_review/runs/<runId>/`
- names archived screenshots like `shell_matches__run-0007__2026-04-20__16-12-05.png`
- prunes stale archived runs before creating run 51, or earlier if the archive bank exceeds `500 MB`
- removes the older legacy output root `build/visual_screenshots/` so there is only one canonical place to inspect

The manifest includes:

- `runId`
- `runNumber`
- `runLabel`
- `workflow`
- `latestDirectory`
- `runDirectory`
- `archiveStateFile`
- one entry per screenshot with scenario name, scenario slug, latest file name, archived file name, run directory name, timestamps, byte size, and both latest/archived paths

## Output layout

Use these paths after the suite finishes:

- `build/visual_review/latest/` — newest screenshots for quick inspection
- `build/visual_review/latest/index.html` — lightweight gallery page
- `build/visual_review/latest/manifest.json` — machine-readable run metadata
- `build/visual_review/archive_state.json` — persistent monotonic run counter and archive bookkeeping
- `build/visual_review/runs/<runId>/` — archived copy of that exact run

Current naming examples:

- latest screenshot: `build/visual_review/latest/shell_matches__run-0007.png`
- archived run folder: `build/visual_review/runs/run-0007__2026-04-20__16-12-05/`
- archived screenshot: `build/visual_review/runs/run-0007__2026-04-20__16-12-05/shell_matches__run-0007__2026-04-20__16-12-05.png`

## Archive cleanup

Cleanup applies only to archived runs under `build/visual_review/runs/`.

The newest `latest/` output is never pruned by retention logic; it is simply replaced by the next successful run.

Before creating run 51, or whenever the archived run bank grows beyond `500 MB`, the workflow prunes the archive and keeps only:

- the oldest 3 archived runs
- the middle 3 archived runs
- the latest 4 archived runs

This preserves the starting point, a middle checkpoint, and the newest history while preventing the archive from growing without bound.

## Automation guidance

Humans and AI agents should inspect the newest run first:

- `build/visual_review/latest/manifest.json`
- `build/visual_review/latest/index.html`

Archived runs should be ignored unless you explicitly need historical context, cleanup verification, or recovery from a missing/corrupt latest run.

## Covered screens

The suite currently captures these UI surfaces at a fixed phone viewport:

- app startup / dev-user picker
- Discover tab
- Matches tab
- Chats tab
- current-user Profile tab
- Settings tab
- conversation thread
- Standouts
- People who liked you
- other-user profile
- profile edit
- location completion
- stats
- achievements
- verification
- blocked users
- notifications

## Review checklist

When inspecting the screenshots, check for:

- clipped or overflowing text
- awkward spacing and padding
- broken hierarchy in cards and headers
- navigation chrome alignment
- button sizing and readability
- forms that feel too cramped or too sparse
- obviously stale or missing data

## Extending coverage

To add more screenshot coverage:

1. add a new `testWidgets` scenario in `test/visual/screenshot_test.dart`
2. pump the target screen with deterministic provider overrides
3. call `_captureAndSave(...)` with a unique file name
4. rerun the suite and inspect the new PNG in `build/visual_review/latest/`

The helper infrastructure in `test/visual/support/` handles output directories, manifests, run archives, and the review gallery.

## Notes

- The screenshots use a fixed `412 x 915` phone-sized surface so the review stays consistent between runs.
- `test/visual/flutter_test_config.dart` loads Material icons and Roboto from the local Flutter SDK cache so the screenshots render with realistic fonts and icons.
- `build/visual_review/latest/` is disposable output; the archived run folders under `build/visual_review/runs/` are useful when you need to refer back to a specific invocation.
- For interactive exploration you can still run the app on Chrome, Windows, or an emulator, but the visual review suite is the repeatable observability artifact.
