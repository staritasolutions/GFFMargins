server <- function(input, output, session) {
  # Overview Tab -----------------------------------------------------------

  date0 <- mod_date_select_server("date0")

  overview_df <- reactive({
    rates_df |>
      filter(month >= date0$start() & month <= date0$end()) |>
      group_by(final_client) |>
      summarize(
        Revenue = sum(amt, na.rm = TRUE),
        Hours = sum(hours, na.rm = TRUE),
        Cost = sum(cost, na.rm = TRUE)
      ) |>
      mutate(
        `Hourly Revenue` = ifelse(Hours == 0, Revenue, Revenue / Hours),
        `Hourly Cost` = ifelse(Hours == 0, Cost, Cost / Hours),
        Gross = Revenue - Cost,
        `Hourly Gross` = ifelse(Hours == 0, Gross, Gross / Hours),
        `Gross Margin` = Gross / Revenue
      ) |>
      ungroup() |>
      rename(Client = final_client) |>
      collect()
  })

  observeEvent(date0$start(), {
    profit_values <- overview_df()$`Hourly Gross`
    updateSliderInput(
      session,
      inputId = "rate_range",
      min = round(min(profit_values, na.rm = TRUE) / 100) * 100,
      max = round(max(profit_values, na.rm = TRUE) / 100) * 100,
      step = 100
    )
  })

  mod_rates_table_client_server("rates_table_client", overview_df)

  slider_vals <- reactive(list(
    start = input$rate_range[1],
    end = input$rate_range[2]
  ))
  mod_rates_histogram_server("rates_histogram", overview_df, slider_vals)

  mod_rates_quadrant_server("rates_quadrant", overview_df)

  # Drilldown Tab ----------------------------------------------------------

  date1 <- mod_date_select_server("date1")
  clients <- mod_general_select_server("client1")

  output$drilldown_header <- renderText({
    if (length(clients()) > 3) {
      "Client: Multiple Clients"
    } else {
      paste0("Client: ", paste(clients(), collapse = ", "))
    }
  })

  monthly_df <- reactive({
    client_vals <- reactive(clients())

    rates_df |>
      filter(month >= date1$start() & month <= date1$end()) |>
      collect() |>
      filter(final_client %in% clients()) |>
      group_by(month) |>
      summarize(
        Revenue = sum(amt, na.rm = TRUE),
        Hours = sum(hours, na.rm = TRUE),
        Cost = sum(cost, na.rm = TRUE)
      ) |>
      mutate(
        `Hourly Revenue` = ifelse(Hours == 0, Revenue, Revenue / Hours),
        `Hourly Cost` = ifelse(Hours == 0, Cost, Cost / Hours),
        Gross = Revenue - Cost,
        `Hourly Gross` = ifelse(Hours == 0, Gross, Gross / Hours),
        `Gross Margin` = Gross / Revenue
      ) |>
      ungroup() |>
      rename(Date = month)
  })

  mod_rates_table_month_server("rates_table_month", monthly_df)
  mod_line_month_server(
    "line_month",
    monthly_df,
    reactive(input$monthly_metric)
  )

  # Reconciliation ------------------------------------------------------------

  date2 <- mod_date_select_server("date2")

  mod_hours_noinvoice_table_server(
    "hours_noinvoice_table",
    hours_df,
    invoices_df,
    date2
  )

  mod_invoice_nohours_table_server(
    "invoice_nohours_table",
    hours_df,
    invoices_df,
    date2
  )

  # Task Exploration -------------------------------------------------------

  date2_1 <- mod_date_select_server("date2_1")

  clients2_1 <- mod_general_select_server("client2_1")
  #tasks2_1 <- mod_general_select_server("tasks2_1")

  output$task_header <- renderText({
    paste0("Client: ", clients2_1())
  })

  filtered_hours <- reactive({
    if (input$project_only) {
      hours_df |>
        filter(spent_date >= date2_1$start() & spent_date <= date2_1$end()) |>
        filter(final_client == !!clients2_1()) |>
        filter(
          task %in%
            c(
              "Website Development",
              "Website Development - Production",
              "Website Development - QC Off-Shore Work",
              "Website Development - Revisions",
              "SEO Setup"
            )
        ) |>
        select(
          Date = spent_date,
          Hours = hours,
          Task = task,
          Client = final_client
        ) |>
        collect()
    } else {
      hours_df |>
        filter(spent_date >= date2_1$start() & spent_date <= date2_1$end()) |>
        filter(final_client == !!clients2_1()) |>
        select(
          Date = spent_date,
          Hours = hours,
          Task = task,
          Client = final_client
        ) |>
        collect()
    }
  })

  filtered_invoices <- reactive({
    invoices_df |>
      filter(txn_date >= date2_1$start() & txn_date <= date2_1$end()) |>
      filter(final_client == !!clients2_1()) |>
      select(
        Date = txn_date,
        Amount = amt,
        Description = description,
        Client = final_client
      ) |>
      collect()
  })

  mod_hours_task_table_client_server("hours_task_table", filtered_hours)
  mod_invoices_task_table_client_server(
    "invoices_task_table",
    filtered_invoices
  )
}
