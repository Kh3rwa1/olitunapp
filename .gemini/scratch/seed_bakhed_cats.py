#!/usr/bin/env python3
import subprocess, json

API_KEY = "standard_6793241c1048acd9fa8465e1abf4c76b0c87ef6f5eba60de4c61ff91489438f8a42f066942fb453069aa278afdfcc54b96240f513cd1cd3005954313d4e09835be9af6afe66364850ec4787aafb3c9e70c68e8edbb81d0931e83d4b00b482df2d13ba88c93048c8f10a8ff8636f1963b7f26d7eca61f7deffc048629eb896133"
PROJECT = "699495910038e39622c5"
DB = "olitun_db"
BASE = "https://sgp.cloud.appwrite.io/v1"

def curl_post(path, doc_id, data):
    payload = json.dumps({"documentId": doc_id, "data": data, "permissions": ["read(\"any\")"]})
    r = subprocess.run(
        ["curl", "-s", "-X", "POST",
         "-H", f"X-Appwrite-Project: {PROJECT}",
         "-H", f"X-Appwrite-Key: {API_KEY}",
         "-H", "Content-Type: application/json",
         "-d", payload,
         f"{BASE}{path}"],
        capture_output=True, text=True
    )
    resp = json.loads(r.stdout) if r.stdout else {}
    if resp.get("code") == 409:
        payload = json.dumps({"data": data, "permissions": ["read(\"any\")"]})
        subprocess.run(
            ["curl", "-s", "-X", "PATCH",
             "-H", f"X-Appwrite-Project: {PROJECT}",
             "-H", f"X-Appwrite-Key: {API_KEY}",
             "-H", "Content-Type: application/json",
             "-d", payload,
             f"{BASE}{path}/{doc_id}"],
            capture_output=True, text=True
        )
    else:
        print("Response:", resp)

categories = [
    {"docId": "cat_sohrai", "data": {"nameLatin": "Sohrai", "nameOlChiki": "ᱥᱚᱦᱨᱟᱭ", "order": 0, "iconName": "agriculture"}},
    {"docId": "cat_baha", "data": {"nameLatin": "Baha", "nameOlChiki": "ᱵᱟᱦᱟ", "order": 1, "iconName": "local_florist"}},
    {"docId": "cat_magmore", "data": {"nameLatin": "Mag'more", "nameOlChiki": "ᱢᱟᱜᱽᱢᱚᱬᱮ", "order": 2, "iconName": "eco"}},
    {"docId": "cat_chhatyar", "data": {"nameLatin": "Chhatyar", "nameOlChiki": "ᱪᱷᱟᱹᱴᱭᱟᱹᱨ", "order": 3, "iconName": "child_friendly"}},
    {"docId": "cat_bapla", "data": {"nameLatin": "Bapla", "nameOlChiki": "ᱵᱟᱯᱞᱟ", "order": 4, "iconName": "favorite"}},
    {"docId": "cat_bhandan", "data": {"nameLatin": "Bhandan", "nameOlChiki": "ᱵᱷᱟᱸᱰᱟᱱ", "order": 5, "iconName": "group"}},
]

subcategories = [
    {"docId": "sub_sohrai_1", "data": {"categoryId": "cat_sohrai", "nameLatin": "Got Puja", "nameOlChiki": "ᱜᱚᱴ ᱯᱩᱡᱟ", "order": 0}},
    {"docId": "sub_sohrai_2", "data": {"categoryId": "cat_sohrai", "nameLatin": "Gohal Puja", "nameOlChiki": "ᱜᱚᱦᱟᱞ ᱯᱩᱡᱟ", "order": 1}},
    {"docId": "sub_baha_1", "data": {"categoryId": "cat_baha", "nameLatin": "Jaher Puja", "nameOlChiki": "ᱡᱟᱦᱮᱨ ᱯᱩᱡᱟ", "order": 0}},
    {"docId": "sub_bapla_1", "data": {"categoryId": "cat_bapla", "nameLatin": "Raebah", "nameOlChiki": "ᱨᱟᱭᱵᱟᱨ", "order": 0}},
    {"docId": "sub_bapla_2", "data": {"categoryId": "cat_bapla", "nameLatin": "Sindur", "nameOlChiki": "ᱥᱤᱸᱫᱩᱨ", "order": 1}},
]

print("Adding new Bakhed categories...")
for cat in categories:
    curl_post(f"/databases/{DB}/collections/rhyme_categories/documents", cat["docId"], cat["data"])

print("Adding new Bakhed subcategories...")
for sub in subcategories:
    curl_post(f"/databases/{DB}/collections/rhyme_subcategories/documents", sub["docId"], sub["data"])

print("Done!")
