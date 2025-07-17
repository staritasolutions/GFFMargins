mod_hours_noinvoice_table_ui <- function(id) {
  ns <- NS(id)
  tagList(
    gt_output(ns("tbl")),
    mod_download_button_ui(ns("download"))
  )
}

mod_hours_noinvoice_table_server <- function(id, hours_df, invoices_df, date) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    harvest_clients_to_exclude <- c("Ignore", "Spot On Solution", "ProBono")

    temp_hours_df <- reactive({
      hours_df |>
        filter(spent_date >= date$start() & spent_date <= date$end()) |>
        select(spent_date, hours, final_client) |>
        filter(!final_client %in% harvest_clients_to_exclude) |>
        group_by(final_client) |>
        summarize(hours = sum(hours)) |>
        ungroup()
    })

    temp_invoices_df <- reactive({
      invoices_df |>
        filter(txn_date >= date$start() & txn_date <= date$end()) |>
        group_by(final_client) |>
        summarize(amount = sum(amt)) |>
        ungroup()
    })

    hours_no_invoice_df <- reactive({
      temp_hours_df() |>
        left_join(temp_invoices_df(), by = "final_client") |>
        filter(is.na(amount)) |>
        mutate(amount = 0) |>
        arrange(desc(hours)) |>
        rename(Client = final_client, Hours = hours, Amount = amount) |>
        collect()
    })

    output$tbl <- render_gt(
      gt(hours_no_invoice_df()) %>%
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
          decimals = 1
        ) %>%
        fmt_currency(
          columns = "Amount",
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
        opt_interactive(
          use_pagination = TRUE,
          use_sorting = TRUE,
          page_size_default = 10,
          use_search = TRUE
        )
    )

    mod_download_button_server(
      "download",
      hours_no_invoice_df,
      "hours_no_invoice.csv"
    )
  })
}
