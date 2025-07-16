mod_general_select_ui <- function(
  id,
  title,
  data,
  metric,
  selected_count = NULL,
  select_multiple = TRUE
) {
  ns <- NS(id)
  default_selected <- if (is.null(selected_count)) {
    unique(data[[metric]])
  } else {
    unique(data[[metric]])[seq_len(selected_count)]
  }

  tagList(
    pickerInput(
      ns("selected"),
      choices = sort(unique(data[[metric]])),
      multiple = select_multiple,
      selected = default_selected,
      options = pickerOptions(
        actionsBox = TRUE,
        liveSearch = TRUE,
        selectedTextFormat = "static",
        title = title
      ),
      choicesOpt = list(
        content = stringr::str_trunc(sort(unique(data[[metric]])), width = 35)
      )
    )
  )
}

mod_general_select_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    return(
      reactive({
        input$selected
      })
    )
  })
}
