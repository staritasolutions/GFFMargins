library(dplyr)
library(janitor)
library(googlesheets4)
library(lubridate)

# Read in data -----------------------------------------------------------

employees_df <- readRDS("imports/employees/wages.rds")

invoices_df <- readRDS("imports/quickbooks/invoices.rds") |>
  clean_names()
time_entries_df <- readRDS("imports/harvest/time_entries.rds")

gs4_auth(path = "sheets_service_account.json")

harvest_client_reference <- read_sheet(
  ss = "https://docs.google.com/spreadsheets/d/1yAHOB-B67Q9H21iYdqEEuJVYG1EYbZ-c244VYZ4P2s8/edit?gid=0#gid=0",
  sheet = "Harvest",
  range = "A:B"
) |>
  clean_names()

saveRDS(harvest_client_reference, "imports/harvest/harvest_ref.rds")

qb_client_reference <- read_sheet(
  ss = "https://docs.google.com/spreadsheets/d/1yAHOB-B67Q9H21iYdqEEuJVYG1EYbZ-c244VYZ4P2s8/edit?gid=0#gid=0",
  sheet = "Quickbooks",
  range = "A:B"
) |>
  clean_names()

saveRDS(qb_client_reference, "imports/quickbooks/quickbooks_ref.rds")

# Attach employee rates/salaries to clocked hours
hours_w_wages <- time_entries_df |>
  select(spent_date, hours, notes, employee, client, project, task) |>
  left_join(employees_df, by = c("employee" = "employee_name")) |>
  mutate(
    cost = hours * hourly_rate,
    month = floor_date(spent_date, unit = "month")
  ) |>
  left_join(harvest_client_reference, by = c("client" = "harvest_client")) |>
  mutate(
    final_client = ifelse(is.na(final_client), client, final_client)
  ) |>
  group_by(month, final_client) |>
  summarize(hours = sum(hours, na.rm = TRUE), cost = sum(cost, na.rm = TRUE)) |>
  ungroup()


full_df <- invoices_df |>
  left_join(qb_client_reference, by = c("customer_ref" = "qb_client")) |>
  filter(detail_type == "SalesItemLineDetail") |>
  mutate(txn_date = ymd(txn_date)) |>
  mutate(month = floor_date(txn_date, unit = "month") - months(1)) |> # invoices reflect previous months hours
  group_by(month, final_client) |>
  summarize(amt = sum(amt, na.rm = TRUE)) |>
  ungroup() |>
  left_join(
    hours_w_wages,
    by = c("final_client", "month")
  ) |>
  mutate(
    hourly_rev = amt / hours,
    hourly_cost = cost / hours,
    total_profit = amt - cost,
    hourly_profit = total_profit / hours
  )


# full_df |> group_by(customer_ref) |>
#   summarize(hours = sum(hours, na.rm = TRUE)) |>
#   ungroup() |> View()

saveRDS(full_df, "imports/quickbooks/rates.rds")
