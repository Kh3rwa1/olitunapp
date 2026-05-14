#!/usr/bin/env python3
"""Seed Greetings lessons into Appwrite."""
import subprocess, json

API_KEY = "standard_ac66cdc8cbd18a7d772cc8dcaea7bc5f33d0942a57a7c724ebb46d93f12da2a70c31e456518f1a585615bc3ae4237fc85946dcb9f8900827f77c00c38075b07f402e43b4f74fbf52996bd6515017098b5b94eedb3d2df42e8c2f4e9cf7260cd93238ca3f65435cba5f8cdd6d1351fcb427c96ad01bb6ab1b263ce70f02e09143"
PROJECT = "699495910038e39622c5"
DB = "olitun_db"
BASE = "https://sgp.cloud.appwrite.io/v1"
GREETINGS_CAT = "cat_phrases_1778594027629"

def create_or_update(doc_id, data):
    """Try create, if 409 then update."""
    payload = json.dumps({"documentId": doc_id, "data": data, "permissions": ["read(\"any\")"]})
    r = subprocess.run(
        ["curl", "-s", "-X", "POST",
         "-H", f"X-Appwrite-Project: {PROJECT}",
         "-H", f"X-Appwrite-Key: {API_KEY}",
         "-H", "Content-Type: application/json",
         "-d", payload,
         f"{BASE}/databases/{DB}/collections/lessons/documents"],
        capture_output=True, text=True
    )
    resp = json.loads(r.stdout) if r.stdout else {}
    if resp.get("code") == 409:
        # Update instead
        update_payload = json.dumps({"data": data, "permissions": ["read(\"any\")"]})
        r2 = subprocess.run(
            ["curl", "-s", "-X", "PATCH",
             "-H", f"X-Appwrite-Project: {PROJECT}",
             "-H", f"X-Appwrite-Key: {API_KEY}",
             "-H", "Content-Type: application/json",
             "-d", update_payload,
             f"{BASE}/databases/{DB}/collections/lessons/documents/{doc_id}"],
            capture_output=True, text=True
        )
        print(f"  UPDATED {doc_id}")
    elif resp.get("$id"):
        print(f"  CREATED {doc_id}")
    else:
        print(f"  ERROR {doc_id}: {r.stdout[:200]}")

