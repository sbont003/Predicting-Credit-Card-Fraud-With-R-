library(shiny)
library(shinydashboard)

root <- normalizePath(file.path(".."))
metrics_file <- file.path(root, "models", "model_metrics", "metrics.json")
sample_file <- file.path(root, "data", "processed", "scored_sample.csv")

meta <- if (file.exists(metrics_file)) jsonlite::fromJSON(metrics_file) else NULL
scored <- if (file.exists(sample_file)) read.csv(sample_file) else data.frame()
