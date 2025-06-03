library(dplyr)
library(janitor)
library(googlesheets4)
library(lubridate)

# Read in data -----------------------------------------------------------

employees_df <- readRDS("imports/employees/wages.rds") |> 
  select(-age)
invoices_df <- readRDS("imports/quickbooks/invoices.rds") |> 
  clean_names()
time_entries_df <- readRDS("imports/harvest/time_entries.rds")

gs4_auth(path = "sheets_service_account.json")

client_reference <- read_sheet(
  ss = "https://docs.google.com/spreadsheets/d/1KXOhqDpeKegv9h2ear4rTXBo7Yy5Zsu6hvhKDhExclc/edit?gid=2033729727#gid=2033729727",
  sheet = "ClientNames",
  range = "A:B") |> 
  clean_names()

# Attach employee rates/salaries to clocked hours
hours_w_wages <- time_entries_df |> 
  select(spent_date, hours, notes, employee, client, project, task) |> 
  left_join(employees_df, by = c("employee" = "employee_name")) |> 
  mutate(cost = hours * hourly_rate,
         month = floor_date(spent_date, unit = "month")) |> 
  left_join(client_reference, by = c("client" = "harvest_client")) |> 
    group_by(month, quickbooks_client) |> 
    summarize(hours = sum(hours, na.rm = TRUE),
              cost = sum(cost, na.rm = TRUE)) |> 
  ungroup()


full_df <- invoices_df |> 
  filter(detail_type == "SalesItemLineDetail") |>
  mutate(txn_date = ymd(txn_date)) |> 
  mutate(month = floor_date(txn_date, unit = "month")-months(1)) |> # invoices reflect previous months hours
  group_by(month, customer_ref) |>
  summarize(amt = sum(amt, na.rm = TRUE)) |> 
  left_join(hours_w_wages, by = c("customer_ref" = "quickbooks_client", "month" = "month")) |> 
  mutate(hourly_rev = amt/hours,
         hourly_cost = cost/hours,
         total_profit = amt - cost,
         hourly_profit = total_profit/hours)

saveRDS(full_df, "imports/quickbooks/rates.rds")