lessons = [
    {
        "id": "lesson_greet_0",
        "data": {
            "categoryId": GREETINGS_CAT,
            "titleLatin": "Basic Greetings",
            "titleOlChiki": "ᱡᱚᱦᱟᱨ",
            "level": "beginner",
            "order": 0,
            "estimatedMinutes": 5,
            "isActive": True,
            "blocks": json.dumps([
                {"type": "text", "textOlChiki": "ᱡᱚᱦᱟᱨ", "textLatin": "Johar – Hello / Greetings (formal)"},
                {"type": "text", "textOlChiki": "ᱡᱚᱦᱟᱨ ᱢᱮ", "textLatin": "Johar me – Hello to you"},
                {"type": "text", "textOlChiki": "ᱟᱹᱰᱤ ᱡᱚᱦᱟᱨ", "textLatin": "Aadi Johar – Good morning"},
                {"type": "text", "textOlChiki": "ᱥᱮᱛᱟᱜ ᱡᱚᱦᱟᱨ", "textLatin": "Setag Johar – Good evening"},
                {"type": "text", "textOlChiki": "ᱵᱟᱝ ᱡᱚᱦᱟᱨ", "textLatin": "Bang Johar – Good night"},
            ])
        }
    },
    {
        "id": "lesson_greet_1",
        "data": {
            "categoryId": GREETINGS_CAT,
            "titleLatin": "Meeting People",
            "titleOlChiki": "ᱦᱚᱲ ᱥᱟᱶᱛᱟ",
            "level": "beginner",
            "order": 1,
            "estimatedMinutes": 5,
            "isActive": True,
            "blocks": json.dumps([
                {"type": "text", "textOlChiki": "ᱟᱢ ᱧᱩᱛᱩᱢ ᱪᱮᱫ?", "textLatin": "Am nyutum ched? – What is your name?"},
                {"type": "text", "textOlChiki": "ᱤᱧ ᱧᱩᱛᱩᱢ ... ᱠᱟᱱᱟ", "textLatin": "Iny nyutum ... kana – My name is ..."},
                {"type": "text", "textOlChiki": "ᱟᱢ ᱚᱠᱟ ᱨᱮᱱ?", "textLatin": "Am oka ren? – Where are you from?"},
                {"type": "text", "textOlChiki": "ᱤᱧ ... ᱨᱮᱱ", "textLatin": "Iny ... ren – I am from ..."},
                {"type": "text", "textOlChiki": "ᱟᱢ ᱥᱟᱶᱛᱟ ᱛᱟᱦᱮᱸ ᱠᱟᱱᱟ ᱵᱟᱝ ᱞᱟᱜᱟᱛᱤᱡᱚᱜ", "textLatin": "Nice to meet you!"},
            ])
        }
    },
    {
        "id": "lesson_greet_2",
        "data": {
            "categoryId": GREETINGS_CAT,
            "titleLatin": "Polite Phrases",
            "titleOlChiki": "ᱢᱟᱨᱟᱝ ᱠᱟᱛᱷᱟ",
            "level": "beginner",
            "order": 2,
            "estimatedMinutes": 5,
            "isActive": True,
            "blocks": json.dumps([
                {"type": "text", "textOlChiki": "ᱥᱟᱨᱦᱟᱣ", "textLatin": "Sarhaw – Thank you"},
                {"type": "text", "textOlChiki": "ᱢᱟᱹᱧ ᱜᱚᱡ", "textLatin": "Maany goj – Excuse me / Sorry"},
                {"type": "text", "textOlChiki": "ᱦᱮᱸ", "textLatin": "Hen – Yes"},
                {"type": "text", "textOlChiki": "ᱵᱟᱝ", "textLatin": "Bang – No"},
                {"type": "text", "textOlChiki": "ᱫᱟᱭᱟ ᱠᱟᱛᱮ", "textLatin": "Daya kate – Please"},
                {"type": "text", "textOlChiki": "ᱟᱹᱰᱤ ᱞᱮᱠᱟ", "textLatin": "Aadi leka – Very good / Well done"},
            ])
        }
    },
    {
        "id": "lesson_greet_3",
        "data": {
            "categoryId": GREETINGS_CAT,
            "titleLatin": "Farewells",
            "titleOlChiki": "ᱟᱹᱞᱟᱹ ᱠᱟᱛᱷᱟ",
            "level": "beginner",
            "order": 3,
            "estimatedMinutes": 5,
            "isActive": True,
            "blocks": json.dumps([
                {"type": "text", "textOlChiki": "ᱟᱹᱞᱟᱹ", "textLatin": "Aalaa – Goodbye"},
                {"type": "text", "textOlChiki": "ᱛᱟᱦᱮᱸᱱ ᱡᱚᱦᱟᱨ", "textLatin": "Tahen Johar – See you later"},
                {"type": "text", "textOlChiki": "ᱥᱮᱨᱢᱟ ᱡᱚᱠᱷᱮᱡ", "textLatin": "Serma jokhej – Take care"},
                {"type": "text", "textOlChiki": "ᱢᱟᱹᱧ ᱥᱮᱱ ᱟ", "textLatin": "Maany sen a – I'm leaving now"},
                {"type": "text", "textOlChiki": "ᱫᱩᱞᱟᱹᱲ ᱡᱚᱦᱟᱨ", "textLatin": "Dulaar Johar – Goodbye with love"},
            ])
        }
    },
]

print(f"Seeding {len(lessons)} greeting lessons into {GREETINGS_CAT}...\n")
for lesson in lessons:
    create_or_update(lesson["id"], lesson["data"])

print("\nDone!")
