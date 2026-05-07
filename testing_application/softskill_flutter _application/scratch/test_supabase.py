import requests
import json

url = "https://ssktamuozmtzezgiqiql.supabase.co/rest/v1/conversation_logs"
headers = {
    "apikey": "sb_publishable_K1CDZRWbcZ9Xz8bINwM0PQ_cf42NTaY",
    "Authorization": "Bearer sb_publishable_K1CDZRWbcZ9Xz8bINwM0PQ_cf42NTaY",
    "Content-Type": "application/json",
    "Prefer": "return=minimal"
}
data = {
    "user_id": "test_user_1",
    "user_message": "script test interaction",
    "ai_message": "script test reply",
    "module_name": "ai-interaction"
}

response = requests.post(url, headers=headers, data=json.dumps(data))
print(f"Status: {response.status_code}")
print(f"Response: {response.text}")
