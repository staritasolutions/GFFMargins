mod_rates_quadrant_ui <- function(id) {
  ns <- NS(id)
  tagList(
    #girafeOutput(ns("plt"), height = "100%", width = "100%")
    plotlyOutput(ns("plt2"))
  )
}

mod_rates_quadrant_server <- function(id, client_rates_df) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    temp_df <- reactive(client_rates_df()) # |> filter(Revenue < 10000 & Hours < 100)

    x_cut <- reactive(mean(temp_df()$Hours, na.rm = TRUE))
    y_cut <- reactive(mean(temp_df()$Revenue, na.rm = TRUE))

    plt_df <- reactive({
      temp_df() %>%
        mutate(
          quadrant = case_when(
            Hours > x_cut() & Revenue > y_cut() ~ "Target",
            Hours <= x_cut() & Revenue > y_cut() ~ "Danger",
            Hours <= x_cut() & Revenue <= y_cut() ~ "Meh",
            TRUE ~ "Bad Clients"
          )
        )
    })

    labels_df <- reactive({
      # Get padding for labels so they are clearly placed
      x_range <- range(temp_df()$Hours, na.rm = TRUE)
      y_range <- range(temp_df()$Revenue, na.rm = TRUE)

      x_pad <- (x_range[2] - x_range[1]) * 0.2
      y_pad <- (y_range[2] - y_range[1]) * 0.1

      tibble(
        label = c("Target", "Danger", "Meh", "Bad Clients"),
        x_point = c(
          x_range[2] - x_pad,
          x_range[1],
          x_range[1],
          x_range[2] - x_pad
        ),
        y_point = c(
          y_range[2] - y_pad,
          y_range[2] - y_pad,
          y_range[1] - y_pad,
          y_range[1] + y_pad
        )
      )
    })

    plt <- reactive({
      ggplot(data = plt_df(), aes(x = Hours, y = Revenue, color = quadrant)) +
        geom_vline(xintercept = x_cut()) +
        geom_hline(yintercept = y_cut()) +
        geom_point_interactive(aes(tooltip = Client)) +
        geom_label(
          data = labels_df(),
          aes(x = x_point, y = y_point, label = label, color = label),
          inherit.aes = FALSE,
          size = 2,
          fill = "white",
          alpha = 0.8
        ) +
        labs(x = "Hours", y = "Revenue") +
        scale_y_continuous(labels = scales::dollar) +
        scale_color_manual(
          values = c(
            "Target" = "#00a676",
            "Danger" = "#a60030",
            "Meh" = "#4c86a8",
            "Bad Clients" = "#CD9600"
          )
        ) +
        theme(
          legend.position = "none",
          ,
          panel.grid.major.x = element_blank(),
          panel.grid.minor.x = element_blank(),
          axis.text.x = element_text(size = 12),
          axis.text.y = element_text(size = 12)
        )
    })

    library(plotly)

    p2 <- reactive({
      p <- ggplot(
        data = plt_df(),
        aes(x = Hours, y = Revenue, color = quadrant)
      ) +
        geom_vline(xintercept = x_cut()) +
        geom_hline(yintercept = y_cut()) +
        geom_point(aes(text = Client)) + # plotly will use 'text' for tooltip
        geom_text(
          data = labels_df(),
          aes(x = x_point, y = y_point, label = label, color = label),
          inherit.aes = FALSE,
          size = 6
        ) +
        labs(x = "Hours", y = "Revenue") +
        scale_y_continuous(labels = scales::dollar) +
        scale_color_manual(
          values = c(
            "Target" = "#00a676",
            "Danger" = "#a60030",
            "Meh" = "#4c86a8",
            "Bad Clients" = "#CD9600"
          )
        ) +
        theme_minimal() +
        theme(
          legend.position = "none",
          panel.grid.major.x = element_blank(),
          panel.grid.minor.x = element_blank(),
          axis.text.x = element_text(size = 12),
          axis.text.y = element_text(size = 12)
        )

      ggplotly(p, tooltip = "text") # enable plotly interactivity
    })

    output$plt <- renderGirafe({
      girafe(ggobj = plt(), height_svg = 2) %>%
        girafe_options(
          opts_tooltip(zindex = 9999),
          opts_zoom(min = .7, max = 2)
        )
    })

    output$plt2 <- renderPlotly({
      p2()
    })
  })
}
