library(tidyverse)
library(glue)
library(janitor)
library(lubridate)
library(duckdb)
library(gmailr)

# Load in environment variables
dotenv::load_dot_env()

# Read in Client List

clients_df <- read_csv("data/quickbooks/client_list.csv") |>
  dplyr::select(client_name = Name)

# Get current list from DB

# Connect to Database
con <- dbConnect(duckdb::duckdb())
dbExecute(con, "INSTALL 'motherduck';")
dbExecute(con, "LOAD 'motherduck'")
#dbExecute(con, "ATTACH 'md:'")
auth_query <- glue::glue_sql(
  "SET motherduck_token= {`Sys.getenv('MD_UPDATE_TOKEN')`};",
  .con = con
)
DBI::dbExecute(con, auth_query)
# Connect to MotherDuck
DBI::dbExecute(con, "PRAGMA MD_CONNECT")
dbExecute(con, "USE gff")

# get current db clients
current_clients <- tbl(con, "QuickBooksClientRef") |> collect()

new_clients <- clients_df |>
  filter(!client_name %in% current_clients$qb_client)

# email new clients
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
  gm_subject("New Quickbooks Clients") %>%
  gm_html_body(new_clients_html)

gm_send_message(html_msg)
