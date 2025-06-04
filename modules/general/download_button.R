mod_download_button_ui <- function(id){
  ns <- NS(id)
  tagList(
    tags$head(
      tags$style(HTML("
        .download-btn {
  width: 200px; /* Adjust the width as needed */
  background-color: #4c86a8; /* Change background color */
  color: white; /* Change text color */
  border: none; /* Remove border */
  padding: 10px
  font-size: 14px; /* Adjust font size */
  border-radius: 3px; /* Add border radius for rounded corners */
  cursor: pointer; /* Change cursor to pointer */
  font-family: 'Montserrat';
}
      "))
    ),
    column(12, align = "right",
                    downloadButton(ns("tableDownload"), "Download .csv", class = "download-btn"))
  )
}

mod_download_button_server <- function(id, input_df, filename) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    # Make table exportable to csv
    output$tableDownload <- downloadHandler(
      filename = function() {
        paste(filename, ".csv", sep = "")
      },
      content = function(file) {
        write.csv(input_df(), file, row.names = FALSE)
      }
    )
  })
}