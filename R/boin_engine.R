simulate_boin_oc <- function(
    true_dlt,
    n_trial = 500L,
    phi = 0.30,
    cohort_size = 3L,
    n_max = 18L,
    n_stop_per_dose = 12L,
    gamma = 0.90,
    true_state = NULL,
    seed = 20260918L,
    keep_trials = FALSE,
    start_dose = 1L,
    require_stability = TRUE) {
  stopifnot(length(require_stability) == 1L, !is.na(require_stability), is.logical(require_stability),
    length(n_stop_per_dose) == 1L, is.finite(n_stop_per_dose),
    n_stop_per_dose >= 1, n_stop_per_dose == as.integer(n_stop_per_dose))
  if (length(start_dose) != 1L || !is.finite(start_dose) ||
      start_dose != as.integer(start_dose) || start_dose < 1L || start_dose > length(true_dlt)) {
    stop("Starting dose must be an integer within the available dose levels.")
  }
  if (!requireNamespace("BOIN", quietly = TRUE)) {
    stop("Install the BOIN package with install.packages('BOIN').")
  }
  if (n_max %% cohort_size != 0) {
    stop("For BOIN, n_max must be divisible by cohort_size.")
  }

  set.seed(seed)
  j_max <- length(true_dlt)
  n_cohort <- n_max / cohort_size
  p_safe <- 0.6 * phi
  p_toxic <- 1.4 * phi

  boundary <- BOIN::get.boundary(
    target = phi,
    ncohort = n_cohort,
    cohortsize = cohort_size,
    n.earlystop = n_max,
    p.saf = p_safe,
    p.tox = p_toxic,
    cutoff.eli = gamma,
    extrasafe = FALSE
  )$full_boundary_tab
  b_escalate <- boundary[2, ]
  b_deescalate <- boundary[3, ]
  b_eliminate <- boundary[4, ]

  allocation <- matrix(0L, nrow = n_trial, ncol = j_max)
  toxicity <- matrix(0L, nrow = n_trial, ncol = j_max)
  selected <- integer(n_trial)
  early_stop <- logical(n_trial)

  for (trial in seq_len(n_trial)) {
    y <- integer(j_max)
    n <- integer(j_max)
    current <- as.integer(start_dose)
    eliminated <- integer(j_max)

    for (cohort in seq_len(n_cohort)) {
      new_dlt <- stats::runif(cohort_size) < true_dlt[current]
      remaining <- min(cohort_size, n_max - sum(n))
      y[current] <- y[current] + sum(new_dlt[seq_len(remaining)])
      n[current] <- n[current] + remaining
      if (sum(n) >= n_max) break

      if (!is.na(b_eliminate[n[current]]) && y[current] >= b_eliminate[n[current]]) {
        eliminated[current:j_max] <- 1L
        if (current == 1L) {
          early_stop[trial] <- TRUE
          break
        }
      }

      stable_at_current <-
        (y[current] > b_escalate[n[current]] && y[current] < b_deescalate[n[current]]) ||
        (current == 1L && y[current] >= b_deescalate[n[current]]) ||
        ((current == j_max || eliminated[current + 1L] == 1L) && y[current] <= b_escalate[n[current]])
      if (n[current] >= n_stop_per_dose && (!require_stability || stable_at_current)) break

      if (y[current] <= b_escalate[n[current]] && current != j_max) {
        if (eliminated[current + 1L] == 0L) current <- current + 1L
      } else if (y[current] >= b_deescalate[n[current]] && current != 1L) {
        current <- current - 1L
      }
    }

    allocation[trial, ] <- n
    toxicity[trial, ] <- y
    if (early_stop[trial]) {
      selected[trial] <- 0L
    } else {
      final_selection <- BOIN::select.mtd(
        target = phi,
        npts = n,
        ntox = y,
        cutoff.eli = gamma,
        extrasafe = FALSE,
        boundMTD = FALSE,
        p.tox = p_toxic
      )$MTD
      selected[trial] <- if (final_selection %in% seq_len(j_max)) final_selection else 0L
    }
  }

  selection <- tabulate(selected + 1L, nbins = j_max + 1L) / n_trial
  names(selection) <- c("No MTD", paste0("Dose ", seq_len(j_max)))
  if (is.null(true_state)) true_state <- which.min(abs(true_dlt - phi))
  accuracy <- if (identical(true_state, "<1")) {
    selection[["No MTD"]]
  } else if (identical(true_state, paste0(">", j_max))) {
    selection[[paste0("Dose ", j_max)]]
  } else {
    selection[[paste0("Dose ", as.integer(true_state))]]
  }

  true_mtd_number <- suppressWarnings(as.integer(true_state))
  if (identical(true_state, "<1")) true_mtd_number <- 0L
  if (identical(true_state, paste0(">", j_max))) true_mtd_number <- j_max
  overdose_n <- if (true_mtd_number < j_max) {
    rowSums(allocation[, seq.int(true_mtd_number + 1L, j_max), drop = FALSE])
  } else {
    rep(0, n_trial)
  }
  total_n <- rowSums(allocation)
  trial_overdose_rate <- overdose_n / total_n

  trial_data <- data.frame(
    trial = seq_len(n_trial),
    selected = selected,
    total_n = total_n,
    total_dlt = rowSums(toxicity),
    stop_reason = ifelse(
      selected == 0L,
      ifelse(early_stop, "lowest dose elimination", "no MTD at final selection"),
      "other/end of trial"
    ),
    allocation,
    check.names = FALSE
  )
  names(trial_data)[6:(5 + j_max)] <- paste0("n_dose", seq_len(j_max))

  list(
    method = "BOIN",
    accuracy = unname(accuracy),
    selection = selection,
    allocation = stats::setNames(colMeans(allocation), paste0("n_dose", seq_len(j_max))),
    mean_n = mean(total_n),
    sd_n = stats::sd(total_n),
    mean_dlt = mean(rowSums(toxicity)),
    overdose_rate = sum(overdose_n) / sum(total_n),
    trial_overdose_sd = stats::sd(trial_overdose_rate),
    stop_reasons = prop.table(table(trial_data$stop_reason)),
    trials = if (keep_trials) trial_data else NULL
  )
}
