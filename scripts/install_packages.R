# Install required R packages for this project

pkgs <- c(
  "dplyr", "ggplot2", "readr", "caret", "randomForest", "xgboost", "rpart",
  "ROSE", "pROC", "PRROC", "rmarkdown", "shiny", "shinydashboard", "plumber",
  "testthat", "jsonlite", "scales", "Matrix", "recipes", "themis"
)

install_if_missing <- function(packages) {
  for (p in packages) {
    if (!requireNamespace(p, quietly = TRUE)) {
      message("Installing ", p, " ...")
      install.packages(p, repos = "https://cloud.r-project.org")
    } else {
      message(p, " already installed")
    }
  }
}

install_if_missing(pkgs)
message("Done.")
