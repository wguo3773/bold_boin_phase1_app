source("R/scenarios.R")
source("R/bold_engine.R")
source("R/boin_engine.R")
source("R/analysis_utils.R")

q <- c(.10, .15, .20, .30)
p <- bold_prior_parameters(q, 3, 4)
stopifnot(isTRUE(all.equal(p$alpha, c(.30, .45, .60, .90))),
  isTRUE(all.equal(p$beta, c(2.70, 2.55, 2.40, 2.10))))
for (j in c(2L, 4L, 10L)) {
  s <- default_scenarios(j)
  default <- run_all_scenarios(s, n_trial = 10L)
  explicit <- run_all_scenarios(s, n_trial = 10L, bold_prior_mean = rep(.30, j))
  stopifnot(identical(default, explicit))
  custom <- run_all_scenarios(s, n_trial = 10L, bold_prior_mean = seq(.10, .30, length.out = j))
  for (state in s$scenario) {
    key <- paste(state, "BOIN", sep = "::")
    stopifnot(identical(default$detail[[key]], custom$detail[[key]]))
  }
}
for (bad in list(c(.3, .2, .3, .3), c(.1, .2), c(0, .1, .2, .3),
                 c(.1, .2, .3, 1), c(.1, .2, NA, .3))) {
  stopifnot(inherits(try(bold_prior_parameters(bad, 3, 4), silent = TRUE), "try-error"))
}
cat("Prior-mean checks passed.\n")
