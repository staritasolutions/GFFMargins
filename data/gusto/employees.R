library(dplyr)
library(googlesheets4)
library(janitor)
library(stringr)

#gs4_auth(email = "evan@staritasolutions.com")
gs4_auth(path = "sheets_service_account.json")

raw_wages <- read_sheet(
  ss = "https://docs.google.com/spreadsheets/d/1ft6foIsMZyXBWboUvmzW447BZrraOty-nXiHWGLnGQE/edit?gid=0#gid=0") |> 
  clean_names() |>
  # change employee_name from Last Name, First Name to First Name Last Name
  mutate(employee_name = str_replace(employee_name, "(.*), (.*)", "\\2 \\1"))

saveRDS(raw_wages, "imports/employees/wages.rds")
