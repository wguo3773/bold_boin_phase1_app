# Bayesian Ordered Lattice Design (BOLD) Phase I Trial Simulator

Authors: **Wanru Guo, Gi-Ming Wang, and Curtis Tatsuoka**

[Public Shiny app](https://wguo3.shinyapps.io/bold_boin_phase1_app/) | [Methods audit](METHODS_AUDIT.md)

Independent research software for BOLD, BOIN and iBOIN simulations. This is **not an official authors' or MD Anderson app**, and is not a validated clinical dose-assignment system. No real patient data are required.

**September 23 development update:** nine protocol scenarios and an independent iBOIN implementation are being validated. The public app and existing Zenodo archive may still contain the preceding version; see the publication status in the methods audit.

## General use

1. Choose the number of doses (2-10), starting dose, scenarios and methods. Four-dose defaults use the protocol scenarios below. Other dose counts use illustrative editable scenarios.
2. Enter nondecreasing true DLT probabilities. These generate simulated outcomes; the methods do not know them. They are different from prior means.
3. Set the target DLT probability, cohort size, total patient maximum, per-dose stopping limit, toxicity cutoff, trial count and seed. The matched stopping rule requires reaching the dose limit **and** recommending that same dose again.
4. Set BOLD's tau, prior means and PESS. Checked dose-specific controls override the corresponding common BOLD values. BOIN/iBOIN retain the shared cutoff and stopping limit.
5. For iBOIN, set its separate prior means and **integer PESS**, optionally by dose. Prior means default to the target, PESS to 3. Its final-selection prior option defaults to on. BOIN has no favored-dose prior. iBOIN PESS 0 at every dose reduces to the implemented BOIN rules.
6. Optionally include BOLD-exp: **constant tau 0.49**, with all other BOLD settings unchanged. This replaces the older experimental rule that changed Dose 1's cutoff and switched tau after a DLT. It is a research sensitivity analysis, not the published BOLD method.
7. Run the comparison. Review the named endpoint, MCSE, full selection distribution, patient allocation, DLT count and overdose allocation. Download the CSV bundle for inputs and outputs. Edited inputs do not change an already displayed result until rerun.

With defaults, BOLD's prior is Beta(0.9,2.1): prior mean 0.30 and PESS 3. Favoring a dose by increasing PESS does not change the actual cohort size. These are weak priors, not an absence of prior information.

### iBOIN implementation and safety

This repository implements the published prior-weight and decision-boundary equations, with prior-augmented final estimates, inverse-variance isotonic regression, and the BOIN tie convention. **The uniform Beta(1,1) safety check uses the selected shared cutoff at every dose, during allocation and at final selection.** Safety exclusions override final-selection priors. This is an explicit matched-safety implementation, not a claim of exact MD Anderson web-app equivalence.

Earlier official-web-app iBOIN results are **not reused as matched-0.90 results**. During verification, the app's decision table and simulation/final-selection behavior did not agree on safety handling. See the [audit](docs/IBOIN_VALIDATION.md). Exact flat truths are supported locally without perturbing their probabilities.

### Run locally

```r
install.packages(c("shiny", "bslib", "ggplot2", "Iso", "BOIN"))
shiny::runApp()
```

From the repository directory, run tests and reproduce the protocol comparison:

```r
for (f in list.files("tests", pattern = "[.]R$", full.names = TRUE)) source(f)
source("docs/run_protocol.R")  # 10,000 trials per scenario and method
source("docs/plot_word_results.R") # rebuild all 13 Word-document charts
```

## CD229 CAR-T design example

These are **hypothetical protocol stress tests**, not CD229 toxicity estimates or clinical validation. The four dose levels are 0.5, 1, 2 and 4 million viable CAR-positive T cells/kg. Interest in a higher MTD is a design motivation, not evidence that higher doses are safe. Sentinel timing, delayed toxicity, efficacy and RP2D decisions are not modeled.

The app's default grid retains nine protocol scenarios, excluding Scenario 8. The complete historical Word-document charts below additionally include Scenario 8, with its separate non-MTD endpoints. Default target is 0.30.

| Scenario | Dose 1 | Dose 2 | Dose 3 | Dose 4 | Primary displayed endpoint |
|---|---:|---:|---:|---:|---|
| 1 | 0.30 | 0.40 | 0.50 | 0.60 | Select Dose 1 |
| 2 | 0.15 | 0.30 | 0.45 | 0.60 | Select Dose 2 |
| 3 | 0.05 | 0.15 | 0.30 | 0.45 | Select Dose 3 |
| 4 | 0.05 | 0.10 | 0.20 | 0.30 | Select Dose 4 |
| 5 | 0.05 | 0.10 | 0.15 | 0.20 | Select Dose 4 (highest available) |
| 6 | 0.45 | 0.55 | 0.65 | 0.75 | No dose recommendation |
| 7 | 0.15 | 0.20 | 0.25 | 0.30 | Select Dose 4 |
| 9 | 0.30 | 0.30 | 0.30 | 0.30 | Select any dose 1-4 (all at target) |
| 10 | 0.05 | 0.05 | 0.05 | 0.05 | Select any dose 1-4 (all below target) |

Scenarios 9 and 10 have **no unique true MTD**. Scenario 10's endpoint follows the requested any-dose metric; Dose 4 selection is also available in the full selection data. An above-range label never authorizes an untested Dose 5. Scenario 5's Dose 4 endpoint is a highest-available-dose convention. Do not compare different endpoint types as though they measured the same accuracy.

## All reported scenario results

All **13 result tables** from **ALL SCENARIOS.docx** are shown below as thin-bar charts, including every reported favored-dose setting. Expand each chart's table to see the exact percentages and MCSEs. No results have been rerun or substituted.

These are historical reported values, not outputs of the independent local iBOIN engine. Official iBOIN safety equivalence to a uniform 0.90 cutoff remains unverified. iBOIN is unavailable for Scenarios 9 and 10; it is not represented as zero. BOIN is unchanged across prior settings within each scenario.

Bar labels show the exact source percentage; error bars show +/- 1.96 times the reported MCSE. Rounding is retained. These intervals are descriptive Monte Carlo intervals, not clinical uncertainty intervals.

Scenarios 1 and 2 contain no favored-Dose-4 row in the source; none has been invented. Scenario 8 is included here to reproduce ALL source results, but is not an MTD-accuracy scenario. Its above-target-selection endpoint is undesirable, so lower is better. For Scenario 10, any-dose selection is not target-dose accuracy: all doses are below target.

The source's Scenario 8 iBOIN selection distribution sums to 100.02% at its displayed precision; these values are retained without normalization. The source's narrative conclusions are not copied as instructions or treated as verified superiority claims.

[All source values (CSV)](docs/data/word_all_results.csv) | [Source provenance](docs/data/word_source.json) | [Separate independent local reruns](docs/data/protocol_performance.csv)

### Scenario 1: Select Dose 1

True DLT probabilities: **(0.30, 0.40, 0.50, 0.60)**.

![Scenario 1: Select Dose 1](docs/figures/word_01_scenario_1.png)

<details>
<summary>Exact source values: percentage (MCSE)</summary>

| Prior | BOIN | iBOIN | BOLD | BOLD-exp |
|---|---|---|---|---|
| No favored dose | 46.2 (0.50) | 54.7 (0.50) | 44.45 (0.50) | 51.23 (0.50) |
| Favor Dose 1 | 46.2 (0.50) | 54.9 (0.50) | 49.65 (0.50) | 58.20 (0.49) |
| Favor Dose 2 | 46.2 (0.50) | 52.3 (0.50) | 41.98 (0.49) | 48.81 (0.50) |
| Favor Dose 3 | 46.2 (0.50) | 54.7 (0.50) | 44.84 (0.50) | 51.23 (0.50) |

</details>

### Scenario 2: Select Dose 2

True DLT probabilities: **(0.15, 0.30, 0.45, 0.60)**.

![Scenario 2: Select Dose 2](docs/figures/word_02_scenario_2.png)

<details>
<summary>Exact source values: percentage (MCSE)</summary>

| Prior | BOIN | iBOIN | BOLD | BOLD-exp |
|---|---|---|---|---|
| No favored dose | 43.5 (0.50) | 47.5 (0.50) | 49.48 (0.50) | 48.89 (0.50) |
| Favor Dose 1 | 43.5 (0.50) | 49.4 (0.50) | 48.41 (0.50) | 48.69 (0.50) |
| Favor Dose 2 | 43.5 (0.50) | 53.6 (0.50) | 56.01 (0.50) | 56.76 (0.50) |
| Favor Dose 3 | 43.5 (0.50) | 47.4 (0.50) | 47.68 (0.50) | 46.15 (0.50) |

</details>

### Scenario 3: Select Dose 3

True DLT probabilities: **(0.05, 0.15, 0.30, 0.45)**.

![Scenario 3: Select Dose 3](docs/figures/word_03_scenario_3.png)

<details>
<summary>Exact source values: percentage (MCSE)</summary>

| Prior | BOIN | iBOIN | BOLD | BOLD-exp |
|---|---|---|---|---|
| No favored dose | 39.7 (0.49) | 50.5 (0.50) | 51.10 (0.50) | 51.94 (0.50) |
| Favor Dose 1 | 39.7 (0.49) | 46.5 (0.50) | 49.03 (0.50) | 48.01 (0.50) |
| Favor Dose 2 | 39.7 (0.49) | 45.4 (0.50) | 46.64 (0.50) | 46.98 (0.50) |
| Favor Dose 3 | 39.7 (0.49) | 52.0 (0.50) | 57.19 (0.49) | 59.15 (0.49) |
| Favor Dose 4 | 39.7 (0.49) | 49.4 (0.50) | 49.85 (0.50) | 48.76 (0.50) |

</details>

### Scenario 4: Select Dose 4

True DLT probabilities: **(0.05, 0.10, 0.20, 0.30)**.

![Scenario 4: Select Dose 4](docs/figures/word_04_scenario_4.png)

<details>
<summary>Exact source values: percentage (MCSE)</summary>

| Prior | BOIN | iBOIN | BOLD | BOLD-exp |
|---|---|---|---|---|
| No favored dose | 51.1 (0.50) | 52.6 (0.50) | 60.17 (0.49) | 56.80 (0.50) |
| Favor Dose 1 | 51.1 (0.50) | 52.6 (0.50) | 59.30 (0.49) | 56.05 (0.50) |
| Favor Dose 2 | 51.1 (0.50) | 52.6 (0.50) | 58.83 (0.49) | 55.50 (0.50) |
| Favor Dose 3 | 51.1 (0.50) | 50.9 (0.50) | 53.72 (0.50) | 51.69 (0.50) |
| Favor Dose 4 | 51.1 (0.50) | 53.8 (0.50) | 62.03 (0.49) | 60.02 (0.49) |

</details>

### Scenario 5: Select Dose 4 (highest available)

True DLT probabilities: **(0.05, 0.10, 0.15, 0.20)**.

![Scenario 5: Select Dose 4 (highest available)](docs/figures/word_05_scenario_5.png)

<details>
<summary>Exact source values: percentage (MCSE)</summary>

| Prior | BOIN | iBOIN | BOLD | BOLD-exp |
|---|---|---|---|---|
| No favored dose | 69.0 (0.46) | 70.5 (0.46) | 82.35 (0.38) | 74.32 (0.44) |
| Favor Dose 1 | 69.0 (0.46) | 70.5 (0.46) | 80.44 (0.40) | 73.21 (0.44) |
| Favor Dose 2 | 69.0 (0.46) | 70.5 (0.46) | 80.80 (0.39) | 72.93 (0.44) |
| Favor Dose 3 | 69.0 (0.46) | 69.6 (0.46) | 77.89 (0.41) | 71.21 (0.45) |
| Favor Dose 4 | 69.0 (0.46) | 71.2 (0.45) | 83.39 (0.37) | 76.04 (0.43) |

</details>

### Scenario 6: No dose recommended

True DLT probabilities: **(0.45, 0.55, 0.65, 0.75)**.

![Scenario 6: No dose recommended](docs/figures/word_06_scenario_6.png)

<details>
<summary>Exact source values: percentage (MCSE)</summary>

| Prior | BOIN | iBOIN | BOLD | BOLD-exp |
|---|---|---|---|---|
| No favored dose | 61.7 (0.49) | 53.15 (0.50) | 41.55 (0.49) | 43.65 (0.50) |
| Favor Dose 1 | 61.7 (0.49) | 53.15 (0.50) | 35.10 (0.48) | 36.95 (0.48) |
| Favor Dose 2 | 61.7 (0.49) | 53.15 (0.50) | 41.72 (0.49) | 43.65 (0.50) |
| Favor Dose 3 | 61.7 (0.49) | 53.15 (0.50) | 41.55 (0.49) | 43.65 (0.50) |
| Favor Dose 4 | 61.7 (0.49) | 53.15 (0.50) | 41.55 (0.49) | 43.65 (0.50) |

</details>

### Scenario 7: Select Dose 4 (shallow gradient)

True DLT probabilities: **(0.15, 0.20, 0.25, 0.30)**.

![Scenario 7: Select Dose 4 (shallow gradient)](docs/figures/word_07_scenario_7.png)

<details>
<summary>Exact source values: percentage (MCSE)</summary>

| Prior | BOIN | iBOIN | BOLD | BOLD-exp |
|---|---|---|---|---|
| No favored dose | 29.0 (0.45) | 28.8 (0.45) | 46.20 (0.50) | 32.72 (0.47) |
| Favor Dose 1 | 29.0 (0.45) | 28.8 (0.45) | 45.02 (0.50) | 32.13 (0.47) |
| Favor Dose 2 | 29.0 (0.45) | 28.8 (0.45) | 45.30 (0.50) | 32.22 (0.47) |
| Favor Dose 3 | 29.0 (0.45) | 28.1 (0.45) | 41.18 (0.49) | 29.75 (0.46) |
| Favor Dose 4 | 29.0 (0.45) | 29.7 (0.46) | 47.93 (0.50) | 34.90 (0.48) |

</details>

### Scenario 8: Selection distribution (no favored dose)

True DLT probabilities: **(0.05, 0.10, 0.45, 0.60)**.

![Scenario 8: Selection distribution (no favored dose)](docs/figures/word_08_scenario_8.png)

<details>
<summary>Exact source values: percentage (MCSE)</summary>

| Method | No dose | Dose 1 | Dose 2 | Dose 3 | Dose 4 |
|---|---|---|---|---|---|
| BOIN | 0.70 (0.08) | 3.40 (0.18) | 57.30 (0.49) | 33.60 (0.47) | 5.00 (0.22) |
| iBOIN | 0.02 (0.01) | 0.80 (0.09) | 44.30 (0.50) | 50.00 (0.50) | 4.90 (0.22) |
| BOLD | 0.00 (0.00) | 0.68 (0.08) | 49.19 (0.50) | 45.43 (0.50) | 4.70 (0.21) |
| BOLD-exp | 0.03 (0.02) | 0.46 (0.07) | 49.66 (0.50) | 44.18 (0.50) | 5.67 (0.23) |

</details>

### Scenario 8: Above-target selection (Dose 3 or 4)

True DLT probabilities: **(0.05, 0.10, 0.45, 0.60)**.

![Scenario 8: Above-target selection (Dose 3 or 4)](docs/figures/word_09_scenario_8.png)

<details>
<summary>Exact source values: percentage (MCSE)</summary>

| Prior | BOIN | iBOIN | BOLD | BOLD-exp |
|---|---|---|---|---|
| No favored dose | 38.60 (0.49) | 54.90 (0.50) | 50.13 (0.50) | 49.85 (0.50) |
| Favor Dose 1 | 38.60 (0.49) | 48.20 (0.50) | 46.00 (0.50) | 44.45 (0.50) |
| Favor Dose 2 | 38.60 (0.49) | 45.30 (0.50) | 41.87 (0.49) | 44.79 (0.50) |
| Favor Dose 3 | 38.60 (0.49) | 54.90 (0.50) | 54.30 (0.50) | 59.83 (0.49) |
| Favor Dose 4 | 38.60 (0.49) | 54.80 (0.50) | 50.16 (0.50) | 49.85 (0.50) |

</details>

### Scenario 9: Selection distribution (no favored dose)

True DLT probabilities: **(0.30, 0.30, 0.30, 0.30)**.

![Scenario 9: Selection distribution (no favored dose)](docs/figures/word_10_scenario_9.png)

<details>
<summary>Exact source values: percentage (MCSE)</summary>

| Method | No dose | Dose 1 | Dose 2 | Dose 3 | Dose 4 |
|---|---|---|---|---|---|
| BOIN | 27.12 (0.44) | 33.81 (0.47) | 16.77 (0.37) | 12.22 (0.33) | 10.08 (0.30) |
| BOLD | 10.51 (0.31) | 24.37 (0.43) | 18.59 (0.39) | 17.91 (0.38) | 28.62 (0.45) |
| BOLD-exp | 12.66 (0.33) | 37.90 (0.49) | 20.60 (0.40) | 17.23 (0.38) | 11.61 (0.32) |

</details>

### Scenario 9: Select any dose 1-4 (all at target)

True DLT probabilities: **(0.30, 0.30, 0.30, 0.30)**.

![Scenario 9: Select any dose 1-4 (all at target)](docs/figures/word_11_scenario_9.png)

<details>
<summary>Exact source values: percentage (MCSE)</summary>

| Prior | BOIN | BOLD | BOLD-exp |
|---|---|---|---|
| No favored dose | 72.88 (0.44) | 89.49 (0.31) | 87.34 (0.33) |
| Favor Dose 1 | 72.88 (0.44) | 91.72 (0.28) | 90.10 (0.30) |
| Favor Dose 2 | 72.88 (0.44) | 89.32 (0.31) | 87.34 (0.33) |
| Favor Dose 3 | 72.88 (0.44) | 89.49 (0.31) | 87.34 (0.33) |
| Favor Dose 4 | 72.88 (0.44) | 89.49 (0.31) | 87.34 (0.33) |

</details>

### Scenario 10: Select Dose 4 (highest available)

True DLT probabilities: **(0.05, 0.05, 0.05, 0.05)**.

![Scenario 10: Select Dose 4 (highest available)](docs/figures/word_12_scenario_10.png)

<details>
<summary>Exact source values: percentage (MCSE)</summary>

| Prior | BOIN | BOLD τ=.50 | BOLD-exp τ=.49 |
|---|---|---|---|
| No favored dose | 94.75 (0.22) | 98.99 (0.10) | 96.22 (0.19) |
| Favor Dose 1 | 94.75 (0.22) | 98.60 (0.12) | 95.89 (0.20) |
| Favor Dose 2 | 94.75 (0.22) | 98.65 (0.12) | 95.91 (0.20) |
| Favor Dose 3 | 94.75 (0.22) | 98.78 (0.11) | 96.08 (0.19) |
| Favor Dose 4 | 94.75 (0.22) | 99.06 (0.10) | 96.31 (0.19) |

</details>

### Scenario 10: Select any dose 1-4 (all below target)

True DLT probabilities: **(0.05, 0.05, 0.05, 0.05)**.

![Scenario 10: Select any dose 1-4 (all below target)](docs/figures/word_13_scenario_10.png)

<details>
<summary>Exact source values: percentage (MCSE)</summary>

| Prior | BOIN | BOLD τ=.50 | BOLD-exp τ=.49 |
|---|---|---|---|
| No favored dose | 99.19 (0.09) | 100.00 (0.00) | 99.99 (0.01) |
| Favor Dose 1 | 99.19 (0.09) | 99.99 (0.01) | 99.98 (0.01) |
| Favor Dose 2 | 99.19 (0.09) | 100.00 (0.00) | 99.99 (0.01) |
| Favor Dose 3 | 99.19 (0.09) | 100.00 (0.00) | 99.99 (0.01) |
| Favor Dose 4 | 99.19 (0.09) | 100.00 (0.00) | 99.99 (0.01) |

</details>

### Outcome definitions

- Selection endpoint: number of trials meeting the table's endpoint divided by simulated trials.
- MCSE (percentage points): `100 * sqrt(p * (1-p) / R)`.
- Mean N and SD N: mean and sample SD of enrolled patients across trials.
- Mean DLTs: average observed DLT count per trial.
- Overdose allocation: total patients assigned to doses with **true DLT probability above the target**, divided by total patients across simulations. It is not the DLT rate or the fraction of trials selecting an excessive dose.

## Sources and citation

- [BOLD methods paper](https://doi.org/10.1002/sim.70456) and [authors' code](https://github.com/hiddenmanna1996/BOLD).
- [BOIN R package](https://cran.r-project.org/package=BOIN).
- [iBOIN methods: Zhou et al.](https://arxiv.org/abs/2004.12972).
- [Official iBOIN app](https://biostatistics.mdanderson.org/shinyapps/iBOIN/) and [prior-based final-selection guide](https://biostatistics.mdanderson.org/shinyapps/iBOIN/iBOINprior_for_MTD.pdf).

Guo W, Wang G-M, Tatsuoka C. *Bayesian Ordered Lattice Design (BOLD) Phase I Trial Simulator*. Original archive: Zenodo; 2026. [doi:10.5281/zenodo.22867493](https://doi.org/10.5281/zenodo.22867493).

**The original DOI does not contain this update.** Until a new archive is published, cite this repository with the exact commit and access date for the changed software. Existing DOI-linked files are not silently replaced. Regulatory or clinical use requires independent statistical and code review.
