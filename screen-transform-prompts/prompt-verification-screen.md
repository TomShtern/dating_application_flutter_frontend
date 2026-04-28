# Verification design refinement prompt

Target file: `lib/features/verification/verification_screen.dart`

Visual baseline: `visual_review/runs/run-0052__2026-04-27__21-20-26/verification__run-0052__2026-04-27__21-20-26.png`

The current screen already implements the earlier redesign: SectionIntroCard, step pill, progress bar, full-width CTA, trust section, and success-card treatment. Do not rework the screen from scratch.

## Preserve

- Keep the SectionIntroCard with `Verify your account`, badges, and step pill.
- Keep the progress indicator.
- Keep the Step 1 card structure: method segmented control, contact input, and full-width send-code CTA.
- Keep the `How it works` trust card.
- Keep all provider/model/API logic unchanged.
- Do not add more badges, extra trust claims, or invented verification capabilities.

## Requested refinements

1. Tighten the guided-flow rhythm.

The intro card, progress bar, Step 1 card, and trust card should feel like one connected guided flow. Adjust vertical spacing and grouping slightly so the progress bar does not feel detached between cards.

2. Improve Step 1 form grouping.

Keep the same controls, but make the segmented control, text field, and CTA feel more like a single action block. Use spacing and alignment only; do not change the verification flow or validation logic.

3. Keep the screen concise.

The current copy amount is about right. Prefer small layout and hierarchy improvements over adding new explanatory text.
