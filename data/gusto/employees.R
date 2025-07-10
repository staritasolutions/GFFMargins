library(dplyr)
library(googlesheets4)
library(janitor)
library(stringr)

#gs4_auth(email = "evan@staritasolutions.com")
gs4_auth(path = "sheets_service_account.json")

raw_wages <- read_sheet(
  ss = "https://docs.google.com/spreadsheets/d/1KXOhqDpeKegv9h2ear4rTXBo7Yy5Zsu6hvhKDhExclc/edit?gid=2059115589#gid=2059115589",
  sheet = "FinalEmployeeInfo"
) |>
  clean_names() |>
  # change employee_name from Last Name, First Name to First Name Last Name
  mutate(employee_name = str_replace(employee_name, "(.*), (.*)", "\\2 \\1"))

final_wages <- raw_wages |>
  # calculate an hourly rate for everybody
  # if salaried, assume a 40 hour work week 50 weeks in the year
  mutate(
    hourly_rate = ifelse(
      pay_type == "Hourly",
      hourly_rate,
      annual_salary / 2000
    )
  ) |>
  select(employee_name, hourly_rate)


saveRDS(final_wages, "imports/employees/wages.rds")
