import json
import requests

# Load console cookie from prefs
with open('/Users/dulorai/.appwrite/prefs.json', 'r') as f:
    prefs = json.load(f)

proj_id = '699495910038e39622c5'
cookie = prefs[proj_id]['cookie']
endpoint = prefs[proj_id]['endpoint']

headers = {
    'x-appwrite-project': proj_id,
    'Cookie': cookie,
    'Content-Type': 'application/json'
}

# Try to list documents from lessons collection
url = f"{endpoint}/databases/olitun_db/collections/lessons/documents"
res = requests.get(url, headers=headers)
print("Status:", res.status_code)
if res.status_code == 200:
    data = res.json()
    if data['documents']:
        doc = data['documents'][0]
        print("First Document ID:", doc['$id'])
        print("Keys:", list(doc.keys()))
        print("Sample blocks type:", type(doc.get('blocks')))
        print("Sample blocks content:", repr(doc.get('blocks')[:200]) if doc.get('blocks') else 'None')
    else:
        print("No documents found in lessons.")
else:
    print("Error:", res.text)
