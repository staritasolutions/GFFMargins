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

## Time Entries

time_req <- request("https://api.harvestapp.com/v2/time_entries") %>%
  req_headers(
    "Authorization" = paste0("Bearer ", token),
    "Harvest-Account-Id" = account_id,
    "User-Agent" = agent,
    "Content-Type" = "application/json"
    ) |> 
  req_url_query(
    from = "2024-01-01"
  )

time_raw <- time_req %>%
  req_perform() %>%
  resp_body_json()

time_df <- time_raw$time_entries |> 
  enframe() |> 
  unnest_auto(value) |> 
  select(-name) |> 
  unnest_auto(client) |> 
  rename(client = name) |> 
  unnest_auto(user) |> 
  rename(employee = name) |> 
  unnest_auto(task) |> 
  rename(task = name) |> 
  unnest_auto(project) |> 
  rename(project = name) |> 
  rename(id = `id...1`)

while (!is.null(time_raw$links$`next`)) {
  new_req <- time_raw$links$`next`
  
  time_req <- request(new_req) %>%
    req_headers(
      "Authorization" = paste0("Bearer ", token),
      "Harvest-Account-Id" = account_id,
      "User-Agent" = agent)
  
  time_raw <- time_req %>%
    req_perform() %>%
    resp_body_json()
  
  temp_time_df <- time_raw$time_entries |> 
    enframe() |> 
    unnest_auto(value) |> 
    select(-name) |> 
    unnest_auto(client) |> 
    rename(client = name) |> 
    unnest_auto(user) |> 
    rename(employee = name) |>
    unnest_auto(task) |> 
    rename(task = name) |> 
    unnest_auto(project) |> 
    rename(project = name) |> 
    rename(id = `id...1`)
  
  time_df <- bind_rows(time_df, temp_time_df)
  print(nrow(time_df))
}

time_df %>% filter(billable == FALSE) %>% group_by(client) %>% summarize(hours = sum(hours))

final_time_df <- time_df |> 
  mutate(spent_date = ymd(spent_date)) |> 
  clean_names()


saveRDS(final_time_df, "imports/harvest/time_entries.rds")
