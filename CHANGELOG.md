# Changelog

## Default correction - 2026-09-22

- Designated MTD probabilities are now 0.30 at all in-range default states.
- Dose 4 defaults to (0.05, 0.10, 0.20, 0.30).
- Regenerated the app's 500-trial saved analysis and all 10,000-trial documentation comparisons.
- Added standalone reproducible experimental-analysis code; it remains outside the app.
- No new archived release. Existing archives predate these corrected defaults.

## 1.1.0 - 2026-09-22

- Shared customizable dose count (2-10) and starting dose.
- Dose-specific BOLD prior means, PESS, toxicity cutoffs, and stopping limits.
- Explicit BOIN matched-stability versus standard stopping modes.
- Scenario and exported parameter handling for configurable dose counts.
- Six regression test suites for the added controls and engine inputs.
- General-use instructions followed by a CD229 CAR-T example, selected upper-dose figure, and complete six-scenario results with safety trade-offs.
- Experimental BOLD remains separate from the interactive app.
