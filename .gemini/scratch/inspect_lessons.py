import sys, json

data = json.load(sys.stdin)
total = data.get("total", 0)
print(f"Total lessons: {total}")
for doc in data.get("documents", []):
    blocks_raw = doc.get("blocks", "[]")
    try:
        bl = json.loads(blocks_raw) if isinstance(blocks_raw, str) else blocks_raw
        count = len(bl) if isinstance(bl, list) else "not-a-list"
    except Exception:
        count = "parse-error"
    did = doc["$id"]
    title = doc.get("titleLatin", "?")
    cat = doc.get("categoryId", "?")
    print(f"  {did:30s} | {title:30s} | cat: {cat:20s} | blocks: {count}")
