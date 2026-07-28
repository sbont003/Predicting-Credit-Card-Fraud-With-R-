# End-to-end fraud modeling pipeline

suppressPackageStartupMessages({
  library(dplyr)
})

root <- getwd()
if (!file.exists(file.path(root, "R", "utilities.R"))) {
  stop("Run this script from the project root")
}

source("R/utilities.R")
source("R/data_validation.R")
source("R/preprocessing.R")
source("R/class_balancing.R")
source("R/train_models.R")
source("R/evaluate_models.R")
source("R/explain_predictions.R")

ensure_dirs(root)
set_project_seed(42)

raw_path <- file.path(root, "data", "raw", "creditcard.csv")
if (!file.exists(raw_path)) {
  sample_path <- file.path(root, "data", "synthetic", "creditcard_sample.csv")
  if (file.exists(sample_path)) {
    message("Using bundled sample dataset: ", sample_path)
    dir.create(dirname(raw_path), showWarnings = FALSE, recursive = TRUE)
    file.copy(sample_path, raw_path, overwrite = TRUE)
  } else {
    message("Raw data missing; attempting download / synthetic generation...")
    source("scripts/download_data.R")
  }
}

message("Loading data...")
raw <- read.csv(raw_path)
# Optional subsample for faster local runs (set FULL_DATA=1 for full CSV)
if (!nzchar(Sys.getenv("FULL_DATA")) && nrow(raw) > 80000) {
  message("Subsampling to ~80k rows for faster MVP run (export FULL_DATA=1 for full dataset)")
  set.seed(42)
  fraud_idx <- which(raw$Class == 1)
  legit_idx <- sample(which(raw$Class == 0), size = min(80000 - length(fraud_idx), sum(raw$Class == 0)))
  raw <- raw[c(fraud_idx, legit_idx), ]
}

qa <- validate_credit_card_data(raw)
print(qa)

data <- preprocess_credit_card(raw)
splits <- split_data(data, train_frac = 0.70, valid_frac = 0.15, seed = 42)
message(sprintf(
  "Split sizes train/valid/test: %d / %d / %d | fraud rates: %.4f / %.4f / %.4f",
  nrow(splits$train), nrow(splits$valid), nrow(splits$test),
  mean(splits$train$Class == "fraud"),
  mean(splits$valid$Class == "fraud"),
  mean(splits$test$Class == "fraud")
))

# Balance method: prefer ROSE (widely available); SMOTE if themis present
balance_method <- if (requireNamespace("themis", quietly = TRUE)) "smote" else "rose"
message("Balancing training data with: ", balance_method)
train_bal <- balance_training(splits$train, method = balance_method, seed = 42)
message("Balanced train size: ", nrow(train_bal), " fraud rate: ", round(mean(train_bal$Class == "fraud"), 4))

# For RF speed on large balanced sets, optionally downsample to 40k
rf_train <- train_bal
if (nrow(rf_train) > 40000) {
  set.seed(42)
  rf_train <- rf_train[sample(seq_len(nrow(rf_train)), 40000), ]
}

message("Training Logistic Regression...")
m_logit <- train_logistic(train_bal)
message("Training Decision Tree...")
m_tree <- train_decision_tree(train_bal)
message("Training Random Forest...")
m_rf <- train_random_forest(rf_train, ntree = 80)
message("Training XGBoost...")
m_xgb <- tryCatch(
  train_xgboost(train_bal, nrounds = 100),
  error = function(e) {
    message("XGBoost failed (", conditionMessage(e), "); continuing without it")
    NULL
  }
)

models <- list(
  logistic = list(model = m_logit, type = "logistic"),
  decision_tree = list(model = m_tree, type = "tree"),
  random_forest = list(model = m_rf, type = "rf")
)
if (!is.null(m_xgb)) models$xgboost <- list(model = m_xgb, type = "xgb")

# Threshold optimization on validation
comparison <- list()
best_name <- NULL
best_score <- -Inf
selected <- NULL

