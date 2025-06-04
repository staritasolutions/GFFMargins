mod_date_select_ui <- function(id, 
                               start = floor_date(Sys.Date(), unit = "year"), 
                               end = date_updated,
                               max = date_updated,
                               label = NULL) {
  ns <- NS(id)
  tagList(
    dateRangeInput(ns("date"),
                   label = label,
                   start = start,
                   end = end,
                   max = max,
                   format = "M d, yyyy")
  )
}

mod_date_select_server <- function(id){
  moduleServer(id, function(input, output, session){
    ns <- session$ns
    return(
      list(
        start  = reactive({input$date[1]}),
        end = reactive({input$date[2]})
      )
    )
    
  })
}