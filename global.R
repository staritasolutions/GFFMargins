
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

# Data -------------------------------------------------------------------

rates_df <- readRDS("imports/quickbooks/rates.rds")

date_updated <- as.Date(file.info("imports/quickbooks/rates.rds")$mtime)


# Modules ----------------------------------------------------------------

file.sources <- list.files(path = "modules/general", full.names = TRUE)
sapply(file.sources,source)


file.sources <- list.files(path = "modules/rates", full.names = TRUE)
sapply(file.sources,source)