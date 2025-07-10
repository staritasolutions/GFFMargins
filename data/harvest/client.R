library(tidyverse)
library(glue)
library(httr2)
library(jsonlite)
library(janitor)
library(lubridate)

# Load in environment variables
dotenv::load_dot_env()

## Authorization ##

token <- Sys.getenv("HARVEST_API_TOKEN")
account_id <- 1710988
agent <- "GFFRates (evan@staritasolutions.com)"


# Get All Clients --------------------------------------------------------

clients_req <- request("https://api.harvestapp.com/v2/clients") %>%
  req_headers(
    "Authorization" = paste0("Bearer ", token),
    "Harvest-Account-Id" = account_id,
    "User-Agent" = agent,
    "Content-Type" = "application/json"
  )

clients_raw <- clients_req %>%
  req_perform() %>%
  resp_body_json()

clients_df <- clients_raw$clients |>
  enframe() |>
  unnest_auto(value) |>
  select(client_name = `name...3`)

# Code to see which clients are new

# Code to Upsert
