#!/usr/bin/env python3
import os
import requests
import json
from pathlib import Path

# Load environment variables from .env file
env_path = Path('.env')
env_vars = {}
if env_path.exists():
    with open(env_path) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#'):
                key, value = line.split('=', 1)
                env_vars[key] = value

# Get Supabase credentials
SUPABASE_URL = env_vars.get('SUPABASE_URL', 'https://tvmbdqkwxsnaaeaujbsd.supabase.co')
SUPABASE_SERVICE_ROLE_KEY = env_vars.get('SUPABASE_SERVICE_ROLE_KEY', '')

if not SUPABASE_SERVICE_ROLE_KEY:
    print("Error: SUPABASE_SERVICE_ROLE_KEY not found in .env file")
    exit(1)

# Read the migration SQL
migration_path = Path('supabase/migrations/20260226_add_fcm_token_to_profiles.sql')
if not migration_path.exists():
    print(f"Error: Migration file not found at {migration_path}")
    exit(1)

with open(migration_path, 'r') as f:
    sql = f.read()

print(f"Running migration: {migration_path.name}")
print("SQL to execute:")
print("-" * 50)
print(sql)
print("-" * 50)

# Prepare the request
headers = {
    'Authorization': f'Bearer {SUPABASE_SERVICE_ROLE_KEY}',
    'Content-Type': 'application/json',
    'apikey': SUPABASE_SERVICE_ROLE_KEY
}

# The SQL endpoint is at /rest/v1/ with the sql parameter
# Actually, Supabase uses the postgrest endpoint for SQL queries
# Let's try using the REST API's rpc endpoint for executing SQL
# We'll use the /rest/v1/ endpoint with the sql parameter in the query string

# First, let's try a simpler approach: use the Supabase SQL API via POST
# The endpoint is: https://{project-ref}.supabase.co/rest/v1/
# But for raw SQL we need to use the postgrest SQL endpoint

# Actually, let's split the SQL into individual statements and execute them
# We'll use the /rest/v1/rpc/exec_sql endpoint if it exists, or use direct POST

# Try using the SQL endpoint via POST to /rest/v1/
url = f"{SUPABASE_URL}/rest/v1/"
params = {'sql': sql}

try:
    response = requests.post(url, headers=headers, json={'query': sql})
    print(f"Response status: {response.status_code}")
    if response.status_code == 200:
        print("Migration executed successfully!")
        print(f"Response: {response.text}")
    else:
        print(f"Error: {response.text}")
        # Try alternative approach - use the SQL API directly
        print("\nTrying alternative approach...")
        
        # Use the Supabase SQL API via the management API
        # The SQL API endpoint is: https://api.supabase.com/v1/projects/{ref}/sql
        # But we need the project ref from the URL
        project_ref = SUPABASE_URL.split('//')[1].split('.')[0]
        sql_api_url = f"https://api.supabase.com/v1/projects/{project_ref}/sql"
        
        # We need a different authentication for the management API
        # Let's try using the service role key as a bearer token
        management_headers = {
            'Authorization': f'Bearer {SUPABASE_SERVICE_ROLE_KEY}',
            'Content-Type': 'application/json'
        }
        
        # The SQL API expects a different format
        sql_api_data = {
            'query': sql
        }
        
        response2 = requests.post(sql_api_url, headers=management_headers, json=sql_api_data)
        print(f"SQL API Response status: {response2.status_code}")
        if response2.status_code == 200:
            print("Migration executed via SQL API!")
            print(f"Response: {response2.text}")
        else:
            print(f"SQL API Error: {response2.text}")
            
except Exception as e:
    print(f"Exception: {e}")
    print("\nNote: You may need to run this migration manually via the Supabase dashboard.")
    print("Go to: https://supabase.com/dashboard/project/tvmbdqkwxsnaaeaujbsd/sql")
    print("And paste the SQL from the migration file.")