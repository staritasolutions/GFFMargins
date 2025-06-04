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
                   success = "#00a676", info = "#E6AF2E", danger = "#a60030",
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
            mod_rates_table_client_ui("rates_table_client")
          ),

    )

  ),

# Drill down ---------------------------------------------------------------------

  nav_menu(
    title = "Drilldown",
    icon = fa("users-viewfinder", height = "1rem"),
    align = "left",

    ### Overview

    nav_panel(
      title = "Overview",

      page_sidebar(

        sidebar = sidebar(

        ),

        layout_column_wrap(
          width = 1/2,

          card(
            card_header("Overview"),
            full_screen = FALSE
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
nav_item(img(src = "SS_Logo_Black.png",
             height = 40))

)
