import json
import requests
import urllib.parse
import csv
import os

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

def get_all_documents(collection_id):
    docs = []
    offset = 0
    limit = 100
    while True:
        query1 = json.dumps({'method': 'limit', 'values': [limit]})
        query2 = json.dumps({'method': 'offset', 'values': [offset]})
        url = f"{endpoint}/databases/olitun_db/collections/{collection_id}/documents?queries[]={urllib.parse.quote(query1)}&queries[]={urllib.parse.quote(query2)}"
        res = requests.get(url, headers=headers)
        if res.status_code != 200:
            print(f"❌ Error fetching {collection_id}: {res.text}")
            break
        data = res.json()
        current_docs = data.get('documents', [])
        if not current_docs:
            break
        docs.extend(current_docs)
        if len(current_docs) < limit:
            break
        offset += limit
    return docs

print("📥 Fetching database collections...")
lessons = get_all_documents('lessons')
words = get_all_documents('words')
sentences = get_all_documents('sentences')

print(f"Fetched {len(lessons)} lessons, {len(words)} words, and {len(sentences)} sentences.")

# --- 1. Export Lessons ---
lesson_csv_path = '/Users/dulorai/olitun/olitunapp/Olitun_lesson_Export.csv'
print(f"✍️ Exporting lessons to {lesson_csv_path}...")
with open(lesson_csv_path, 'w', encoding='utf-8', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(['ID', 'Kind', 'Title', 'Title Ol Chiki', 'Ol Chiki', 'Subtitle', 'Category', 'Published', 'Premium', 'Order', 'Tags', 'Updated At'])
    for doc in lessons:
        writer.writerow([
            doc.get('$id', ''),
            'lesson',
            doc.get('titleLatin', ''),
            doc.get('titleOlChiki', ''),
            '', # Ol Chiki (empty for lesson container)
            '', # Subtitle (empty for lesson container)
            doc.get('categoryId', ''),
            str(doc.get('isActive', True)).lower(),
            str(doc.get('isPremium', False)).lower(),
            str(doc.get('orderIndex', 0)),
            '', # Tags
            doc.get('$updatedAt', '')
        ])

# --- 2. Export Unpacked Lesson Blocks (with emotional metadata) ---
blocks_csv_path = '/Users/dulorai/olitun/olitunapp/Olitun_lesson_blocks_Export.csv'
print(f"✍️ Exporting unpacked lesson blocks to {blocks_csv_path}...")
with open(blocks_csv_path, 'w', encoding='utf-8', newline='') as f:
    writer = csv.writer(f)
    writer.writerow([
        'Lesson ID', 'Lesson Title', 'Lesson Category', 'Block Order', 'Block Type', 
        'Ol Chiki', 'Latin', 'Audio URL', 'Image URL', 
        'Emotion', 'Story Arc', 'Growth Value', 'Character Goal', 
        'Image Direction', 'Body Language', 'Learning Moment'
    ])
    
    total_blocks = 0
    for doc in lessons:
        blocks_str = doc.get('blocks', '[]')
        if not blocks_str:
            continue
        try:
            blocks = json.loads(blocks_str)
            for block in blocks:
                meta = block.get('meta', {})
                # Get Latin text (can be in textLatin or markdown)
                latin_text = block.get('textLatin', block.get('markdown', ''))
                
                writer.writerow([
                    doc.get('$id', ''),
                    doc.get('titleLatin', ''),
                    doc.get('categoryId', ''),
                    block.get('order', 0),
                    block.get('type', 'text'),
                    block.get('textOlChiki', ''),
                    latin_text,
                    block.get('audioUrl', meta.get('audioUrl', '')),
                    block.get('imageUrl', meta.get('imageUrl', '')),
                    meta.get('emotion', ''),
                    meta.get('storyArc', ''),
                    meta.get('growthValue', ''),
                    meta.get('characterGoal', ''),
                    meta.get('imageDirection', ''),
                    meta.get('bodyLanguage', ''),
                    meta.get('learningMoment', '')
                ])
                total_blocks += 1
        except Exception as e:
            print(f"⚠️ Error parsing blocks for lesson {doc.get('$id')}: {e}")
            
print(f"Successfully exported {total_blocks} block items.")

# --- 3. Export Words ---
words_csv_path = '/Users/dulorai/olitun/olitunapp/Olitun_word_Export.csv'
print(f"✍️ Exporting words collection to {words_csv_path}...")
with open(words_csv_path, 'w', encoding='utf-8', newline='') as f:
    writer = csv.writer(f)
    writer.writerow([
        'ID', 'Word Ol Chiki', 'Word Latin', 'Meaning', 'Usage', 'Category', 
        'Audio URL', 'Image URL', 'Order Index', 'Pronunciation', 
        'Animation URL', 'Order', 'Is Active', 'Theme Color', 'Hero Media', 
        'Blocks', 'Tracing', 'Updated At'
    ])
    for doc in words:
        writer.writerow([
            doc.get('$id', ''),
            doc.get('wordOlChiki', ''),
            doc.get('wordLatin', ''),
            doc.get('meaning', ''),
            doc.get('usage', ''),
            doc.get('category', ''),
            doc.get('audioUrl', ''),
            doc.get('imageUrl', ''),
            str(doc.get('orderIndex', 0)),
            doc.get('pronunciation', ''),
            doc.get('animationUrl', ''),
            str(doc.get('order', 0)),
            str(doc.get('isActive', True)).lower(),
            doc.get('themeColor', ''),
            doc.get('hero_media', ''),
            doc.get('blocks', ''),
            doc.get('tracing', ''),
            doc.get('$updatedAt', '')
        ])

# --- 4. Export Sentences ---
sentences_csv_path = '/Users/dulorai/olitun/olitunapp/Olitun_sentence_Export.csv'
print(f"✍️ Exporting sentences collection to {sentences_csv_path}...")
with open(sentences_csv_path, 'w', encoding='utf-8', newline='') as f:
    writer = csv.writer(f)
    writer.writerow([
        'ID', 'Sentence Ol Chiki', 'Sentence Latin', 'Meaning', 'Usage', 'Category', 
        'Audio URL', 'Image URL', 'Pronunciation', 'Order Index', 
        'Animation URL', 'Order', 'Is Active', 'Theme Color', 'Hero Media', 
        'Blocks', 'Tracing', 'Updated At'
    ])
    for doc in sentences:
        writer.writerow([
            doc.get('$id', ''),
            doc.get('sentenceOlChiki', ''),
            doc.get('sentenceLatin', ''),
            doc.get('meaning', ''),
            doc.get('usage', ''),
            doc.get('category', ''),
            doc.get('audioUrl', ''),
            doc.get('imageUrl', ''),
            doc.get('pronunciation', ''),
            str(doc.get('orderIndex', 0)),
            doc.get('animationUrl', ''),
            str(doc.get('order', 0)),
            str(doc.get('isActive', True)).lower(),
            doc.get('themeColor', ''),
            doc.get('hero_media', ''),
            doc.get('blocks', ''),
            doc.get('tracing', ''),
            doc.get('$updatedAt', '')
        ])

print("\n🎉 All CSV files exported successfully!")
