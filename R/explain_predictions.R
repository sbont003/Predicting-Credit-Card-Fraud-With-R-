# Lightweight explanations without claiming meanings for V1–V28

explain_prediction <- function(model, newdata_row, model_type, prob, top_n = 5) {
  feats <- feature_columns()
  values <- as.numeric(newdata_row[, feats, drop = FALSE])
  names(values) <- feats

  # Approximate contribution via absolute z-like magnitude for anonymized vars
  # Prefer model-native importance when available
  importance <- rep(1, length(feats))
  names(importance) <- feats

  if (model_type == "rf" && !is.null(model$importance)) {
    imp <- model$importance
    col <- if ("MeanDecreaseAccuracy" %in% colnames(imp)) "MeanDecreaseAccuracy" else colnames(imp)[1]
    importance[rownames(imp)] <- as.numeric(imp[, col])
  }
  if (model_type == "xgb") {
    imp <- xgboost::xgb.importance(model = model)
    importance[imp$Feature] <- imp$Gain
  }
  if (model_type == "logistic") {
    importance[names(coef(model))[-1]] <- abs(coef(model)[-1])
  }

  score <- abs(values) * (abs(importance) + 1e-6)
  ord <- order(score, decreasing = TRUE)
  top <- head(ord, top_n)

  technical <- paste0(
    "Fraud probability: ", sprintf("%.2f", prob), "\n",
    "Top contributing features (anonymized; magnitude × model importance):\n",
    paste(sprintf("- %s = %.4f", names(values)[top], values[top]), collapse = "\n")
  )

  business <- paste0(
    "The transaction received a fraud-risk score of ", sprintf("%.0f%%", 100 * prob),
    " because its behavioral feature pattern differed from most legitimate transactions. ",
    "Anonymized indicators ", paste(names(values)[top[1:3]], collapse = ", "),
    " and the amount-related features strongly influenced the score. ",
    "Because V1–V28 are PCA-transformed, do not map them to merchant, location, or device attributes. ",
    "Recommended action: human fraud review — the model does not permanently block the card."
  )

  list(technical = technical, business = business, top_features = names(values)[top])
}
