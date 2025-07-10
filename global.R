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

# Data -------------------------------------------------------------------

wages_df <- readRDS("imports/employees/wages.rds")
hours_df <- readRDS("imports/harvest/time_entries.rds")
invoices_df <- readRDS("imports/quickbooks/invoices.rds") |>
  clean_names() |>
  mutate(month = as.Date(month))


date_updated <- as.Date(file.info("imports/harvest/time_entries.rds")$mtime)


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
