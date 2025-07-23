# Libraries --------------------------------------------------------------
library(shiny)
library(tidyverse)
library(lubridate)
library(bslib)
library(bsicons)
library(thematic)
library(ggtext)
library(gt)
library(showtext)
library(shinyWidgets)
library(scales)
library(ggiraph)
library(DT)
library(plotly)
library(fontawesome)
library(janitor)
library(DBI)
library(duckdb)


# Load in environment variables
# dotenv::load_dot_env()

# Connect to database ----------------------------------------------------

con <- dbConnect(duckdb::duckdb())
dbExecute(con, "INSTALL 'motherduck';")
dbExecute(con, "LOAD 'motherduck'")
#dbExecute(con, "ATTACH 'md:'")
auth_query <- glue::glue_sql(
  "SET motherduck_token= {`Sys.getenv('MD_TOKEN')`};",
  .con = con
)
DBI::dbExecute(con, auth_query)
# Connect to MotherDuck
DBI::dbExecute(con, "PRAGMA MD_CONNECT")
dbExecute(con, "USE gff")

# Data -------------------------------------------------------------------

wages_df <- tbl(con, "Wages")
hours_df <- tbl(con, "Hours")
invoices_df <- tbl(con, "Invoices") |>
  filter(!str_detect(tolower(description), "pass through"))


date_updated <- today()


# Modules ----------------------------------------------------------------

file.sources <- list.files(path = "modules/general", full.names = TRUE)
sapply(file.sources, source)


file.sources <- list.files(path = "modules/rates", full.names = TRUE)
sapply(file.sources, source)

file.sources <- list.files(path = "modules/reconciliation", full.names = TRUE)
sapply(file.sources, source)

# Minor Data Wrangling ---------------------------------------------------

costs_df <- hours_df |>
  select(spent_date, hours, notes, employee, final_client, project, task) |>
  left_join(wages_df, by = c("employee" = "employee_name")) |>
  mutate(
    cost = hours * hourly_rate,
    month = floor_date(spent_date, unit = "month")
  ) |>
  group_by(month, final_client) |>
  summarize(
    hours = sum(hours, na.rm = TRUE),
    cost = sum(cost, na.rm = TRUE)
  ) |>
  ungroup()

rates_df <- invoices_df |>
  group_by(month, final_client) |>
  summarize(amt = sum(amt, na.rm = TRUE)) |>
  ungroup() |>
  left_join(
    costs_df,
    by = c("final_client", "month")
  )
