source(file.path("..", "..", "R", "data_validation.R"))
source(file.path("..", "..", "R", "evaluate_models.R"))
source(file.path("..", "..", "R", "utilities.R"))

test_that("validation rejects negative amounts", {
  df <- data.frame(
    Time = 1,
    Amount = -1,
    Class = 0,
    matrix(0, ncol = 28, dimnames = list(NULL, paste0("V", 1:28)))
  )
  names(df)[4:31] <- paste0("V", 1:28)
  expect_error(validate_credit_card_data(df))
})

test_that("binary metrics bounds", {
  y <- c(0, 0, 1, 1)
  p <- c(0.1, 0.2, 0.8, 0.9)
  m <- binary_metrics(y, p, threshold = 0.5)
  expect_true(m$precision >= 0 && m$precision <= 1)
  expect_true(m$recall >= 0 && m$recall <= 1)
  expect_equal(m$tp, 2)
})

test_that("risk levels map correctly", {
  expect_equal(risk_level(0.9), "critical")
  expect_equal(risk_level(0.2), "low")
})
