# Plumber API for fraud probability scoring

#* @apiTitle Credit Card Fraud Prediction API
#* @apiDescription Advisory fraud scores only — no automatic card blocking.

`%||%` <- function(a, b) if (!is.null(a)) a else b

load_artifacts <- function() {
  path <- file.path("models", "model_artifacts", "selected_model.rds")
  if (!file.exists(path)) stop("Model artifact missing. Run scripts/run_pipeline.R first.")
  readRDS(path)
}

#* Health check
#* @get /api/v1/health
function() {
  list(status = "ok", service = "credit-card-fraud-r", advisory_only = TRUE)
}

#* Model metrics
#* @get /api/v1/model/metrics
function() {
  path <- file.path("models", "model_metrics", "metrics.json")
  if (!file.exists(path)) return(list(error = "metrics not found"))
  jsonlite::fromJSON(path)
}

#* Model version
#* @get /api/v1/model/version
function() {
  art <- load_artifacts()
  list(model_version = art$model_version, selected_model = art$selected_model_name, threshold = art$threshold)
}

#* Predict fraud probability for one transaction feature vector
#* @post /api/v1/predict
#* @parser json
function(req, res) {
  art <- load_artifacts()
  body <- jsonlite::fromJSON(req$postBody)
  # Accept either flat list of V1..V28 + Amount/Time or already engineered features
  source("R/utilities.R")
  source("R/preprocessing.R")
  source("R/train_models.R")
  source("R/explain_predictions.R")

  # Build a one-row data.frame compatible with training features
  row <- as.list(body)
  # Defaults for missing anonymized features
  for (v in paste0("V", 1:28)) if (is.null(row[[v]])) row[[v]] <- 0
  if (is.null(row$Time)) row$Time <- 0
  if (is.null(row$Amount)) row$Amount <- 0
  df <- as.data.frame(row, stringsAsFactors = FALSE)
  df$Class <- factor("legit", levels = c("legit", "fraud"))
  df$log_amount <- log1p(as.numeric(df$Amount))
  df$scaled_time <- as.numeric(df$Time)
  df$scaled_amount <- as.numeric(df$Amount)

  prob <- predict_fraud_prob(art$model, df, art$model_type)
  th <- art$threshold
  level <- risk_level(prob)
  expl <- explain_prediction(art$model, df, art$model_type, prob)

  list(
    fraud_probability = unname(prob),
    risk_level = toupper(level),
    prediction = if (prob >= th) "FRAUD_REVIEW_REQUIRED" else "ALLOW_WITH_MONITORING",
    decision_threshold = th,
    model_version = art$model_version,
    technical_explanation = expl$technical,
    business_explanation = expl$business,
    advisory_only = TRUE
  )
}
