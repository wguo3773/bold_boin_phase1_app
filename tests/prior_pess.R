source("R/scenarios.R")
source("R/bold_engine.R")
source("R/boin_engine.R")
source("R/analysis_utils.R")

p <- bold_prior_parameters(.30, c(3, 3, 3, 6), 4)
stopifnot(isTRUE(all.equal(p$alpha, c(.9, .9, .9, 1.8))),
  isTRUE(all.equal(p$beta, c(2.1, 2.1, 2.1, 4.2))))
p <- bold_prior_parameters(c(.1, .15, .2, .3), c(2, 3, 4, 6), 4)
stopifnot(isTRUE(all.equal(p$alpha, c(.2, .45, .8, 1.8))),
  isTRUE(all.equal(p$beta, c(1.8, 2.55, 3.2, 4.2))))
for (j in c(2L, 4L, 10L)) {
  s <- default_scenarios(j)
  a <- run_all_scenarios(s, n_trial = 10L)
  b <- run_all_scenarios(s, n_trial = 10L, pess = rep(3, j))
  stopifnot(identical(a$detail, b$detail))
  custom <- run_all_scenarios(s, n_trial = 10L, pess = seq_len(j) + 1)
  stopifnot(identical(custom$parameters$pess, seq_len(j) + 1))
  for (state in s$scenario) {
    key <- paste(state, "BOIN", sep = "::")
    stopifnot(identical(a$detail[[key]], custom$detail[[key]]))
  }
}
for (bad in list(0, -1, NA_real_, Inf, c(3, 6), c(3, 3, NA, 6))) {
  stopifnot(inherits(try(bold_prior_parameters(.3, bad, 4), silent = TRUE), "try-error"))
}
cat("Dose-specific PESS checks passed.\n")
