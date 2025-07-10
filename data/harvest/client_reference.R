library(googlesheets4)
library(janitor)

gs4_auth(path = "sheets_service_account.json")

harvest_client_reference <- read_sheet(
  ss = "https://docs.google.com/spreadsheets/d/1yAHOB-B67Q9H21iYdqEEuJVYG1EYbZ-c244VYZ4P2s8/edit?gid=0#gid=0",
  sheet = "Harvest",
  range = "A:B"
) |>
  clean_names()

saveRDS(harvest_client_reference, "imports/harvest/harvest_ref.rds")
