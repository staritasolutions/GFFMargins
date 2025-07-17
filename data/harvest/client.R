library(tidyverse)
library(glue)
library(httr2)
library(jsonlite)
library(janitor)
library(lubridate)
library(gmailr)

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

# Connect to Database
con <- DBI::dbConnect(duckdb::duckdb())
DBI::dbExecute(con, "INSTALL 'motherduck';")
DBI::dbExecute(con, "LOAD 'motherduck'")
#dbExecute(con, "ATTACH 'md:'")
auth_query <- glue::glue_sql(
  "SET motherduck_token= {`Sys.getenv('MD_UPDATE_TOKEN')`};",
  .con = con
)
DBI::dbExecute(con, auth_query)
# Connect to MotherDuck
DBI::dbExecute(con, "PRAGMA MD_CONNECT")
DBI::dbExecute(con, "USE gff")

# get current db clients
current_clients <- tbl(con, "HarvestClientRef") |> collect()

new_clients <- clients_df |>
  filter(!client_name %in% current_clients$harvest_client)


# Email new client list

gm_auth(
  token = gm_token_read(
    path = "gmailr-token.rds"
  )
)

# Convert the data frame to an HTML table
new_clients_html <- knitr::kable(
  new_clients,
  format = "html",
  table.attr = "style='width:100%;'"
) %>%
  as.character()

html_msg <- gm_mime() %>%
  gm_to(c("evan@staritasolutions.com")) %>%
  gm_from("support@staritasolutions.com") %>%
  gm_subject("New Harvest Clients") %>%
  gm_html_body(new_clients_html)

gm_send_message(html_msg)
