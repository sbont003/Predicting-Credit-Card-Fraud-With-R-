# Data validation for credit-card fraud CSV

validate_credit_card_data <- function(data) {
  required <- c("Time", "Amount", "Class", paste0("V", 1:28))
  missing_cols <- setdiff(required, names(data))
  if (length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
  }

  stopifnot(nrow(data) > 0)
  stopifnot(all(data$Class %in% c(0, 1)))
  stopifnot(all(data$Amount >= 0, na.rm = TRUE))

  n_missing <- sum(!complete.cases(data[, required]))
  fraud_rate <- mean(data$Class == 1)

  list(
    ok = TRUE,
    n_rows = nrow(data),
    n_cols = ncol(data),
    incomplete_rows = n_missing,
    fraud_count = sum(data$Class == 1),
    legit_count = sum(data$Class == 0),
    fraud_rate = fraud_rate,
    duplicate_rows = sum(duplicated(data))
  )
}
