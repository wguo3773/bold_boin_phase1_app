# Methods and deployment audit

## Sources checked

- BOLD paper: <https://pmc.ncbi.nlm.nih.gov/articles/PMC12960292/>
- BOLD authors' R Markdown application: <https://github.com/hiddenmanna1996/BOLD>, commit `ac02d488fec3a3c18a1ed2039b367c8481fd377c`
- MD Anderson BOIN web app: <https://biostatistics.mdanderson.org/shinyapps/BOIN/>, version 3.0.20.0 (September 4, 2026)
- CRAN `BOIN` package used in local verification: version 2.7.2

## What was verified

The local BOLD simulator was compared with the authors' `my_function()` from their R Markdown source, using the same R random seed and 2,000 simulated trials for each of the six default four-dose true-DLT scenarios. Settings were target DLT 0.30, tau 0.50, prior effective sample size 3, toxicity threshold 0.90, cohort size 3, maximum N 18, and stable-dose stopping at N 12 for *every* dose. Selected-dose counts and per-trial total patient counts matched exactly in all six comparisons.

The local BOIN simulator was compared with `BOIN::get.oc()` from package version 2.7.2, again using identical seeds and 2,000 trials per scenario. Selected-dose percentages, mean allocation at each dose, mean total N, mean DLT count, and no-MTD frequency matched exactly in all six comparisons. This validates the local implementation against that package and those settings; it does not establish bit-for-bit equivalence to MD Anderson's separately maintained web app.

The default scenario probabilities are *assumptions for simulation*, not patient estimates or values taken from the BOLD paper. The stopping N of 12 at every dose and total N of 18 are study-specific inputs. The BOLD authors' app defaults differ (15 at the lowest dose, 12 elsewhere, total N 30), but its source supports the study-specific inputs tested here.

The local app reproduces operating-characteristic simulations only. It does not reproduce the authors' live-trial workflow, all BOLD dose lattices, informative priors, protocol generation, or every BOIN web-app option. The local overdose percentage is the share of simulated participants treated above the scenario's designated true MTD; it should not be conflated with other overdose metrics in the paper or BOIN app. The BOLD paper states a strict toxicity cutoff in prose; the authors' code uses `>= gamma`, which this app follows.

## Version 1.1.0 extension checks

The September 22, 2026 release adds variable dose count and starting dose,
dose-specific BOLD prior means, PESS, toxicity cutoffs and stopping limits.
Six regression suites in `tests/` passed, covering these inputs and equivalence
of shared settings to identical per-dose vectors. These tests extend, but do
not generalize, the earlier source-parity claims to every possible setting.
BOIN now exposes matched stable-dose stopping and standard stopping explicitly.
The earlier checks above describe the original tested configuration only.

The README's upper-dose figure comes from a separate saved analysis with a
revised Dose 4 vector. Experimental BOLD's dynamic tau rule is not in the app.
Complete six-scenario summary data are included to disclose the lower-dose
and overdose-allocation trade-offs.

## Publication status

This is an **independent research implementation**, not an official BOLD or MD Anderson BOIN app and not a validated clinical dose-assignment system. Before study or regulatory use, obtain study-team or institutional approval, confirm scenario and safety settings, and perform an independent statistical/code review. Public research hosting is configured at https://wguo3.shinyapps.io/bold_boin_phase1_app/.
