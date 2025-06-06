mod_rates_histogram_ui <- function(id) {
  ns <- NS(id)
  tagList(
    girafeOutput(ns("plot_leads"), height = "100%", width = "100%")
  )
  }

mod_rates_histogram_server <- function(id, client_rates_df, range){
    moduleServer(id, function(input, output, session){
    ns <- session$ns

      plt_df <- reactive({
        client_rates_df() |> 
          filter(`Hourly Gross` >= range()$start & `Hourly Gross` <= range()$end)
      })
      
  
    plt <- reactive({
      ggplot(data = plt_df(), aes(x = `Hourly Gross`)) +
        geom_histogram_interactive(aes(tooltip = after_stat(count)),fill = "#4c86a8", color = "black") +
        labs(x = "Hourly Gross",
             y = "Count") +
        scale_x_continuous(labels = scales::dollar) +
        theme(panel.grid.major.x = element_blank(),
              panel.grid.minor.x = element_blank(),
              axis.text.x = element_text(size=12),
              axis.text.y = element_text(size=12))
    })

    output$plot_leads <- renderGirafe({
      girafe(ggobj = plt(),
      height_svg = 2) %>%
        girafe_options(opts_tooltip(zindex = 9999))
    })

    output$plt <- renderPlot({
      plt()
    })
    })
  }