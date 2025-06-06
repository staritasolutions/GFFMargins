server <- function(input, output, session) {
# Overview Tab -----------------------------------------------------------

  date0_1 <- mod_date_select_server("date0")

  overview_df <- reactive({
    rates_df |> 
      filter(month >= date0_1$start() & month <= date0_1$end()) |> 
        group_by(customer_ref) |> 
        summarize(Revenue = sum(amt, na.rm = TRUE),
                  Hours = sum(hours, na.rm = TRUE),
                  Cost = sum(cost, na.rm = TRUE),
                  `Hourly Revenue` = ifelse(Hours == 0, Revenue, Revenue/Hours),
                  `Hourly Cost` = ifelse(Hours == 0, Cost, Cost/Hours),
                  Gross = Revenue - Cost,
                  `Hourly Gross` = ifelse(Hours == 0, Gross, Gross/Hours),
                  `Gross Margin` = Gross/Revenue) |> 
        ungroup() |> 
        rename(Client = customer_ref)
  })

  observeEvent(date0_1$start(), {
    profit_values <- overview_df()$`Hourly Gross`
    updateSliderInput(
      session,
      inputId = "rate_range",
      min = round(min(profit_values, na.rm = TRUE)/100)*100, 
      max = round(max(profit_values, na.rm = TRUE)/100)*100,
      step = 100
    )
  })

  mod_rates_table_client_server("rates_table_client", overview_df)

  slider_vals <- reactive(list(start = input$rate_range[1], end = input$rate_range[2]))
  mod_rates_histogram_server("rates_histogram", overview_df, slider_vals)

  mod_rates_quadrant_server("rates_quadrant", overview_df)


# Drilldown Tab ----------------------------------------------------------
  
  date1 <- mod_date_select_server("date1")
  clients <- mod_general_select_server("client1")

 output$drilldown_header <- renderText({
  paste0("Client: ", paste(clients(), collapse = ", "))
})



  monthly_df <- reactive({
    rates_df |> 
      filter(month >= date1$start() & month <= date1$end()) |> 
      filter(customer_ref %in% clients()) |> 
        group_by(month) |> 
        summarize(Revenue = sum(amt, na.rm = TRUE),
                  Hours = sum(hours, na.rm = TRUE),
                  Cost = sum(cost, na.rm = TRUE),
                  `Hourly Revenue` = ifelse(Hours == 0, Revenue, Revenue/Hours),
                  `Hourly Cost` = ifelse(Hours == 0, Cost, Cost/Hours),
                 Gross = Revenue - Cost,
                  `Hourly Gross` = ifelse(Hours == 0, Gross, Gross/Hours),
                  `Gross Margin` = Gross/Revenue) |> 
        ungroup() |> 
      rename(Date = month)
  })
  
  mod_rates_table_month_server("rates_table_month", monthly_df)
  mod_line_month_server("line_month", monthly_df, reactive(input$monthly_metric))

}