import json
import requests
import urllib.parse

# Load console cookie from prefs
with open('/Users/dulorai/.appwrite/prefs.json', 'r') as f:
    prefs = json.load(f)

proj_id = '699495910038e39622c5'
cookie = prefs[proj_id]['cookie']
endpoint = prefs[proj_id]['endpoint']

headers = {
    'cookie': cookie,
    'x-appwrite-project': proj_id,
    'x-appwrite-mode': 'admin',
    'Content-Type': 'application/json'
}

query1 = json.dumps({'method': 'limit', 'values': [100]})
url = f"{endpoint}/databases/olitun_db/collections/lessons/documents?queries[]={urllib.parse.quote(query1)}"

res = requests.get(url, headers=headers)
print("Status:", res.status_code)
if res.status_code == 200:
    data = res.json()
    print("Fetched", len(data.get('documents', [])), "documents.")
    if data.get('documents'):
        print("First ID:", data['documents'][0]['$id'])
else:
    print("Error:", res.text)
