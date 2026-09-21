run_all_scenarios <- function(
    scenarios,
    phi = 0.30,
    cohort_size = 3L,
    n_max = 18L,
    n_stop_per_dose = 12L,
    gamma = 0.90,
    tau = 0.50,
    pess = 3,
    n_trial = 500L,
    seed = 20260918L,
    methods = c("BOLD", "BOIN")) {
  validate_scenarios(scenarios, phi)
  methods <- intersect(methods, c("BOLD", "BOIN"))
  if (!length(methods)) stop("Choose BOLD, BOIN, or both.")

  detail <- list()
  for (i in seq_len(nrow(scenarios))) {
    state <- scenarios$scenario[i]
    true_dlt <- as.numeric(scenarios[i, paste0("dose_", 1:4)])
    scenario_seed <- seed + i * 1000L

    if ("BOLD" %in% methods) {
      detail[[paste(state, "BOLD", sep = "::")]] <- simulate_bold_oc(
        true_dlt = true_dlt,
        n_trial = n_trial,
        phi = phi,
        cohort_size = cohort_size,
        n_max = n_max,
        n_stop_per_dose = n_stop_per_dose,
        gamma = gamma,
        tau = tau,
        pess = pess,
        true_state = state,
        seed = scenario_seed,
        keep_trials = TRUE
      )
    }
    if ("BOIN" %in% methods) {
      detail[[paste(state, "BOIN", sep = "::")]] <- simulate_boin_oc(
        true_dlt = true_dlt,
        n_trial = n_trial,
        phi = phi,
        cohort_size = cohort_size,
        n_max = n_max,
        n_stop_per_dose = n_stop_per_dose,
        gamma = gamma,
        true_state = state,
        seed = scenario_seed,
        keep_trials = TRUE
      )
    }
  }

  summary_rows <- list()
  selection_rows <- list()
  allocation_rows <- list()
  for (key in names(detail)) {
    parts <- strsplit(key, "::", fixed = TRUE)[[1]]
    state <- parts[1]
    fit <- detail[[key]]
    n_used <- nrow(fit$trials)

    summary_rows[[key]] <- data.frame(
      scenario = state,
      method = fit$method,
      accuracy_pct = 100 * fit$accuracy,
      accuracy_mcse_pct = 100 * sqrt(fit$accuracy * (1 - fit$accuracy) / n_used),
      mean_patients = fit$mean_n,
      sd_patients = fit$sd_n,
      mean_dlts = fit$mean_dlt,
      overdose_pct = 100 * fit$overdose_rate,
      stringsAsFactors = FALSE
    )

    selection_rows[[key]] <- data.frame(
      scenario = state,
      method = fit$method,
      selection = names(fit$selection),
      selection_pct = 100 * as.numeric(fit$selection),
      stringsAsFactors = FALSE
    )

    allocation_rows[[key]] <- data.frame(
      scenario = state,
      method = fit$method,
      dose = paste0("Dose ", seq_along(fit$allocation)),
      mean_patients = as.numeric(fit$allocation),
      stringsAsFactors = FALSE
    )
  }

  list(
    parameters = list(
      phi = phi,
      cohort_size = cohort_size,
      n_max = n_max,
      n_stop_per_dose = n_stop_per_dose,
      gamma = gamma,
      tau = tau,
      pess = pess,
      n_trial = n_trial,
      seed = seed
    ),
    scenarios = scenarios,
    summary = do.call(rbind, summary_rows),
    selection = do.call(rbind, selection_rows),
    allocation = do.call(rbind, allocation_rows),
    detail = detail
  )
}

format_result_tables <- function(result) {
  summary <- result$summary
  summary$accuracy_pct <- round(summary$accuracy_pct, 1)
  summary$accuracy_mcse_pct <- round(summary$accuracy_mcse_pct, 1)
  summary$mean_patients <- round(summary$mean_patients, 2)
  summary$sd_patients <- round(summary$sd_patients, 2)
  summary$mean_dlts <- round(summary$mean_dlts, 2)
  summary$overdose_pct <- round(summary$overdose_pct, 1)

  selection <- result$selection
  selection$selection_pct <- round(selection$selection_pct, 1)

  allocation <- result$allocation
  allocation$mean_patients <- round(allocation$mean_patients, 2)

  list(summary = summary, selection = selection, allocation = allocation)
}
