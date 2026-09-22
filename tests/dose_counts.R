# Run from the app directory: Rscript tests/dose_counts.R
source("R/scenarios.R")
source("R/bold_engine.R")
source("R/boin_engine.R")
source("R/analysis_utils.R")

for (j in c(2L, 4L, 5L, 10L)) {
  scenarios <- default_scenarios(j)
  validate_scenarios(scenarios)
  result <- run_all_scenarios(scenarios, n_trial = 10L)
  stopifnot(nrow(result$summary) == 2L * (j + 2L),
    nrow(result$allocation) == 2L * (j + 2L) * j,
    result$parameters$n_doses == j,
    all(is.finite(result$summary$accuracy_pct)))
  for (fit in result$detail) {
    allocations <- fit$trials[, paste0("n_dose", seq_len(j)), drop = FALSE]
    stopifnot(all(rowSums(allocations) == fit$trials$total_n))
  }
}
stopifnot(identical(as.numeric(default_scenarios()[5, 3:6]), c(.03, .05, .10, .25)))
for (bad in list(1, 2.5, 11, NA_real_)) {
  stopifnot(inherits(try(default_scenarios(bad), silent = TRUE), "try-error"))
}
cat("Dose-count regression checks passed.\n")
