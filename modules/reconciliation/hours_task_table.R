mod_hours_task_table_client_ui <- function(id) {
  ns <- NS(id)
  tagList(
    gt_output(ns("hours_table")),
    mod_download_button_ui(ns("download"))
  )
}

mod_hours_task_table_client_server <- function(id, hours_df) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    output$hours_table <- render_gt(
      gt(hours_df()) %>%
        cols_align(align = "left", columns = 1) %>%
        opt_stylize(style = 1, color = "gray", add_row_striping = TRUE) %>%
        tab_options(
          table.border.top.style = "hidden"
        ) %>%
        tab_style(
          style = list(
            cell_text(weight = "bold") # Set the font weight to bold
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
        sub_missing(
          missing_text = "---"
        ) %>%
        opt_interactive(
          use_pagination = TRUE,
          use_sorting = TRUE,
          page_size_default = 10,
          use_search = TRUE
        )
    )

    mod_download_button_server("download", hours_df, "hours_df")
  })
}
