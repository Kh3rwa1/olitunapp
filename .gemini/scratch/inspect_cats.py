import sys, json

data = json.load(sys.stdin)
total = data.get("total", 0)
print(f"Total categories: {total}")
for doc in data.get("documents", []):
    did = doc["$id"]
    title = doc.get("titleLatin", "?")
    print(f"  {did:40s} | {title}")
