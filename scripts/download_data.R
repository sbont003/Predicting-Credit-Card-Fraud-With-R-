# Download ULB credit-card fraud CSV (TensorFlow public mirror)

source(file.path("R", "utilities.R"))
root <- ensure_dirs()
dest <- file.path(root, "data", "raw", "creditcard.csv")

if (file.exists(dest)) {
  message("Dataset already present: ", dest)
  quit(save = "no", status = 0)
}

url <- "https://storage.googleapis.com/download.tensorflow.org/data/creditcard.csv"
message("Downloading ", url)
tryCatch(
  {
    download.file(url, destfile = dest, mode = "wb")
    message("Saved to ", dest)
  },
  error = function(e) {
    message("Download failed: ", conditionMessage(e))
    message("Generating synthetic fallback dataset instead...")
    source(file.path(root, "scripts", "generate_synthetic.R"))
  }
)
