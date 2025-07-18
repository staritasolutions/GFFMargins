from intuitlib.client import AuthClient
from intuitlib.migration import migrate
from intuitlib.enums import Scopes
from intuitlib.exceptions import AuthClientError
import requests
from quickbooks import QuickBooks
from quickbooks.objects import Invoice, Payment, Bill, Customer, CompanyInfo
import pandas as pd
import pyreadr
from dotenv import load_dotenv, set_key
import os
import duckdb
import janitor

load_dotenv()  # loads variables from .env into os.environ

# Connect to Mother Duck
md_token = os.getenv("MD_UPDATE_TOKEN")
con = duckdb.connect(f'md:?motherduck_token={md_token}')
con.execute("USE gff")

# Load in client references
client_ref_df = con.execute("SELECT * FROM QuickbooksClientRef;").fetchdf()

auth_client = AuthClient(
    client_id= os.getenv("QB_CLIENT_ID"),
    client_secret=os.getenv("QB_CLIENT_SECRET"),
    redirect_uri="https://developer.intuit.com/v2/OAuth2Playground/RedirectUrl",
    environment="production"
)

url = auth_client.get_authorization_url([Scopes.ACCOUNTING])

client = QuickBooks(
        auth_client=auth_client,
        refresh_token=os.getenv("QB_REFRESH_TOKEN"),
        company_id='1061176460',
    )

auth_client.refresh_token

set_key(".env", "QB_REFRESH_TOKEN", auth_client.refresh_token)


# Function to call 1 Invoice request

def get_all_invoices(client):
    all_invoices = []
    start_position = 1  # QuickBooks uses 1-based indexing
    max_results = 1000  # Maximum allowed by QuickBooks API
    more_records = True

    while more_records:
        query = f"SELECT * FROM Invoice WHERE TxnDate >= '2023-05-01' STARTPOSITION {start_position} MAXRESULTS {max_results}"
        current_batch = Invoice.query(query, qb=client)

        if not current_batch:
            break

        all_invoices.extend(current_batch)

        # Check if we might have more records
        if len(current_batch) < max_results:
            more_records = False
        else:
            start_position += max_results

    return all_invoices

# Usage
all_invoices = get_all_invoices(client)

# Convert to list of dicts by extracting desired fields
invoice_data = []

for inv in all_invoices:
    for li in inv.Line:
        invoice_data.append({
            "Id": inv.Id,
            "DocNumber": inv.DocNumber,
            "TxnDate": inv.TxnDate,
            "CustomerRef": inv.CustomerRef.name if inv.CustomerRef else None,
            "DetailType": li.DetailType,
            "Description": li.Description,
            "Amt": li.Amount,
            "DueDate": inv.DueDate,
        })

# Turn into DataFrame
df = pd.DataFrame(invoice_data)

final_df = pd.merge(df, client_ref_df, how = 'left', left_on='CustomerRef', right_on='qb_client')

df_filtered = final_df[final_df["DetailType"] == "SalesItemLineDetail"].copy()

# Ensure txn_date is a datetime
df_filtered["TxnDate"] = pd.to_datetime(df_filtered["TxnDate"])

# Create 'month' column as previous month's floor
df_filtered["month"] = df_filtered["TxnDate"].dt.to_period("M").dt.to_timestamp() - pd.DateOffset(months=1)

# 1. Clean column names (snake_case)
df_filtered = df_filtered.clean_names()
df_filtered.rename(columns={
    "customerref": "customer_ref",
    "txndate": "txn_date",
    "duedate": "due_date"
}, inplace=True)

# 2. Select the desired columns
df_filtered = df_filtered[[
    "id", "txn_date", "month", "customer_ref", 
    "description", "amt", "due_date", "final_client"
]]

# Register your DataFrame as a DuckDB (in-memory) view
con.register("final_df_view", df_filtered)
con.execute("CREATE OR REPLACE TABLE Invoices AS SELECT * FROM final_df_view")
