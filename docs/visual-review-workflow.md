# Visual Review Workflow

This repo now has a repeatable screenshot-based UI review loop.

## What it covers

The canonical visual baseline lives in `test/visual/visual_review_golden_test.dart` and captures:

- app startup with the dev-user picker
- signed-in shell tabs: Discover, Matches, Chats, Profile, and Settings
- a populated conversation thread

The reference baseline images live in `test/visual/goldens/`.
Each run also writes a fresh screenshot set to `build/visual_review/latest/`.

## How to run the workflow

Run the visual suite normally:

```bash
flutter test test/visual/visual_review_golden_test.dart
```

Every run now:

- clears and recreates `build/visual_review/latest/`
- writes a fresh PNG for every covered screen
- writes `build/visual_review/latest/manifest.json` with the captured files
- compares the rendered UI against the baseline goldens in `test/visual/goldens/`
- loads real Material/Roboto fonts for `test/visual` via `test/visual/flutter_test_config.dart`

Even if the golden comparison fails, the fresh files in `build/visual_review/latest/` are still written first, so the newest screenshots remain available for review and debugging.

This means the review images the agent inspects are always newly rendered, even when the baseline goldens are unchanged.

If a golden comparison fails, Flutter may also emit diff/debug files under `test/visual/failures/`. Those are transient diagnostics and should not be treated as the primary review artifact.

## How to refresh baseline goldens

Run the golden suite and regenerate PNGs when the UI changes:

```bash
flutter test test/visual/visual_review_golden_test.dart --update-goldens
```

Then inspect the updated PNGs in `test/visual/goldens/` before merging.

The run will still emit a fresh set of review screenshots under `build/visual_review/latest/`.

## What to look for

When reviewing screenshots, check for:

- clipped or overflowing text
- awkward spacing at phone widths
- broken hierarchy in the hero cards
- bottom navigation alignment
- message thread readability

## Notes

- The screenshots are intentionally phone-sized so the app can be reviewed at a realistic mobile width.
- `build/visual_review/latest/` is disposable run output for AI/human review; `test/visual/goldens/` remains the regression baseline directory.
- `test/visual/flutter_test_config.dart` loads Material icons and Roboto from the local Flutter SDK cache so the screenshots use real UI text and icons instead of the default test font.
- For live interactive review, you can still run the app in Chrome or on an emulator, but the golden files are the repeatable baseline.
