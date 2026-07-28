# Docs

## Run locally (macOS)

1. Install R from https://cran.r-project.org/bin/macosx/
2. From the project root:

```bash
Rscript scripts/install_packages.R
Rscript scripts/download_data.R   # or use data/synthetic sample
Rscript scripts/run_pipeline.R
```

3. Open `reports/model_evaluation.html`
4. Optional:

```bash
Rscript -e "shiny::runApp('app', port=3838)"
Rscript -e "plumber::pr_run(plumber::plumb('api/plumber.R'), host='127.0.0.1', port=8000)"
```

## Full Kaggle/ULB dataset

Set `FULL_DATA=1` when running the pipeline to avoid the default ~80k subsample:

```bash
FULL_DATA=1 Rscript scripts/run_pipeline.R
```

## Design notes

- Resampling (SMOTE/ROSE) is applied **only** to training data.
- Time-ordered split is preferred when `Time` is present.
- Primary metrics: recall, precision, F1, PR-AUC, ROC-AUC — not accuracy.
- Explanations avoid inventing meanings for anonymized `V1`–`V28` features.
