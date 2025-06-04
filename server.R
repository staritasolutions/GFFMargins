server <- function(input, output, session) {
# Overview Tab -----------------------------------------------------------

  date0_1 <- mod_date_select_server("date0")

  overview_df <- reactive({
    rates_df |> 
      filter(month >= date0_1$start() & month <= date0_1$end())
  })

  mod_rates_table_client_server("rates_table_client", overview_df)
}