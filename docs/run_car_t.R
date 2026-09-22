# Run from the repository root. Experimental BOLD remains outside the app.
source("R/scenarios.R")
source("R/bold_engine.R")
source("R/boin_engine.R")
source("R/analysis_utils.R")
experimental <- new.env(parent = globalenv())
sys.source("docs/experimental_bold_engine.R", envir = experimental)
scenarios <- default_scenarios()
result <- run_all_scenarios(scenarios, n_trial = 10000L, seed = 20260920L)
d <- result$summary
d$method[d$method == "BOLD"] <- "Original BOLD"
for (i in seq_len(nrow(scenarios))) {
  state <- scenarios$scenario[i]
  message("Experimental BOLD scenario ", state)
  fit <- experimental$simulate_bold_oc(
    true_dlt = as.numeric(scenarios[i, paste0("dose_", 1:4)]),
    n_trial = 10000L, phi = .30, cohort_size = 3L, n_max = 18L,
    n_stop_per_dose = 12L, gamma = c(.85, .90, .90, .90),
    tau = .50, tau_after_dlt = .49, pess = 3, true_state = state,
    seed = 20260920L + i * 1000L, keep_trials = FALSE)
  d <- rbind(d, data.frame(scenario = state, method = "Experimental BOLD",
    accuracy_pct = 100 * fit$accuracy,
    accuracy_mcse_pct = 100 * sqrt(fit$accuracy * (1 - fit$accuracy) / 10000),
    mean_patients = fit$mean_n, sd_patients = fit$sd_n,
    mean_dlts = fit$mean_dlt, overdose_pct = 100 * fit$overdose_rate))
}
d$true_dlt <- vapply(d$scenario, function(s) paste(sprintf("%.2f",
  as.numeric(scenarios[scenarios$scenario == s, paste0("dose_", 1:4)])), collapse = ", "), character(1))
d$rule <- ifelse(d$method == "Experimental BOLD", "gamma1=.85, others=.90; tau=.50 then .49 after any DLT",
  ifelse(d$method == "Original BOLD", "gamma=.90 all doses; tau=.50; Beta(.9,2.1)", "gamma=.90 all doses"))
d <- d[order(match(d$scenario, scenarios$scenario), match(d$method,
  c("Original BOLD", "Experimental BOLD", "BOIN"))), ]
write.csv(d, "docs/data/car_t_six_scenarios.csv", row.names = FALSE)
source("docs/plot_car_t.R")
print(d[, c("scenario", "method", "accuracy_pct", "overdose_pct")], row.names = FALSE)
