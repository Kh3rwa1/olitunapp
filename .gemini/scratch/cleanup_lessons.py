#!/usr/bin/env python3
"""Delete old empty lessons and fix orphaned ones in Appwrite."""
import subprocess, json, sys

API_KEY = "standard_211dcef79ec66106724d96019b16a246ee8fb0f5e4e2c3b07719a6b5fac524ff76c35de4da08a14737b16c334df317d04f779f4db9bc3eaf55634c59583284526390cf06d608dbb622d9ab13f138316c9ef72ef7e6c8677c3ab61e3e5956e76232c5cd9e4b8cdadb5d9cb27c16a90d3be8d955acbb8b87c6deda96044ecc882d"
PROJECT = "699495910038e39622c5"
DB = "olitun_db"
BASE = "https://sgp.cloud.appwrite.io/v1"

def curl_get(path):
    r = subprocess.run(
        ["curl", "-s", "-H", f"X-Appwrite-Project: {PROJECT}", "-H", f"X-Appwrite-Key: {API_KEY}", f"{BASE}{path}"],
        capture_output=True, text=True
    )
    return json.loads(r.stdout)

def curl_delete(path):
    r = subprocess.run(
        ["curl", "-s", "-X", "DELETE", "-H", f"X-Appwrite-Project: {PROJECT}", "-H", f"X-Appwrite-Key: {API_KEY}", f"{BASE}{path}"],
        capture_output=True, text=True
    )
    print(f"  DELETE {path} -> {r.stdout[:80] if r.stdout else 'OK'}")

def curl_patch(path, data):
    r = subprocess.run(
        ["curl", "-s", "-X", "PATCH",
         "-H", f"X-Appwrite-Project: {PROJECT}",
         "-H", f"X-Appwrite-Key: {API_KEY}",
         "-H", "Content-Type: application/json",
         "-d", json.dumps({"data": data}),
         f"{BASE}{path}"],
        capture_output=True, text=True
    )
    print(f"  PATCH {path} -> {r.stdout[:120] if r.stdout else 'OK'}")

# Get all lessons
lessons = curl_get(f"/databases/{DB}/collections/lessons/documents")
docs = lessons.get("documents", [])
print(f"Found {len(docs)} lessons total\n")

# Identify old empty lessons (with timestamp IDs) to delete
old_empty = []
new_lessons = []
orphaned = []

for doc in docs:
    did = doc["$id"]
    blocks_raw = doc.get("blocks", "[]")
    try:
        bl = json.loads(blocks_raw) if isinstance(blocks_raw, str) else blocks_raw
        block_count = len(bl) if isinstance(bl, list) else 0
    except:
        block_count = 0
    
    cat_id = doc.get("categoryId", "")
    
    # Old timestamp-based lessons with 0 blocks
    if "_177859" in did and block_count == 0:
        old_empty.append(did)
    # Orphaned lesson pointing to wrong category
    elif cat_id == "cat_sentences" and "cat_sentences" not in [c["$id"] for c in curl_get(f"/databases/{DB}/collections/categories/documents").get("documents", [])]:
        orphaned.append(did)
    else:
        new_lessons.append((did, block_count))

print(f"Old empty lessons to DELETE: {len(old_empty)}")
for lid in old_empty:
    print(f"  - {lid}")

print(f"\nNew lessons to KEEP: {len(new_lessons)}")
for lid, bc in new_lessons:
    print(f"  + {lid} ({bc} blocks)")

# Delete old empty lessons
print("\n--- Deleting old empty lessons ---")
for lid in old_empty:
    curl_delete(f"/databases/{DB}/collections/lessons/documents/{lid}")

# Fix orphaned lesson_sentences_basics - point to correct category
print("\n--- Fixing orphaned lessons ---")
# Find correct sentences category
cats = curl_get(f"/databases/{DB}/collections/categories/documents")
sentences_cat = None
for c in cats.get("documents", []):
    if "sentence" in c.get("titleLatin", "").lower():
        sentences_cat = c["$id"]
        break

if sentences_cat:
    for doc in docs:
        if doc.get("categoryId") == "cat_sentences":
            print(f"  Fixing {doc['$id']} -> categoryId: {sentences_cat}")
            curl_patch(f"/databases/{DB}/collections/lessons/documents/{doc['$id']}", {"categoryId": sentences_cat})

print("\nDone!")
