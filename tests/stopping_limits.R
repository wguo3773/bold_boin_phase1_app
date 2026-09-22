source("R/scenarios.R")
source("R/bold_engine.R")
source("R/boin_engine.R")
source("R/analysis_utils.R")

args <- list(true_dlt = rep(1e-12, 4), n_trial = 5L,
  n_stop_per_dose = 3L, keep_trials = TRUE)
standard <- do.call(simulate_boin_oc, c(args, list(require_stability = FALSE)))
matched <- do.call(simulate_boin_oc, c(args, list(require_stability = TRUE)))
stopifnot(all(standard$trials$total_n == 3L), all(matched$trials$total_n > 3L))

s <- default_scenarios()
baseline <- run_all_scenarios(s, n_trial = 5L)
explicit <- run_all_scenarios(s, n_trial = 5L,
  bold_stop_per_dose = rep(12L, 4), boin_require_stability = TRUE)
stopifnot(identical(baseline, explicit))
custom <- run_all_scenarios(s, n_trial = 5L, bold_stop_per_dose = c(15L, 6L, 9L, 12L))
stopifnot(identical(custom$parameters$bold_stop_per_dose, c(15L, 6L, 9L, 12L)))
for (state in s$scenario) {
  key <- paste(state, "BOIN", sep = "::")
  stopifnot(identical(baseline$detail[[key]], custom$detail[[key]]))
}
for (bad in list(c(3, 4), c(3, NA, 3, 3), 2.5, 0)) {
  stopifnot(inherits(try(run_all_scenarios(s, n_trial = 2L,
    bold_stop_per_dose = bad), silent = TRUE), "try-error"))
}
cat("Stopping-limit checks passed.\n")
