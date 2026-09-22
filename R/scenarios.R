default_scenarios <- function(n_doses = 4L) {
  if (length(n_doses) != 1L || !is.finite(n_doses) ||
      n_doses != as.integer(n_doses) || n_doses < 2 || n_doses > 10) {
    stop("Number of dose levels must be an integer from 2 to 10.")
  }
  if (n_doses != 4L) {
    states <- c("<1", as.character(seq_len(n_doses)), paste0(">", n_doses))
    rates <- t(vapply(0:(n_doses + 1L), function(k) {
      if (k == 0L) return(seq(0.45, 0.75, length.out = n_doses))
      if (k > n_doses) return(seq(0.03, 0.15, length.out = n_doses))
      lower <- if (k > 1L) 0.10 * 0.5^rev(seq_len(k - 1L) - 1L) else numeric()
      upper <- if (k < n_doses) seq(0.40, 0.80, length.out = n_doses - k) else numeric()
      pmax(0.001, c(lower, 0.25, upper))
    }, numeric(n_doses)))
    colnames(rates) <- paste0("dose_", seq_len(n_doses))
    return(data.frame(scenario = states,
      interpretation = c("All available doses are too toxic",
        paste("Dose", seq_len(n_doses), "is the true MTD"),
        "All available doses are below target"), rates, stringsAsFactors = FALSE))
  }
  data.frame(
    scenario = c("<1", "1", "2", "3", "4", ">4"),
    interpretation = c(
      "All available doses are too toxic",
      "Dose 1 is the true MTD",
      "Dose 2 is the true MTD",
      "Dose 3 is the true MTD",
      "Dose 4 is the true MTD",
      "All available doses are below target"
    ),
    dose_1 = c(0.45, 0.25, 0.10, 0.05, 0.03, 0.03),
    dose_2 = c(0.50, 0.40, 0.25, 0.10, 0.05, 0.05),
    dose_3 = c(0.55, 0.50, 0.40, 0.25, 0.10, 0.10),
    dose_4 = c(0.60, 0.60, 0.50, 0.40, 0.25, 0.15),
    stringsAsFactors = FALSE
  )
}

validate_scenarios <- function(x, phi = 0.30) {
  dose_cols <- grep("^dose_[0-9]+$", names(x), value = TRUE)
  n_doses <- length(dose_cols)
  if (n_doses < 2L || !identical(dose_cols, paste0("dose_", seq_len(n_doses)))) {
    stop("Scenario table needs consecutive dose columns starting with dose_1.")
  }
  rates <- as.matrix(x[, dose_cols, drop = FALSE])
  storage.mode(rates) <- "double"
  if (any(!is.finite(rates)) || any(rates <= 0 | rates >= 1)) {
    stop("Every true DLT rate must be between 0 and 1.")
  }
  if (any(apply(rates, 1, function(z) any(diff(z) < 0)))) {
    stop("True DLT rates must be non-decreasing across doses.")
  }
  for (i in seq_len(nrow(x))) {
    state <- x$scenario[i]
    r <- rates[i, ]
    if (state == "<1" && !all(r > phi)) {
      stop("In state <1, all true DLT rates must exceed the target.")
    }
    if (state == paste0(">", n_doses) && !all(r < phi)) {
      stop("In the above-range state, all true DLT rates must be below the target.")
    }
    if (!state %in% c("<1", as.character(seq_len(n_doses)), paste0(">", n_doses))) {
      stop("Scenario state does not match the number of doses.")
    }
    if (state %in% as.character(seq_len(n_doses)) &&
        (length(which(abs(r - phi) == min(abs(r - phi)))) != 1L ||
         which.min(abs(r - phi)) != as.integer(state))) {
      stop(sprintf("In state %s, Dose %s must be uniquely closest to the target DLT rate.", state, state))
    }
  }
  invisible(TRUE)
}
