#!/usr/bin/env python3
"""
Olitun Firebase Seed Data Script
================================
Run this script to populate your Firestore database with demo content.

Prerequisites:
1. Install firebase-admin: pip install firebase-admin==7.1.0
2. Download your Firebase Admin SDK key from Firebase Console
3. Place it at /opt/flutter/firebase-admin-sdk.json or update the path below

Usage:
  python3 seed_data.py
"""

import os
import sys

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except ImportError:
    print("❌ firebase-admin not installed!")
    print("Run: pip install firebase-admin==7.1.0")
    sys.exit(1)

# Configuration
ADMIN_SDK_PATH = "/opt/flutter/firebase-admin-sdk.json"

# Ol Chiki Alphabet Data
OL_CHIKI_LETTERS = [
    {"char": "ᱚ", "latin": "A", "pronunciation": "ah (as in father)", "example_ol": "ᱟᱹᱜᱩ", "example_latin": "fire"},
    {"char": "ᱛ", "latin": "AT", "pronunciation": "at", "example_ol": "ᱛᱟᱹᱠᱟᱹ", "example_latin": "money"},
    {"char": "ᱜ", "latin": "AG", "pronunciation": "ag", "example_ol": "ᱜᱟᱞᱚᱡ", "example_latin": "story"},
    {"char": "ᱝ", "latin": "ANG", "pronunciation": "ang", "example_ol": "ᱟᱝᱜᱩ", "example_latin": "finger"},
    {"char": "ᱞ", "latin": "AL", "pronunciation": "al", "example_ol": "ᱞᱟᱫᱩ", "example_latin": "ladu (sweet)"},
    {"char": "ᱟ", "latin": "LA", "pronunciation": "la", "example_ol": "ᱞᱟᱠᱷᱚ", "example_latin": "hundred"},
    {"char": "ᱠ", "latin": "K", "pronunciation": "ka", "example_ol": "ᱠᱟᱛᱷᱟ", "example_latin": "word"},
    {"char": "ᱡ", "latin": "J", "pronunciation": "ja", "example_ol": "ᱡᱟᱱ", "example_latin": "people"},
    {"char": "ᱢ", "latin": "M", "pronunciation": "ma", "example_ol": "ᱢᱟᱸ", "example_latin": "mother"},
    {"char": "ᱣ", "latin": "W", "pronunciation": "wa", "example_ol": "ᱣᱟᱦᱟᱸ", "example_latin": "see"},
    {"char": "ᱤ", "latin": "I", "pronunciation": "i (as in see)", "example_ol": "ᱤᱨᱟᱹ", "example_latin": "sun"},
    {"char": "ᱥ", "latin": "S", "pronunciation": "sa", "example_ol": "ᱥᱟᱱᱟᱢ", "example_latin": "all"},
]

# Categories Data
CATEGORIES = [
    {
        "titleOlChiki": "ᱚᱠᱷᱚᱨ",
        "titleLatin": "Alphabets",
        "iconName": "alphabet",
        "gradientPreset": "skyBlue",
        "order": 1,
        "totalLessons": 6,
        "description": "Learn the 30 letters of Ol Chiki script"
    },
    {
        "titleOlChiki": "ᱜᱚᱱᱚᱱ",
        "titleLatin": "Numbers",
        "iconName": "numbers",
        "gradientPreset": "peach",
        "order": 2,
        "totalLessons": 4,
        "description": "Master counting in Santali"
    },
    {
        "titleOlChiki": "ᱨᱚᱲ",
        "titleLatin": "Words",
        "iconName": "words",
        "gradientPreset": "mint",
        "order": 3,
        "totalLessons": 8,
        "description": "Build your vocabulary"
    },
    {
        "titleOlChiki": "ᱜᱟᱱᱤᱛ",
        "titleLatin": "Arithmetic",
        "iconName": "arithmetic",
        "gradientPreset": "sunset",
        "order": 4,
        "totalLessons": 5,
        "description": "Learn math in Ol Chiki"
    },
]

# Featured Banners
BANNERS = [
    {
        "title": "Continue Learning",
        "subtitle": "Pick up where you left off",
        "gradientPreset": "skyBlue",
        "targetRoute": "/lessons",
        "order": 1,
    },
    {
        "title": "Almost There!",
        "subtitle": "Complete your daily goal",
        "gradientPreset": "peach",
        "targetRoute": None,
        "order": 2,
    },
]

# Sample Lessons
LESSONS = [
    {
        "categoryId": "",  # Will be filled after categories are created
        "titleOlChiki": "ᱚᱠᱷᱚᱨ ᱠᱚ ᱵᱟᱲᱟᱭ",
        "titleLatin": "Meet the Letters",
        "level": "beginner",
        "order": 1,
        "estimatedMinutes": 5,
        "blocks": [
            {
                "type": "text",
                "textOlChiki": "ᱡᱚᱦᱟᱨ! ᱚᱞ ᱪᱤᱠᱤ ᱥᱤᱠᱷᱟᱹᱣ ᱨᱮ ᱟᱢᱮᱫ ᱥᱟᱫᱮᱨ!",
                "textLatin": "Hello! Welcome to learning Ol Chiki!"
            },
            {
                "type": "text",
                "textOlChiki": "ᱚᱞ ᱪᱤᱠᱤ ᱨᱮ ᱑᱐ ᱚᱠᱷᱚᱨ ᱢᱮᱱᱟᱜ-ᱟ",
                "textLatin": "Ol Chiki has 30 letters"
            },
        ],
    },
]

