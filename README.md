# Predicting Credit Card Fraud with R

Machine-learning project that detects fraudulent credit card transactions in a highly imbalanced dataset (fraud typically < 1%).

The pipeline validates data, explores class imbalance, applies **SMOTE/ROSE only on training data**, trains Logistic Regression / Decision Tree / Random Forest / XGBoost, optimizes the decision threshold, and reports **precision, recall, F1, ROC-AUC, and PR-AUC** (not accuracy alone).

> The model produces a fraud probability and risk category to support human review. It does **not** permanently block cards or reverse transactions.

## Quick start

### Option A — Local R

Install R from https://cran.r-project.org/bin/macosx/ then:

```bash
Rscript scripts/install_packages.R
Rscript scripts/download_data.R   # optional; full ULB CSV
# or copy the bundled sample:
# cp data/synthetic/creditcard_sample.csv data/raw/creditcard.csv
Rscript scripts/run_pipeline.R
```

### Option B — Docker

```bash
docker build -t credit-fraud-r .
docker run --rm -v "$PWD/models:/project/models" -v "$PWD/reports:/project/reports" credit-fraud-r
```

Open `reports/model_evaluation.html` after the pipeline finishes.

### Optional apps

```bash
# Plumber API
Rscript -e "plumber::pr_run(plumber::plumb('api/plumber.R'), port=8000)"

# Shiny dashboard
Rscript -e "shiny::runApp('app', port=3838)"
```

## Dataset

Default source (TensorFlow public mirror of the ULB credit-card fraud CSV):

https://storage.googleapis.com/download.tensorflow.org/data/creditcard.csv

Place the file at `data/raw/creditcard.csv` (or run `scripts/download_data.R`).

**Limitations:** Features `V1`–`V28` are PCA-anonymized; no merchant/device/location fields; public data does not represent a production bank.

## Project layout

```text
R/                 # reusable functions
scripts/           # download + end-to-end pipeline
reports/           # R Markdown evaluation report
app/               # Shiny monitoring dashboard
api/               # Plumber prediction API
models/            # saved models + metrics
tests/             # testthat checks
```

## Demo prediction API

```http
POST /api/v1/predict
GET  /api/v1/model/metrics
GET  /api/v1/health
```

## Resume bullets

- Built R fraud classifiers (Logistic Regression, Decision Tree, Random Forest, XGBoost) on 280k+ transactions with <1% fraud.
- Applied SMOTE/ROSE only inside training folds and evaluated with precision, recall, F1, ROC-AUC, and PR-AUC.
- Tuned classification thresholds to reduce false negatives while controlling false-positive alert volume.
