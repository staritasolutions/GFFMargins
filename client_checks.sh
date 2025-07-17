#!/bin/bash

# Get the directory of the script
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change to the script directory
cd "$DIR"



# Activate Python virtual environment
source venv311/bin/activate

Rscript data/harvest/client.R

python data/quickbooks/client.py

Rscript data/quickbooks/new_client_check.R

# Deactivate venv
deactivate
