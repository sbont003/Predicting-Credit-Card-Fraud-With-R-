# Model training helpers

train_logistic <- function(train) {
  form <- as.formula(paste("Class ~", paste(feature_columns(), collapse = " + ")))
  glm(form, data = train, family = binomial())
}

train_decision_tree <- function(train) {
  form <- as.formula(paste("Class ~", paste(feature_columns(), collapse = " + ")))
  # Use class weights via parms / loss if rpart available
  if (!requireNamespace("rpart", quietly = TRUE)) stop("rpart required")
  rpart::rpart(
    form,
    data = train,
    method = "class",
    parms = list(loss = matrix(c(0, 1, 5, 0), nrow = 2)), # higher cost for FN
    control = rpart::rpart.control(cp = 0.001, minsplit = 20)
  )
}

train_random_forest <- function(train, ntree = 100) {
  form <- as.formula(paste("Class ~", paste(feature_columns(), collapse = " + ")))
  # Downsize for speed on full data if huge
  randomForest::randomForest(
    form,
    data = train,
    ntree = ntree,
    mtry = floor(sqrt(length(feature_columns()))),
    importance = TRUE,
    nodesize = 5
  )
}

train_xgboost <- function(train, nrounds = 120) {
  if (!requireNamespace("xgboost", quietly = TRUE)) stop("xgboost required")
  y <- as.numeric(train$Class == "fraud")
  x <- as.matrix(train[, feature_columns(), drop = FALSE])
  # scale_pos_weight ~ negatives / positives
  pos <- max(sum(y == 1), 1)
  neg <- max(sum(y == 0), 1)
  dtrain <- xgboost::xgb.DMatrix(data = x, label = y)
  params <- list(
    objective = "binary:logistic",
    eval_metric = "aucpr",
    max_depth = 5,
    eta = 0.08,
    subsample = 0.9,
    colsample_bytree = 0.9,
    min_child_weight = 2,
    scale_pos_weight = neg / pos
  )
  xgboost::xgb.train(params = params, data = dtrain, nrounds = nrounds, verbose = 0)
}

predict_fraud_prob <- function(model, newdata, model_type) {
  feats <- newdata[, feature_columns(), drop = FALSE]
  if (model_type == "logistic") {
    return(as.numeric(predict(model, newdata = newdata, type = "response")))
  }
  if (model_type == "tree") {
    p <- predict(model, newdata = newdata, type = "prob")
    return(as.numeric(p[, "fraud"]))
  }
  if (model_type == "rf") {
    p <- predict(model, newdata = newdata, type = "prob")
    return(as.numeric(p[, "fraud"]))
  }
  if (model_type == "xgb") {
    x <- as.matrix(feats)
    return(as.numeric(predict(model, newdata = x)))
  }
  stop("Unknown model_type: ", model_type)
}
