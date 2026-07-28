# Preprocessing: clean, engineer, split (before resampling)

preprocess_credit_card <- function(data) {
  data <- data[!duplicated(data), ]
  data$Class <- factor(data$Class, levels = c(0, 1), labels = c("legit", "fraud"))
  data$log_amount <- log1p(data$Amount)
  data$scaled_time <- as.numeric(scale(data$Time))
  data$scaled_amount <- as.numeric(scale(data$Amount))
  data
}

feature_columns <- function() {
  c(paste0("V", 1:28), "log_amount", "scaled_time", "scaled_amount")
}

split_data <- function(data, train_frac = 0.70, valid_frac = 0.15, seed = 42) {
  set.seed(seed)
  # Prefer time-ordered split when Time exists; otherwise stratified
  if ("Time" %in% names(data)) {
    ord <- order(data$Time)
    data <- data[ord, ]
    n <- nrow(data)
    n_train <- floor(train_frac * n)
    n_valid <- floor(valid_frac * n)
    train <- data[seq_len(n_train), ]
    valid <- data[(n_train + 1):(n_train + n_valid), ]
    test <- data[(n_train + n_valid + 1):n, ]
  } else {
    idx <- caret::createDataPartition(data$Class, p = train_frac, list = FALSE)
    train <- data[idx, ]
    rest <- data[-idx, ]
    idx2 <- caret::createDataPartition(rest$Class, p = valid_frac / (1 - train_frac), list = FALSE)
    valid <- rest[idx2, ]
    test <- rest[-idx2, ]
  }
  list(train = train, valid = valid, test = test)
}
