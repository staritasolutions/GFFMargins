mod_rates_table_client_ui <- function(id) {
ns <- NS(id)
tagList(
  gt_output(ns("client_table")),
  mod_download_button_ui(ns("download"))
)
}

mod_rates_table_client_server <- function(id, client_rates_df){
  moduleServer(id, function(input, output, session){
  ns <- session$ns
    

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
          columns = c("Gross Margin"),
          decimals = 0
        ) %>%
        fmt_currency(
          columns = c("Revenue", "Cost", "Hourly Revenue", "Hourly Cost", "Gross", "Hourly Gross"),
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
          columns = `Gross Margin`,
          method = "numeric",
          palette = c("#a60030","#ffffff", "#00a676"),
          domain = c(0,1)
          #domain = c(min(client_rates_df()$`Gross Margin`, na.rm = TRUE), max(client_rates_df()$`Gross Margin`, na.rm = TRUE))
        ) %>%
        sub_missing(
          missing_text = "---"
        ) %>%
          opt_interactive(
            use_pagination = TRUE,
            use_sorting = TRUE,
            page_size_default = 10,
            use_search = TRUE)
      )
    
    
      mod_download_button_server("download", client_rates_df, "margins_overview")
    
  })
}