for (nm in names(models)) {
  message("Evaluating ", nm, " on validation...")
  prob <- predict_fraud_prob(models[[nm]]$model, splits$valid, models[[nm]]$type)
  opt <- optimize_threshold(splits$valid$Class, prob, beta = 2)
  # Also metrics at 0.5 for reference
  m50 <- binary_metrics(splits$valid$Class, prob, threshold = 0.5)
  comparison[[nm]] <- list(opt = opt, at_0_5 = m50, valid_prob = prob)
  if (opt$score > best_score) {
    best_score <- opt$score
    best_name <- nm
    selected <- list(name = nm, model = models[[nm]]$model, type = models[[nm]]$type, threshold = opt$threshold)
  }
}

# Final test evaluation for selected model
message("Selected model: ", best_name, " threshold=", selected$threshold)
test_prob <- predict_fraud_prob(selected$model, splits$test, selected$type)
test_metrics <- binary_metrics(splits$test$Class, test_prob, threshold = selected$threshold)

rows <- do.call(rbind, lapply(names(comparison), function(nm) {
  metrics_to_row(nm, comparison[[nm]]$opt$metrics)
}))
rows$dataset <- "validation_optimized"
test_row <- metrics_to_row(paste0(best_name, "_TEST"), test_metrics)
test_row$dataset <- "test"
all_metrics <- rbind(rows, test_row)

# Example explanation on a high-prob test row
idx <- which.max(test_prob)
expl <- explain_prediction(selected$model, splits$test[idx, , drop = FALSE], selected$type, test_prob[idx])

# Persist artifacts
artifacts <- list(
  selected_model_name = best_name,
  model = selected$model,
  model_type = selected$type,
  threshold = selected$threshold,
  feature_columns = feature_columns(),
  balance_method = balance_method,
  validation_summary = qa,
  metrics_table = all_metrics,
  test_metrics = test_metrics,
  explanation_example = expl,
  model_version = paste0("fraud-", best_name, "-v1")
)

saveRDS(artifacts, file.path(root, "models", "model_artifacts", "selected_model.rds"))
write.csv(all_metrics, file.path(root, "models", "model_metrics", "comparison.csv"), row.names = FALSE)
jsonlite::write_json(
  list(
    model_version = artifacts$model_version,
    selected_model = best_name,
    threshold = selected$threshold,
    balance_method = balance_method,
    test = list(
      precision = test_metrics$precision,
      recall = test_metrics$recall,
      f1 = test_metrics$f1,
      pr_auc = test_metrics$pr_auc,
      roc_auc = test_metrics$roc_auc,
      false_negatives = test_metrics$fn,
      false_positives = test_metrics$fp
    ),
    comparison = all_metrics
  ),
  file.path(root, "models", "model_metrics", "metrics.json"),
  auto_unbox = TRUE,
  pretty = TRUE
)

# Save scored sample for Shiny
sample_n <- min(2000, nrow(splits$test))
set.seed(42)
samp <- splits$test[sample(seq_len(nrow(splits$test)), sample_n), ]
samp$fraud_probability <- predict_fraud_prob(selected$model, samp, selected$type)
samp$risk_level <- risk_level(samp$fraud_probability)
samp$predicted_fraud <- as.integer(samp$fraud_probability >= selected$threshold)
write.csv(samp[, c("Time", "Amount", "Class", "fraud_probability", "risk_level", "predicted_fraud")],
          file.path(root, "data", "processed", "scored_sample.csv"), row.names = FALSE)

message("Wrote models/model_artifacts/selected_model.rds")
message("Wrote models/model_metrics/comparison.csv and metrics.json")
print(all_metrics)

# Knit report if rmarkdown available
if (requireNamespace("rmarkdown", quietly = TRUE) && file.exists("reports/model_evaluation.Rmd")) {
  message("Rendering reports/model_evaluation.Rmd ...")
  tryCatch(
    rmarkdown::render("reports/model_evaluation.Rmd", quiet = TRUE),
    error = function(e) message("Report render skipped: ", conditionMessage(e))
  )
}

message("Pipeline complete.")
