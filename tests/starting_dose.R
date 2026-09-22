# Run from the app directory: Rscript tests/starting_dose.R
source("R/scenarios.R")
source("R/bold_engine.R")
source("R/boin_engine.R")
source("R/analysis_utils.R")

for (j in c(2L, 4L, 10L)) {
  s <- default_scenarios(j)
  for (start in unique(c(1L, 2L, j))) {
    result <- run_all_scenarios(s[s$scenario == as.character(j), ],
      n_trial = 4L, n_max = 3L, start_dose = start)
    stopifnot(result$parameters$start_dose == start)
    for (fit in result$detail) {
      stopifnot(all(fit$trials[[paste0("n_dose", start)]] == 3L),
        all(fit$trials$total_n == 3L))
    }
    full <- run_all_scenarios(s, n_trial = 3L, start_dose = start)
    stopifnot(all(is.finite(full$summary$accuracy_pct)))
  }
}
for (method in list(simulate_bold_oc, simulate_boin_oc)) {
  args <- list(true_dlt = c(.03, .05, .10, .25), n_trial = 4L, keep_trials = TRUE)
  stopifnot(identical(do.call(method, args), do.call(method, c(args, list(start_dose = 1L)))))
  for (bad in c(0, 5, 1.5, NA_real_)) {
    stopifnot(inherits(try(do.call(method, c(args, list(start_dose = bad))), silent = TRUE), "try-error"))
  }
}
cat("Starting-dose checks passed.\n")
