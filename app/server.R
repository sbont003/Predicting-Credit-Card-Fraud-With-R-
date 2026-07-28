server <- function(input, output, session) {
  output$n_box <- renderValueBox({
    valueBox(nrow(scored), "Scored sample transactions", icon = icon("credit-card"), color = "blue")
  })
  output$alert_box <- renderValueBox({
    n <- if (nrow(scored)) sum(scored$fraud_probability >= 0.6) else 0
    valueBox(n, "High/critical alerts (p≥0.60)", icon = icon("exclamation"), color = "red")
  })
  output$model_box <- renderValueBox({
    label <- if (!is.null(meta)) meta$selected_model else "untrained"
    valueBox(label, "Selected model", icon = icon("cogs"), color = "purple")
  })

  output$alert_table <- renderTable({
    req(nrow(scored) > 0)
    df <- scored[scored$fraud_probability >= input$min_prob, ]
    df <- df[order(-df$fraud_probability), ]
    head(df, 100)
  })

  output$metrics_text <- renderPrint({
    if (is.null(meta)) {
      cat("Run scripts/run_pipeline.R first.\n")
    } else {
      str(meta$test)
      cat("\nThreshold:", meta$threshold, "\nVersion:", meta$model_version, "\n")
    }
  })
}
