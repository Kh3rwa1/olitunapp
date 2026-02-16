import requests
import json

project_id = "ec138b74-cdb7-4c55-a7e0-a59d68561548"
publishable_key = "pck_2v7xw0j8hbgj6tqec50m4mev9yhvw195v8c753y7n6nw0"

url = "https://api.stack-auth.com/api/v1/auth/otp/send-sign-in-code"
headers = {
    "Content-Type": "application/json",
    "X-Stack-Project-Id": project_id,
    "X-Stack-Publishable-Client-Key": publishable_key,
    "X-Stack-Access-Type": "client"
}
data = {
    "email": "olitun_test_otp@mailinator.com",
    "callback_url": "https://olitun.vercel.app/auth/callback"
}

print(f"Testing OTP Send with Project ID: {project_id}")
print(f"Endpoint: {url}")
response = requests.post(url, headers=headers, json=data)

print(f"Status Code: {response.status_code}")
print(f"Response Body: {response.text}")

if response.status_code == 200:
    print("\n✅ SUCCESS: OTP code sent!")
else:
    print("\n❌ FAILED: Check credentials or API endpoint.")
