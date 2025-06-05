# UI for ExecDashv3

# Setup -------------------------------------------------------------------

font_add_google("Montserrat")

showtext_auto()

thematic_shiny(font = "auto"
               , bg = "#FFFFFf"
               , fg = "#2F2D2E"
               )

theme_set(theme_minimal())

ui <- page_navbar(

# Theming -----------------------------------------------------------------

  theme = bs_theme(version = 5,
                   fg = "#2F2D2E", bg = "#FFFFFF",
                   primary = "#4c86a8", secondary = "#dfdedf",
                   success = "#00a676", info = "#4c86a8", danger = "#a60030",
                   base_font = font_google("Montserrat"),
                   spacer = "0.75rem"),

  title =strong("Get Found First Margins Dashboard"),
  underline = FALSE,
  tags$head(
    tags$style(HTML("
        .date-text {
          display: inline-block;
          font-size: 0.9em;
          margin-left: 10px;
        }
        .date-container {
          display: flex;
          align-items: center;
        }
      "))
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
        mod_date_select_ui("date0")
      ),

      h4("Overview"),
          card(
            card_header = "Overview",
            input_switch("exclude_setup", "Exclude Setup/Dev Fees", value = TRUE),
            mod_rates_table_client_ui("rates_table_client")
          ),
       h4("Hourly Profit Distribution"),
          card(
            card_header = "Distribution",
            sliderInput( 
              "rate_range", "Range", 
              min = 0,
              max = 40000,
              value = c(0, 1000),
              step = 100,
              round = TRUE
            ), 
            mod_rates_histogram_ui("rates_histogram")
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
          mod_date_select_ui("date1",start = floor_date(Sys.Date(), unit = "year")-years(1))

        ),
        h4("Client Drilldown"),
        mod_general_select_ui("client1", "Client", rates_df, "customer_ref", selected_count = 1),
          card(
            card_header("By Month"),
            full_screen = FALSE,
            mod_rates_table_month_ui("rates_table_month")
          ),
          h4("Metrics Graph"),
          card(
            card_header("Metric by Month"),
            full_screen = FALSE,
            pickerInput("monthly_metric",
                          choices = c("Revenue","Hours","Cost",
                                      "Hourly Revenue","Hourly Cost","Profit",
                                      "Hourly Profit", "Profit Margin"),
                          multiple = FALSE,
                          selected = "Hourly Profit",
                          options = pickerOptions(actionsBox = TRUE,
                                                  liveSearch = TRUE,
                                                  title = "Metric")
                          ),
            mod_line_month_ui("line_month")
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
nav_item(img(src = "SS_Logo_Black.png",
             height = 40))

)
