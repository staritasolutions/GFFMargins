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

load_dotenv()  # loads variables from .env into os.environ

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

    # Get all customers

def get_all_customers(client):
    all_customers = []
    start_position = 1  # QuickBooks uses 1-based indexing
    max_results = 1000  # Maximum allowed by QuickBooks API
    more_records = True

    while more_records:
        query = f"SELECT * FROM Customer STARTPOSITION {start_position} MAXRESULTS {max_results}"
        current_batch = Customer.query(query, qb=client)

        if not current_batch:
            break

        all_customers.extend(current_batch)

        # Check if we might have more records
        if len(current_batch) < max_results:
            more_records = False
        else:
            start_position += max_results
            
    return all_customers

# Usage
all_customers = get_all_customers(client)

# Convert to list of dicts by extracting desired fields
customer_data = []

for cust in all_customers:
    customer_data.append({
        "Name": cust.DisplayName,
        "Name2": cust.FullyQualifiedName,
        "Name3": cust.CompanyName
    })

# Turn into DataFrame

customer_df = pd.DataFrame(customer_data)

customer_df.to_csv("data/quickbooks/client_list.csv")
