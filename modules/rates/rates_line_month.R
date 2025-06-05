mod_line_month_ui <- function(id) {
  ns <- NS(id)
  tagList(
    girafeOutput(ns("gplt"), height = "100%", width = "100%")
  )
  }

  mod_line_month_server <- function(id, month_rates_df, metric){
    moduleServer(id, function(input, output, session){
    ns <- session$ns

      thresh <- reactive({
        if(metric() == "Hours") {
          30
        } else if (metric() == "Revenue") {
          5000
        } else if (metric() == "Profit Margin") {
          .9
        } else {
          100
        }
      })
      
  
      plt <- reactive({
        ggplot(data = month_rates_df() %>%
                 mutate(tooltip = paste0("Date: ", lubridate::month(Date, label = TRUE), " ", year(Date), "\n", 
                                         metric(), ": ", round(.data[[metric()]]))),
               aes(x = lubridate::month(Date, label = TRUE),
                   y = .data[[metric()]],
                   group = as.factor(year(Date)),
                   color = as.factor(year(Date)),
                   tooltip = tooltip)) +
          geom_line(linewidth = 3, alpha = 0.8) +
          geom_hline(yintercept = thresh(), linetype = "dashed", color = "#00A676",
                       size = 1.5, alpha = 0.8) +
          geom_label(y = thresh(), x = max(month(month_rates_df()$Date)), color = "#00A676", label = "Threshold") +
          geom_point_interactive(size = 10, alpha = 0.0, aes(tooltip = tooltip)) +
          theme(
            panel.grid.major.x = element_blank(),
            panel.grid.minor.x = element_blank(),
            legend.title = element_blank(),
            axis.text.x = element_text(size=12),
            axis.text.y = element_text(size=12)
          ) +
          scale_y_continuous(labels = ifelse(metric() == "Hours", scales::label_comma(), scales::dollar)) +
          labs(x = NULL)
      })
  
      
      output$gplt <- renderGirafe({
        girafe(ggobj = plt(),
               height_svg = 3,
               width_svg = 12) %>%
          girafe_options(opts_tooltip(zindex = 9999))
      })
    })
}