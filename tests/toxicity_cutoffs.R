source("R/scenarios.R")
source("R/bold_engine.R")
source("R/boin_engine.R")
source("R/analysis_utils.R")
for (j in c(2L, 4L, 10L)) {
  s <- default_scenarios(j)
  baseline <- run_all_scenarios(s, n_trial = 10L)
  same <- run_all_scenarios(s, n_trial = 10L, bold_gamma = rep(.90, j))
  stopifnot(identical(baseline, same))
  cutoffs <- c(.85, rep(.95, j - 1L))
  custom <- run_all_scenarios(s, n_trial = 10L, bold_gamma = cutoffs)
  stopifnot(identical(custom$parameters$bold_gamma, cutoffs), custom$parameters$gamma == .90)
  for (state in s$scenario) {
    key <- paste(state, "BOIN", sep = "::")
    stopifnot(identical(baseline$detail[[key]], custom$detail[[key]]))
  }
}
# With near-certain DLTs, a high Dose 1 cutoff postpones exclusion.
set.seed(1)
a <- run_bold_trial(rep(1 - 1e-12, 4), gamma = c(.90, .95, .95, .95))
set.seed(1)
b <- run_bold_trial(rep(1 - 1e-12, 4), gamma = c(.999, .95, .95, .95))
stopifnot(a$total_n == 3, b$total_n > a$total_n)
for (bad in list(0, 1, NA_real_, c(.9, .95))) {
  stopifnot(inherits(try(run_all_scenarios(default_scenarios(),
    n_trial = 2L, bold_gamma = bad), silent = TRUE), "try-error"))
}
cat("Toxicity-cutoff checks passed.\n")
