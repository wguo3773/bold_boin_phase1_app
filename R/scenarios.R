default_scenarios <- function() {
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
  dose_cols <- paste0("dose_", 1:4)
  if (!all(dose_cols %in% names(x))) stop("Scenario table needs dose_1 through dose_4.")
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
      stop("In state <1, all four true DLT rates must exceed the target.")
    }
    if (state == ">4" && !all(r < phi)) {
      stop("In state >4, all four true DLT rates must be below the target.")
    }
    if (state %in% as.character(1:4) &&
        (length(which(abs(r - phi) == min(abs(r - phi)))) != 1L ||
         which.min(abs(r - phi)) != as.integer(state))) {
      stop(sprintf("In state %s, Dose %s must be uniquely closest to the target DLT rate.", state, state))
    }
  }
  invisible(TRUE)
}
