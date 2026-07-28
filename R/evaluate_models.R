# Evaluation metrics and threshold optimization

binary_metrics <- function(y_true, y_prob, threshold = 0.5) {
  # y_true: factor with levels legit, fraud OR 0/1
  if (is.factor(y_true)) {
    y <- as.integer(y_true == "fraud")
  } else {
    y <- as.integer(y_true)
  }
  pred <- as.integer(y_prob >= threshold)
  tp <- sum(pred == 1 & y == 1)
  tn <- sum(pred == 0 & y == 0)
  fp <- sum(pred == 1 & y == 0)
  fn <- sum(pred == 0 & y == 1)

  precision <- ifelse(tp + fp == 0, 0, tp / (tp + fp))
  recall <- ifelse(tp + fn == 0, 0, tp / (tp + fn))
  f1 <- ifelse(precision + recall == 0, 0, 2 * precision * recall / (precision + recall))
  fpr <- ifelse(fp + tn == 0, 0, fp / (fp + tn))
  fnr <- ifelse(fn + tp == 0, 0, fn / (fn + tp))

  roc_auc <- NA_real_
  pr_auc <- NA_real_
  if (requireNamespace("pROC", quietly = TRUE) && length(unique(y)) == 2) {
    roc_auc <- as.numeric(pROC::auc(pROC::roc(y, y_prob, quiet = TRUE)))
  }
  if (requireNamespace("PRROC", quietly = TRUE) && sum(y == 1) > 0 && sum(y == 0) > 0) {
    pr <- PRROC::pr.curve(scores.class0 = y_prob[y == 1], scores.class1 = y_prob[y == 0], curve = FALSE)
    pr_auc <- as.numeric(pr$auc.integral)
  }

  list(
    threshold = threshold,
    precision = precision,
    recall = recall,
    f1 = f1,
    roc_auc = roc_auc,
    pr_auc = pr_auc,
    fpr = fpr,
    fnr = fnr,
    tp = tp,
    tn = tn,
    fp = fp,
    fn = fn,
    confusion = matrix(c(tn, fp, fn, tp), nrow = 2, byrow = TRUE,
                       dimnames = list(Actual = c("legit", "fraud"), Predicted = c("legit", "fraud")))
  )
}

optimize_threshold <- function(y_true, y_prob, beta = 2, grid = seq(0.05, 0.95, by = 0.01)) {
  # F-beta emphasizes recall when beta > 1 (fraud FN costly)
  if (is.factor(y_true)) y <- as.integer(y_true == "fraud") else y <- as.integer(y_true)
  best <- list(threshold = 0.5, score = -Inf, metrics = NULL)
  for (th in grid) {
    m <- binary_metrics(y, y_prob, threshold = th)
    # F-beta
    b2 <- beta^2
    score <- ifelse(m$precision + m$recall == 0, 0,
                    (1 + b2) * m$precision * m$recall / (b2 * m$precision + m$recall))
    if (is.finite(score) && score > best$score) {
      best <- list(threshold = th, score = score, metrics = m)
    }
  }
  best
}

metrics_to_row <- function(model_name, metrics) {
  data.frame(
    model = model_name,
    threshold = metrics$threshold,
    precision = round(metrics$precision, 4),
    recall = round(metrics$recall, 4),
    f1 = round(metrics$f1, 4),
    pr_auc = round(metrics$pr_auc, 4),
    roc_auc = round(metrics$roc_auc, 4),
    false_negatives = metrics$fn,
    false_positives = metrics$fp,
    stringsAsFactors = FALSE
  )
}
