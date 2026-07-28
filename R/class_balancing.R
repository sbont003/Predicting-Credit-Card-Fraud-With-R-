# Class-imbalance handling — ONLY on training data

balance_training <- function(train, method = c("smote", "rose", "none"), seed = 42) {
  method <- match.arg(method)
  set.seed(seed)
  form <- as.formula(paste("Class ~", paste(feature_columns(), collapse = " + ")))

  if (method == "none") {
    return(train)
  }

  if (method == "rose") {
    if (!requireNamespace("ROSE", quietly = TRUE)) {
      stop("Package ROSE is required for method='rose'")
    }
    # Target ~50/50 with ROSE
    bal <- ROSE::ROSE(form, data = train, seed = seed)$data
    return(bal)
  }

  # SMOTE via caret upSample approximation if themis unavailable
  if (requireNamespace("themis", quietly = TRUE) && requireNamespace("recipes", quietly = TRUE)) {
    rec <- recipes::recipe(form, data = train) |>
      themis::step_smote(Class, over_ratio = 0.2) # fraud up to 20% of majority
    bal <- recipes::prep(rec) |> recipes::bake(new_data = NULL)
    return(as.data.frame(bal))
  }

  # Fallback: caret::upSample (random oversampling, not true SMOTE)
  message("themis not available; falling back to caret::upSample")
  caret::upSample(x = train[, feature_columns(), drop = FALSE], y = train$Class, yname = "Class")
}
