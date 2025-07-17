#!/bin/bash

# Get the directory of the script
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change to the script directory
cd "$DIR"



# Activate Python virtual environment
source venv311/bin/activate

Rscript data/harvest/hours.R

python data/quickbooks/invoices.py

# Deactivate venv
deactivate
