# Synthetic fallback (~50k rows, ~0.2% fraud) matching V1–V28 schema

source(file.path("R", "utilities.R"))
root <- ensure_dirs()
set_project_seed(42)

n <- 50000
fraud_n <- 100
legit_n <- n - fraud_n

make_block <- function(n, fraud = FALSE) {
  mat <- matrix(rnorm(n * 28, mean = if (fraud) -1.5 else 0, sd = if (fraud) 1.8 else 1), ncol = 28)
  colnames(mat) <- paste0("V", 1:28)
  as.data.frame(mat)
}

legit <- make_block(legit_n, fraud = FALSE)
fraud <- make_block(fraud_n, fraud = TRUE)
# Amplify a few fraud-sensitive dims
fraud$V14 <- fraud$V14 - 4
fraud$V17 <- fraud$V17 - 3.5
fraud$V12 <- fraud$V12 - 2.5

df <- rbind(legit, fraud)
df$Time <- sort(runif(n, 0, 172000))
df$Amount <- pmax(0, ifelse(df$V1[seq_len(n)] > 0, abs(rnorm(n, 50, 40)), abs(rnorm(n, 120, 200))))
df$Amount[ (legit_n + 1):n ] <- abs(rnorm(fraud_n, 250, 400))
df$Class <- c(rep(0L, legit_n), rep(1L, fraud_n))
df <- df[sample(seq_len(n)), ]

# Reorder columns like original
df <- df[, c("Time", paste0("V", 1:28), "Amount", "Class")]

out <- file.path(root, "data", "raw", "creditcard.csv")
dir.create(dirname(out), showWarnings = FALSE, recursive = TRUE)
write.csv(df, out, row.names = FALSE)
write.csv(df, file.path(root, "data", "synthetic", "creditcard_synthetic.csv"), row.names = FALSE)
message("Wrote synthetic dataset to ", out, " (n=", n, ", fraud=", fraud_n, ")")
