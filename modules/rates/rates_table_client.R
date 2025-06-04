mod_rates_table_client_ui <- function(id) {
ns <- NS(id)
tagList(
  gt_output(ns("client_table")),
  mod_download_button_ui(ns("download"))
)
}

mod_rates_table_client_server <- function(id, rates_df){
  moduleServer(id, function(input, output, session){
  ns <- session$ns
    
    client_rates_df <- reactive({
      rates_df() |> 
        group_by(customer_ref) |> 
        summarize(Revenue = sum(amt, na.rm = TRUE),
                  Hours = sum(hours, na.rm = TRUE),
                  Cost = sum(cost, na.rm = TRUE),
                  `Hourly Revenue` = ifelse(Hours == 0, Revenue, Revenue/Hours),
                  `Hourly Cost` = ifelse(Hours == 0, Cost, Cost/Hours),
                  Profit = Revenue - Cost,
                  `Hourly Profit` = ifelse(Hours == 0, Profit, Profit/Hours),
                  `Profit Margin` = Profit/Revenue) |> 
        ungroup() |> 
        rename(Client = customer_ref)
    })

    output$client_table <- render_gt(
      gt(client_rates_df()) %>%
        cols_align(align = "left", columns = 1) %>%
        opt_stylize(style = 1, color = "gray", add_row_striping = TRUE) %>%
        tab_options(
          table.border.top.style = "hidden"
        ) %>%
        tab_style(
          style = list(
            cell_text(weight = "bold")  # Set the font weight to bold
          ),
          locations = cells_column_labels()
        ) %>%
        tab_style(
          style = cell_text(size = "large"),
          locations = list(cells_body(), cells_column_labels())
        ) %>%
        fmt_number(
          columns = c("Hours"),
          decimals = 0
        ) %>%
        fmt_percent(
          columns = c("Profit Margin"),
          decimals = 0
        ) %>%
        fmt_currency(
          columns = c("Revenue", "Cost", "Hourly Revenue", "Hourly Cost", "Profit", "Hourly Profit"),
          decimals = 2
        ) %>%
        tab_options(
          table.border.top.style = "hidden",
          table.width = pct(100),
          data_row.padding = px(15)
        ) %>%
        tab_style(
          style = list(
            cell_text(align = "left")
          ),
          locations = cells_column_labels(
            columns = Client
          )
        ) %>%
        data_color(
          columns = `Profit Margin`,
          method = "numeric",
          palette = c("#a60030","#ffffff", "#00a676"),
          domain = c(0,1)
          #domain = c(min(client_rates_df()$`Profit Margin`, na.rm = TRUE), max(client_rates_df()$`Profit Margin`, na.rm = TRUE))
        ) %>%
        sub_missing(
          missing_text = "---"
        ) %>%
          opt_interactive(
            use_pagination = TRUE,
            use_sorting = TRUE,
            page_size_default = 20,
            use_search = TRUE)
      )
    
    
      mod_download_button_server("download", client_rates_df, "margins_overview")
    
  })
}