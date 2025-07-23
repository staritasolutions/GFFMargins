# UI for ExecDashv3

# Setup -------------------------------------------------------------------

font_add_google("Montserrat")

showtext_auto()

thematic_shiny(font = "auto", bg = "#FFFFFf", fg = "#2F2D2E")

theme_set(theme_minimal())

ui <- page_navbar(
  # Theming -----------------------------------------------------------------

  theme = bs_theme(
    version = 5,
    fg = "#2F2D2E",
    bg = "#FFFFFF",
    primary = "#4c86a8",
    secondary = "#dfdedf",
    success = "#00a676",
    info = "#4c86a8",
    danger = "#a60030",
    base_font = font_google("Montserrat"),
    spacer = "0.75rem"
  ),

  title = strong("Get Found First Margins Dashboard"),
  underline = FALSE,
  tags$head(
    tags$style(HTML(
      "
        .date-text {
          display: inline-block;
          font-size: 0.9em;
          margin-left: 10px;
        }
        .date-container {
          display: flex;
          align-items: center;
        }
      "
    ))
  ),

  # Weekly Overview ---------------------------------------------------------

  nav_panel(
    title = "Overview",
    icon = fa("mountain-sun", height = "1rem"),
    align = "left",

    page_sidebar(
      fillable = FALSE,

      sidebar = sidebar(
        width = 300,
        mod_date_select_ui("date0", end = floor_date(today(), "month") - 1)
      ),

      h4("Overview"),
      card(
        card_header("Overview"),
        mod_rates_table_client_ui("rates_table_client")
      ),
      h4("Hours vs. Revenue"),
      card(
        card_header("Quadrant Plot"),
        #sliderInput(
        #  "rate_range", "Range",
        #  min = 0,
        #  max = 40000,
        #  value = c(0, 1000),
        #  step = 100,
        #  round = TRUE
        #),
        mod_rates_quadrant_ui("rates_quadrant")
        #mod_rates_histogram_ui("rates_histogram")
      )
    )
  ),

  # Drill down ---------------------------------------------------------------------

  nav_panel(
    title = "Drilldown",
    icon = fa("magnifying-glass-chart", height = "1rem"),
    align = "left",

    page_sidebar(
      fillable = FALSE,

      sidebar = sidebar(
        width = 300,
        mod_date_select_ui(
          "date1",
          start = floor_date(Sys.Date(), unit = "year") - years(1),
          end = floor_date(today(), "month") - 1
        )
      ),
      h4(textOutput("drilldown_header")),
      mod_general_select_ui(
        "client1",
        "Client",
        invoices_df |> count(final_client) |> collect(),
        "final_client",
        selected_count = 1
      ),
      card(
        card_header("By Month"),
        full_screen = FALSE,
        mod_rates_table_month_ui("rates_table_month")
      ),
      h4("Metrics Graph"),
      card(
        card_header("Metric by Month"),
        full_screen = FALSE,
        pickerInput(
          "monthly_metric",
          choices = c(
            "Revenue",
            "Hours",
            "Cost",
            "Hourly Revenue",
            "Hourly Cost",
            "Gross",
            "Hourly Gross",
            "Gross Margin"
          ),
          multiple = FALSE,
          selected = "Gross",
          options = pickerOptions(
            actionsBox = TRUE,
            liveSearch = TRUE,
            title = "Metric"
          )
        ),
        mod_line_month_ui("line_month")
      )
    )
  ),

  # Data Exploration -------------------------------------------------------

  nav_menu(
    title = "Data Exploration",
    icon = fa("table", height = "1rem"),

    nav_panel(
      title = "Reconciliation",
      page_sidebar(
        fillable = FALSE,

        sidebar = sidebar(
          width = 300,
          mod_date_select_ui(
            "date2",
            start = floor_date(Sys.Date(), unit = "year") - years(1),
            end = floor_date(today(), "month") - 1
          )
        ),
        h4("Inconsistencies"),
        markdown(
          "The purpose of this page is to:

          **1. Identify hours/invoices that aren't properly being connected within the app**

          - If identified, please email support@staritasolutions.com detailing the issue.  
            If possible, please provide the client name as it is displayed in both Harvest and QuickBooks separately.

          **2. Flag clients with hours logged but no corresponding invoice**

          **3. Flag clients who have been invoiced but have no logged hours**
          "
        ),

        layout_columns(
          card(
            card_header("Hours w/out Invoice"),
            full_screen = FALSE,
            mod_hours_noinvoice_table_ui("hours_noinvoice_table")
          ),
          card(
            card_header("Invoice w/out Hours"),
            full_screen = FALSE,
            mod_invoice_nohours_table_ui("invoice_nohours_table")
          )
        )
      )
    ),
    nav_panel(
      title = "Task Exploration",
      page_sidebar(
        fillable = FALSE,
        sidebar = sidebar(
          width = 400,
          mod_date_select_ui(
            "date2_1",
            start = floor_date(Sys.Date(), unit = "year") - years(1),
            end = floor_date(today(), "month") - 1
          ),
          mod_general_select_ui(
            "client2_1",
            "Client",
            hours_df |> count(final_client) |> collect(),
            "final_client",
            select_multiple = FALSE
          )
        ),
        h3(textOutput("task_header")),
        layout_columns(
          column(
            width = 12,
            h4("Hours"),
            # pickerInput(
            #   "tasks2_1_test",
            #   choices = hours_df |>
            #     count(task) |>
            #     arrange(task) |>
            #     collect() |>
            #     pull(task),
            #   multiple = TRUE,
            #   selected = c(
            #     "Website Development",
            #     "Website Development - Production",
            #     "Website Development - QC Off-Shore Work",
            #     "Website Development - Revisions",
            #     "SEO Setup"
            #   ),
            #   options = pickerOptions(
            #     actionsBox = TRUE,
            #     liveSearch = TRUE,
            #     selectedTextFormat = "static",
            #     title = "Task"
            #   )
            # ),

            input_switch("project_only", "Project Tasks Only", value = TRUE),
            # mod_general_select_ui(
            #   "tasks2_1",
            #   "Task",
            #   hours_df |> count(task) |> collect(),
            #   "task",
            # ),
            mod_hours_task_table_client_ui("hours_task_table")
          ),
          column(
            width = 12,
            h4("Invoices"),
            mod_invoices_task_table_client_ui("invoices_task_table")
          )
        )
      )
    )
  ),
  nav_spacer(),
  br(),
  nav_item(tooltip(
    bs_icon("info-circle"),
    paste0("Date Updated: ", date_updated)
  )),
  br(),
  nav_item(img(src = "SS_Logo_Black.png", height = 40))
)
