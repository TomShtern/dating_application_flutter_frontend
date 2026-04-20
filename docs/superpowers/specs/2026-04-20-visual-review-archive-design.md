# Visual Review Archive and Retention Design

## Goal

Extend the existing Flutter visual review workflow so every successful run produces fresh screenshots inside the workspace, keeps the newest run easy to inspect, keeps historical runs organized and traceable, and prunes stale history with a custom retention policy that preserves the oldest, middle, and newest archived runs.

## Current baseline

The repository already has an observability-first screenshot workflow with these properties:

- the canonical entrypoint is `flutter test test/visual_inspection/screenshot_test.dart`
- the latest run is written to `build/visual_review/latest/`
- an archived copy is written to `build/visual_review/runs/<runId>/`
- `manifest.json` and `index.html` are generated for review
- the current screenshot suite covers 17 screens

This design keeps that overall model and upgrades naming, archive identity, and retention behavior.

## Approved decisions

### 1. Output structure

Keep `build/visual_review/` as the root.

Use these subpaths:

- `build/visual_review/latest/` — newest run only, rebuilt every successful run
- `build/visual_review/runs/` — archived historical runs
- `build/visual_review/archive_state.json` — persistent metadata for run numbering and archive bookkeeping

`latest/` is the primary inspection target. `runs/` is the historical bank.

`archive_state.json` must persist at least the next run number so numbering remains monotonic across cleanup.

### 2. Run identity and folder naming

Each run gets a monotonic run number that never decreases even if old archive runs are deleted.

Run numbers are persisted in `build/visual_review/archive_state.json`.

Run number formatting uses at least four digits with zero padding, for example `run-0001` and `run-0050`.

Archived run folders use this format:

- `run-0001__2026-04-20__16-12-05/`
- `run-0002__2026-04-20__16-18-41/`

This yields:

- stable chronological sorting
- easy human scanning
- uniqueness when multiple runs happen on the same day

Archived run folders must sort correctly with ordinary lexicographic file-system ordering.

### 3. Screenshot file naming

Latest screenshots include the scenario slug and run number:

- `shell_matches__run-0007.png`
- `profile_edit__run-0007.png`

Archived screenshots include the full run identity:

- `shell_matches__run-0007__2026-04-20__16-12-05.png`
- `profile_edit__run-0007__2026-04-20__16-12-05.png`

This keeps `latest/` readable while allowing a copied archived PNG to remain self-identifying.

Within both `latest/` and each archived run folder, screenshot file names must be deterministic and naturally sortable by scenario slug.

### 4. Screenshot metadata

Every screenshot entry in the manifest must include enough information to identify and locate the screenshot without guessing.

Required manifest fields per screenshot:

- scenario name
- scenario slug
- latest file name
- archived file name
- run number
- run folder name
- capture timestamp in UTC
- file size in bytes
- latest path
- archived path

Archived PNG files must also carry embedded machine-readable metadata with the same identity fields.

The metadata must let an automation agent identify what a single archived file is, what run it came from, and when it was captured even if the file is handled outside the HTML gallery.

### 5. Review ergonomics

Reviewers should inspect `build/visual_review/latest/` first.

The gallery and documentation should make it clear that:

- `latest/` is the current truth
- archived runs are for historical reference only
- this workflow is for observability and inspection, not screenshot comparison

Automation and AI review flows must default to `build/visual_review/latest/manifest.json` and `build/visual_review/latest/index.html` first.

Archived runs should be ignored unless one of these is true:

- the user explicitly asks for historical review
- the current run output is missing or corrupt
- cleanup or retention behavior is being investigated

### 6. Cleanup unit

Cleanup operates on archived runs as complete units.

Cleanup must never delete individual PNG files inside a preserved run.

This preserves run integrity, manifest accuracy, and gallery usefulness.

### 7. Cleanup triggers

Automatic cleanup runs before creating a new archived run when either condition is true:

- the archived run bank already contains 50 runs, or
- the `build/visual_review/runs/` archive bank is over 500 MB

Operationally, this means cleanup must happen before run 51 is created.

The newest `latest/` output is never pruned by retention logic. It is simply replaced on the next successful run.

### 8. Cleanup shape

When cleanup runs, preserve exactly these archived runs:

- the oldest 3 archived runs
- the middle 3 archived runs
- the latest 4 archived runs

Delete archived runs between those preserved bands.

Middle-run selection is based on archived-run order after sorting by run number ascending.

- for an odd count, choose the median run and its immediate neighbors
- for an even count, choose the lower-centered block of three

Example with 50 archived runs:

- oldest block: `1, 2, 3`
- middle block: `24, 25, 26`
- latest block: `47, 48, 49, 50`

This mirrors the approved example pattern:

- keep `1, 2, 3`
- keep the middle block
- keep the newest block

The policy intentionally preserves:

- the starting point
- a middle checkpoint
- the most recent history

### 9. Oversize protected set behavior

If cleanup reduces the archive to the protected 10-run shape and the archive is still larger than 500 MB, stop pruning and emit a warning in metadata or logs instead of violating the protected-set rule.

The protected oldest/middle/latest bands take priority over strict size reduction.

## Expected run lifecycle

For each successful visual review invocation:

1. load archive state
2. inspect the archived bank for cleanup conditions
3. if the archive is at 50 runs or above 500 MB, prune archived runs to the protected shape before creating the next run
4. allocate the next monotonic run number
5. create the new run folder name using run number and UTC timestamp
6. rebuild `latest/`
7. write latest screenshots using `__run-####` naming
8. write archived screenshots using full run identity naming
9. write or update `manifest.json`, `index.html`, and archive state metadata

## Testing requirements

Implementation is not complete until it is verified with both automated checks and a real workflow run.

Required verification:

- automated tests for naming, archive-state behavior, and cleanup policy
- verification that a successful visual run writes fresh screenshots inside the workspace
- verification that `latest/` and archived runs are both generated
- verification that latest filenames include the run number
- verification that archived filenames include run number and UTC timestamp identity
- verification that manifests reference the correct paths and metadata
- verification that manifests and gallery output are deterministically sorted
- verification that cleanup preserves complete runs rather than partial runs

## Out of scope

This design does not add screenshot diffing, golden comparison review, or regression baselining.

This workflow remains strictly focused on generating fresh UI inspection artifacts.