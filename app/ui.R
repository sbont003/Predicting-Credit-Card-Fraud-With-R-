dashboardPage(
  dashboardHeader(title = "Credit Fraud (R)"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Overview", tabName = "overview", icon = icon("dashboard")),
      menuItem("Alerts", tabName = "alerts", icon = icon("bell")),
      menuItem("Model", tabName = "model", icon = icon("chart-line"))
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(
        "overview",
        fluidRow(
          valueBoxOutput("n_box"),
          valueBoxOutput("alert_box"),
          valueBoxOutput("model_box")
        ),
        box(width = 12, title = "Note", status = "warning", solidHeader = TRUE,
            "Predictions support human review only. The app does not block cards or reverse charges.")
      ),
      tabItem(
        "alerts",
        sliderInput("min_prob", "Minimum fraud probability", 0, 1, 0.5, 0.05),
        tableOutput("alert_table")
      ),
      tabItem(
        "model",
        verbatimTextOutput("metrics_text")
      )
    )
  )
)
