# Independent BOLD / BOIN Four-Dose Phase I Simulator

**Version 1.0.0**

Authors: Wanru Guo, Gi-Ming Wang, and Curtis Tatsuoka.

This reproducible Shiny app implements a four-dose operating-characteristic study:

- Target DLT rate `phi = 0.30`
- Four doses: 0.5, 1, 2, and 4 million viable CAR-positive T cells/kg
- Cohorts of 3, starting at Dose 1
- Maximum total sample size `N = 18`
- Stop when 12 participants have received the current dose and the next selection remains that dose
- BOLD toxicity threshold `gamma = 0.90` at every dose
- BOLD PPAT threshold `tau = 0.50`
- Non-informative Beta prior centered at `phi`, with PESS = 3
- 500 simulation trials per scenario

The BOLD implementation independently reproduces the single-agent simulation logic in Wang and Tatsuoka's published application for the four-dose configuration below. It is not a copy of their full app. The BOIN comparison uses the decision boundaries and final MTD selection implemented by the CRAN `BOIN` package; it is not the MD Anderson BOIN web app.

See [METHODS_AUDIT.md](METHODS_AUDIT.md) for the source versions, parity checks, and limits of validation.

## Start the app

Open RStudio in this folder and run:

```r
install.packages(c("shiny", "bslib", "ggplot2", "Iso", "BOIN"))
shiny::runApp()
```

Then use the **How to use** tab for the numbered click guide.

The six default true-DLT vectors are editable on the **Run simulation** tab when
"All six prespecified scenarios" is selected. To compare a single custom vector,
choose its true-MTD state and edit the four dose inputs. For example, the Dose-4
default is `(0.03, 0.05, 0.10, 0.25)`; change Dose 3 to `0.15` to run
`(0.03, 0.05, 0.15, 0.25)`. Click **Run comparison** after editing. The
**Scenario definitions** tab and CSV download show the inputs from the last
completed run, not unrun edits. Invalid or mislabeled true-MTD scenarios are
rejected before simulation.

## Publish a web link

For a public, simulation-only demonstration, obtain the appropriate study/institutional approval, create a shinyapps.io account,
connect that account in RStudio, and publish this `bold_boin_phase1_app` folder
with RStudio's **Publish** button. Or run:

```r
install.packages("rsconnect")
rsconnect::deployApp("/Users/wanru.guo/Documents/Codex/2026-06-24/this-is-the-p-5-first/bold_boin_phase1_app")
```

The app does not use patient-level data. Do not upload real patient data to a
public app. Publishing creates a separate hosted copy; the current
`127.0.0.1` link works only on this computer. Large simulation runs can be
slow or exceed hosted resource limits.

## Reproduce the saved analysis

```r
Rscript run_analysis.R
```

The command writes:

- `results/scenario_definitions.csv`
- `results/operating_characteristics.csv`
- `results/dose_selection_percentages.csv`
- `results/mean_patient_allocation.csv`
- `results/simulation_results.rds`

## Important interpretation

The scenario DLT rates are simulation assumptions, not real patient estimates. They must be approved before regulatory use. The paper defines upper delta as the gap to the dose above the MTD; the Dose-4 scenario uses a 0.15 gap to the dose below. The app states this distinction explicitly.

This app is research software for design evaluation based on the published BOLD
method and an independently implemented BOIN comparison. It is not affiliated
with or endorsed by the MD Anderson BOIN app team. It has not been independently
validated as a live clinical dose-assignment system.

## Sources

- Paper: <https://onlinelibrary.wiley.com/doi/full/10.1002/sim.70456>
- Authors' code: <https://github.com/hiddenmanna1996/BOLD>
- BOIN package: <https://cran.r-project.org/package=BOIN>
- MD Anderson BOIN app: <https://biostatistics.mdanderson.org/shinyapps/BOIN/>

## Citation

If you use this application, cite the archived software release and the BOLD
methods paper. Citation metadata are provided in [`CITATION.cff`](CITATION.cff).

Guo W, Wang G-M, Tatsuoka C. *BOLD/BOIN Research Simulator*. Version 1.0.0.
2026. <https://wguo3.shinyapps.io/bold_boin_phase1_app/>.

Wang G-M, Tatsuoka C. Bayesian Ordered Lattice Design for Phase I Clinical
Trials. *Statistics in Medicine*. 2026;45(6-7):e70456.
<https://doi.org/10.1002/sim.70456>.
