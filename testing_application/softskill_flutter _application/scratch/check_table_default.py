import requests

url = "https://ssktamuozmtzezgiqiql.supabase.co/rest/v1/"
headers = {
    "apikey": "sb_publishable_K1CDZRWbcZ9Xz8bINwM0PQ_cf42NTaY",
    "Authorization": "Bearer sb_publishable_K1CDZRWbcZ9Xz8bINwM0PQ_cf42NTaY"
}

# Get table info via PostgREST OpenAPI (usually not enabled, but worth a try)
# Or just try to insert a row with a null user_message to see what happens
data = {
    "user_id": "test_user_1",
    "user_message": None, # Try to trigger default
    "ai_message": "test default check",
    "module_name": "debug"
}

response = requests.post(url + "conversation_logs", headers=headers, json=data)
print(f"Status: {response.status_code}")
print(f"Response: {response.text}")