# Sample Quiz
QUIZZES = [
    {
        "categoryId": "",  # Will be filled after categories are created
        "title": "Alphabet Quiz 1",
        "level": "beginner",
        "order": 1,
        "passingScore": 70,
        "questions": [
            {
                "promptOlChiki": "ᱚ",
                "promptLatin": "What letter is this?",
                "optionsOlChiki": ["A", "B", "C", "D"],
                "optionsLatin": ["A", "B", "C", "D"],
                "correctIndex": 0,
                "explanation": "ᱚ is the first letter of Ol Chiki, pronounced 'A' as in 'father'"
            },
            {
                "promptOlChiki": "ᱠ",
                "promptLatin": "What letter is this?",
                "optionsOlChiki": ["M", "K", "J", "L"],
                "optionsLatin": ["M", "K", "J", "L"],
                "correctIndex": 1,
                "explanation": "ᱠ is pronounced 'K'"
            },
        ],
    },
]


def initialize_firebase():
    """Initialize Firebase Admin SDK"""
    if not os.path.exists(ADMIN_SDK_PATH):
        print(f"❌ Admin SDK key not found at: {ADMIN_SDK_PATH}")
        print("Please download it from Firebase Console and place it there.")
        sys.exit(1)
    
    cred = credentials.Certificate(ADMIN_SDK_PATH)
    firebase_admin.initialize_app(cred)
    return firestore.client()


def seed_letters(db):
    """Seed Ol Chiki letters"""
    print("\n📝 Seeding letters...")
    letters_ref = db.collection('letters')
    
    for i, letter in enumerate(OL_CHIKI_LETTERS):
        doc_ref = letters_ref.document()
        doc_ref.set({
            "charOlChiki": letter["char"],
            "transliterationLatin": letter["latin"],
            "pronunciation": letter["pronunciation"],
            "exampleWordOlChiki": letter["example_ol"],
            "exampleWordLatin": letter["example_latin"],
            "order": i + 1,
            "isActive": True,
        })
        print(f"  ✓ Added letter: {letter['char']} ({letter['latin']})")
    
    print(f"✅ Added {len(OL_CHIKI_LETTERS)} letters")


def seed_categories(db):
    """Seed categories and return their IDs"""
    print("\n📂 Seeding categories...")
    categories_ref = db.collection('categories')
    category_ids = []
    
    for cat in CATEGORIES:
        doc_ref = categories_ref.document()
        doc_ref.set({
            **cat,
            "isActive": True,
        })
        category_ids.append(doc_ref.id)
        print(f"  ✓ Added category: {cat['titleLatin']}")
    
    print(f"✅ Added {len(CATEGORIES)} categories")
    return category_ids


def seed_banners(db):
    """Seed featured banners"""
    print("\n🖼️ Seeding banners...")
    banners_ref = db.collection('featuredBanners')
    
    for banner in BANNERS:
        doc_ref = banners_ref.document()
        doc_ref.set({
            **banner,
            "isActive": True,
        })
        print(f"  ✓ Added banner: {banner['title']}")
    
    print(f"✅ Added {len(BANNERS)} banners")


def seed_lessons(db, category_ids):
    """Seed sample lessons"""
    print("\n📚 Seeding lessons...")
    lessons_ref = db.collection('lessons')
    
    for lesson in LESSONS:
        lesson_data = {**lesson}
        lesson_data["categoryId"] = category_ids[0]  # Assign to first category (Alphabets)
        
        doc_ref = lessons_ref.document()
        doc_ref.set({
            **lesson_data,
            "isActive": True,
        })
        print(f"  ✓ Added lesson: {lesson['titleLatin']}")
    
    print(f"✅ Added {len(LESSONS)} lessons")


def seed_quizzes(db, category_ids):
    """Seed sample quizzes"""
    print("\n❓ Seeding quizzes...")
    quizzes_ref = db.collection('quizzes')
    
    for quiz in QUIZZES:
        quiz_data = {**quiz}
        quiz_data["categoryId"] = category_ids[0]  # Assign to first category
        
        doc_ref = quizzes_ref.document()
        doc_ref.set({
            **quiz_data,
            "isActive": True,
        })
        print(f"  ✓ Added quiz: {quiz['title']}")
    
    print(f"✅ Added {len(QUIZZES)} quizzes")


def main():
    print("=" * 50)
    print("🌟 Olitun Firebase Seed Data")
    print("=" * 50)
    
    # Initialize Firebase
    db = initialize_firebase()
    print("✅ Firebase initialized")
    
    # Seed data
    seed_letters(db)
    category_ids = seed_categories(db)
    seed_banners(db)
    seed_lessons(db, category_ids)
    seed_quizzes(db, category_ids)
    
    print("\n" + "=" * 50)
    print("🎉 Seed data complete!")
    print("=" * 50)


if __name__ == "__main__":
    main()
