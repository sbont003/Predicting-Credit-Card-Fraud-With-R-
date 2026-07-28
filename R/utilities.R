# Shared helpers

project_root <- function() {
  # Prefer RStudio project / script-relative root
  if (requireNamespace("rprojroot", quietly = TRUE)) {
    tryCatch(
      return(rprojroot::find_root(rprojroot::has_file("README.md"))),
      error = function(e) NULL
    )
  }
  getwd()
}

ensure_dirs <- function(root = project_root()) {
  dirs <- c(
    file.path(root, "data", "raw"),
    file.path(root, "data", "processed"),
    file.path(root, "models", "model_artifacts"),
    file.path(root, "models", "model_metrics"),
    file.path(root, "reports")
  )
  invisible(vapply(dirs, dir.create, logical(1), showWarnings = FALSE, recursive = TRUE))
  invisible(root)
}

set_project_seed <- function(seed = 42) {
  set.seed(seed)
  invisible(seed)
}

risk_level <- function(prob) {
  dplyr::case_when(
    prob >= 0.80 ~ "critical",
    prob >= 0.60 ~ "high",
    prob >= 0.30 ~ "medium",
    TRUE ~ "low"
  )
}
