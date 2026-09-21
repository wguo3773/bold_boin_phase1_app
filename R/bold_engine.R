choose_tied_dose <- function(loss, ppat, tau) {
  tied <- which(loss == min(loss, na.rm = TRUE))
  if (length(tied) == 1L) {
    return(tied)
  }

  # This follows the tie rule in the published BOLD application:
  # favor the higher dose when all tied PPATs are below tau; otherwise
  # favor the lower dose.
  if (ppat[tied[1]] < tau) max(tied) else min(tied)
}

run_bold_trial <- function(
    true_dlt,
    phi = 0.30,
    cohort_size = 3L,
    n_max = 18L,
    n_stop_per_dose = 12L,
    gamma = 0.90,
    tau = 0.50,
    pess = 3,
    start_dose = 1L) {
  stopifnot(
    length(true_dlt) >= 2L,
    all(diff(true_dlt) >= 0),
    all(true_dlt > 0 & true_dlt < 1),
    cohort_size > 0,
    n_max >= cohort_size
  )

  j_max <- length(true_dlt)
  alpha <- rep(phi * pess, j_max)
  beta <- rep((1 - phi) * pess, j_max)
  gamma <- rep_len(gamma, j_max)
  n_stop_per_dose <- rep_len(n_stop_per_dose, j_max)

  current <- as.integer(start_dose)
  n <- integer(j_max)
  x <- integer(j_max)
  excluded <- rep(FALSE, j_max)
  stop_reason <- NA_character_

  repeat {
    cohort_dlt <- stats::rbinom(1L, cohort_size, true_dlt[current])
    n[current] <- n[current] + cohort_size
    x[current] <- x[current] + cohort_dlt

    cpat <- 1 - stats::pbeta(
      phi,
      shape1 = alpha + x,
      shape2 = beta + n - x
    )

    # Local PAVA: only current dose and immediate neighbors influence the
    # next-dose decision, matching the published single-agent implementation.
    local_cpat <- cpat
    if (current > 2L) local_cpat[seq_len(current - 2L)] <- 0
    if (current < j_max - 1L) {
      local_cpat[seq.int(current + 2L, j_max)] <- 100
    }
    ppat <- round(Iso::pava(local_cpat, w = n, decreasing = FALSE), 3)

    toxic_index <- which(cpat >= gamma)
    if (length(toxic_index)) {
      excluded[min(toxic_index):j_max] <- TRUE
    }

    candidates <- intersect(
      seq.int(max(1L, current - 1L), min(j_max, current + 1L)),
      which(!excluded)
    )

    if (!length(candidates)) {
      chosen <- current
    } else {
      loss <- rep(Inf, j_max)
      loss[candidates] <- abs(ppat[candidates] - tau)
      chosen <- choose_tied_dose(loss, ppat, tau)
    }

    if (excluded[1]) {
      stop_reason <- "lowest dose overly toxic"
    } else if (sum(n) >= n_max) {
      stop_reason <- "maximum total sample size"
    } else if (
      n[current] >= n_stop_per_dose[current] &&
        chosen == current &&
        !excluded[current]
    ) {
      stop_reason <- "per-dose stability stopping rule"
    } else if (all(excluded)) {
      stop_reason <- "no selectable dose"
    }

    if (!is.na(stop_reason)) break
    current <- chosen
  }

  selected <- 0L
  if (!excluded[1]) {
    posterior_mean <- (alpha + x) / (alpha + beta + n)
    fitted_mean <- round(
      Iso::pava(posterior_mean, w = n, decreasing = FALSE),
      3
    )

    candidates <- seq.int(max(1L, current - 1L), min(j_max, current + 1L))
    candidates <- candidates[n[candidates] > 0 & !excluded[candidates]]

    if (length(candidates)) {
      distance <- abs(fitted_mean[candidates] - phi)
      tied <- candidates[distance == min(distance)]
      if (length(tied) == 1L) {
        selected <- tied
      } else if (fitted_mean[min(tied)] < phi) {
        # If both tied means are below target, choose the higher dose. If the
        # target lies between them, choose the lower dose.
        selected <- if (fitted_mean[max(tied)] < phi) max(tied) else min(tied)
      } else {
        selected <- min(tied)
      }
    }
  }

  list(
    selected = selected,
    allocation = n,
    toxicity = x,
    total_n = sum(n),
    total_dlt = sum(x),
    stop_reason = stop_reason
  )
}

simulate_bold_oc <- function(
    true_dlt,
    n_trial = 500L,
    phi = 0.30,
    cohort_size = 3L,
    n_max = 18L,
    n_stop_per_dose = 12L,
    gamma = 0.90,
    tau = 0.50,
    pess = 3,
    true_state = NULL,
    seed = 20260918L,
    keep_trials = FALSE) {
  set.seed(seed)
  j_max <- length(true_dlt)
  trial_rows <- vector("list", n_trial)

  for (i in seq_len(n_trial)) {
    fit <- run_bold_trial(
      true_dlt = true_dlt,
      phi = phi,
      cohort_size = cohort_size,
      n_max = n_max,
      n_stop_per_dose = n_stop_per_dose,
      gamma = gamma,
      tau = tau,
      pess = pess
    )
    trial_rows[[i]] <- data.frame(
      trial = i,
      selected = fit$selected,
      total_n = fit$total_n,
      total_dlt = fit$total_dlt,
      stop_reason = fit$stop_reason,
      t(stats::setNames(fit$allocation, paste0("n_dose", seq_len(j_max)))),
      check.names = FALSE
    )
  }

  trials <- do.call(rbind, trial_rows)
  selection <- tabulate(trials$selected + 1L, nbins = j_max + 1L) / n_trial
  names(selection) <- c("No MTD", paste0("Dose ", seq_len(j_max)))
  allocation_cols <- paste0("n_dose", seq_len(j_max))
  allocation <- colMeans(trials[, allocation_cols, drop = FALSE])

  if (is.null(true_state)) {
    true_state <- which.min(abs(true_dlt - phi))
  }
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
    rowSums(trials[, paste0("n_dose", seq.int(true_mtd_number + 1L, j_max)), drop = FALSE])
  } else {
    rep(0, n_trial)
  }
  trial_overdose_rate <- overdose_n / trials$total_n

  summary <- list(
    method = "BOLD",
    accuracy = unname(accuracy),
    selection = selection,
    allocation = allocation,
    mean_n = mean(trials$total_n),
    sd_n = stats::sd(trials$total_n),
    mean_dlt = mean(trials$total_dlt),
    overdose_rate = sum(overdose_n) / sum(trials$total_n),
    trial_overdose_sd = stats::sd(trial_overdose_rate),
    stop_reasons = prop.table(table(trials$stop_reason)),
    trials = if (keep_trials) trials else NULL
  )
  summary
}
