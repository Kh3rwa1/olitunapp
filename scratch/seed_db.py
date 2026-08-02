import re
import json
import subprocess
import sys

vocab_path = '/Users/dulorai/olitun/olitunapp/lib/shared/providers/seeders/vocab_seeder.dart'
sentence_path = '/Users/dulorai/olitun/olitunapp/lib/shared/providers/seeders/sentence_seeder.dart'

def parse_seeder(file_path, default_category_id):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    lesson_matches = list(re.finditer(r"'id':\s*'(lesson_(?:vocab|sentences)_\w+)'", content))
    block_matches = list(re.finditer(r"LessonBlockModel\((.*?)\n\s*\),?", content, re.DOTALL))
    
    lessons_data = {}
    current_lesson_id = None
    block_index = 0

    for block in block_matches:
        block_offset = block.start()
        
        # Find active lesson match
        active_match = None
        for lm in lesson_matches:
            if lm.start() < block_offset:
                active_match = lm
            else:
                break
                
        if not active_match:
            continue
            
        active_id = active_match.group(1)
            
        if active_id != current_lesson_id:
            current_lesson_id = active_id
            lesson_region = content[active_match.start():block.start()]
            title_latin_m = re.search(r"'titleLatin':\s*'(.*?)',", lesson_region)
            title_ol_m = re.search(r"'titleOlChiki':\s*'(.*?)',", lesson_region)
            level_m = re.search(r"'level':\s*'(.*?)',", lesson_region)
            
            lessons_data[active_id] = {
                'id': active_id,
                'categoryId': default_category_id,
                'titleOlChiki': title_ol_m.group(1) if title_ol_m else '',
                'titleLatin': title_latin_m.group(1) if title_latin_m else '',
                'level': level_m.group(1) if level_m else 'beginner',
                'blocks': []
            }
            block_index = 0
            
        block_content = block.group(1)
        
        type_match = re.search(r"type:\s*['\"](.*?)['\"],", block_content, re.DOTALL)
        b_type = type_match.group(1) if type_match else 'text'
        
        ol_match = re.search(r"textOlChiki:\s*['\"](.*?)['\"],", block_content, re.DOTALL)
        b_ol = ol_match.group(1) if ol_match else ''
        
        latin_match = re.search(r"textLatin:\s*['\"](.*?)['\"],", block_content, re.DOTALL)
        b_latin = latin_match.group(1) if latin_match else ''
        
        data_match = re.search(r"data:\s*const\s*\{(.*?)\},", block_content, re.DOTALL)
        b_data = {}
        if data_match:
            dict_content = data_match.group(1)
            for field in ['emotion', 'storyArc', 'growthValue', 'characterGoal', 'imageDirection', 'bodyLanguage', 'learningMoment']:
                fm = re.search(fr"'{field}':\s*'(.*?)',", dict_content, re.DOTALL)
                if fm:
                    b_data[field] = fm.group(1).replace("\\'", "'")
                    
        block_obj = {
            'id': f"blk_text_{block_index}",
            'order': block_index,
            'type': b_type,
            'markdown': b_latin.replace("\\'", "'"),
            'textOlChiki': b_ol.replace("\\'", "'"),
            'textLatin': b_latin.replace("\\'", "'"),
        }
        if b_data:
            block_obj['meta'] = b_data
            
        lessons_data[active_id]['blocks'].append(block_obj)
        block_index += 1
        
    return lessons_data

print("Parsing seeders...")
vocab_lessons = parse_seeder(vocab_path, 'cat_vocab_1778594020532')
sentence_lessons = parse_seeder(sentence_path, 'cat_sentences_1778594024495')

all_lessons = {**vocab_lessons, **sentence_lessons}
print(f"Parsed {len(vocab_lessons)} vocab lessons and {len(sentence_lessons)} sentence lessons. Total: {len(all_lessons)}")

for lesson_id, lesson in all_lessons.items():
    print(f"\n--- Processing Lesson: {lesson_id} ({lesson['titleLatin']}) ---")
    
    # 1. Fetch existing document to merge custom fields (like audioUrl or existing meta)
    cmd_get = [
        'appwrite', '--json', 'databases', 'get-document',
        '--database-id', 'olitun_db',
        '--collection-id', 'lessons',
        '--document-id', lesson_id
    ]
    res_get = subprocess.run(cmd_get, capture_output=True, text=True)
    
    existing_doc = None
    if res_get.returncode == 0:
        try:
            existing_doc = json.loads(res_get.stdout)
        except Exception as e:
            print(f"⚠️ Error parsing JSON for {lesson_id}: {e}")
    
    # 2. Merge existing block properties (specifically meta audio/image links)
    merged_blocks = []
    if existing_doc and 'blocks' in existing_doc:
        try:
            existing_blocks = json.loads(existing_doc['blocks'])
            # Create a lookup mapping from existing blocks by their order or text
            existing_by_order = {b.get('order'): b for b in existing_blocks if 'order' in b}
            
            for new_b in lesson['blocks']:
                order = new_b['order']
                existing_b = existing_by_order.get(order)
                if existing_b:
                    # Preserve any audio/image URLs in the meta object
                    existing_meta = existing_b.get('meta', {})
                    if existing_meta:
                        new_meta = new_b.get('meta', {})
                        # Merge new_meta values on top of existing_meta, keeping audio/image values if new_meta doesn't have them
                        merged_meta = {**existing_meta, **new_meta}
                        # Make sure to keep any raw keys like 'audioUrl' or 'imageUrl' that might be in existing_meta
                        for k, v in existing_meta.items():
                            if k not in new_meta:
                                merged_meta[k] = v
                        new_b['meta'] = merged_meta
                        
                    # Also keep root fields from existing block if present
                    for k in ['audioUrl', 'imageUrl', 'id']:
                        if k in existing_b and existing_b[k]:
                            new_b[k] = existing_b[k]
                merged_blocks.append(new_b)
        except Exception as e:
            print(f"⚠️ Error merging blocks for {lesson_id}: {e}")
            merged_blocks = lesson['blocks']
    else:
        merged_blocks = lesson['blocks']
        
    # Build payload data object
    payload = {
        'categoryId': lesson['categoryId'],
        'titleOlChiki': lesson['titleOlChiki'],
        'titleLatin': lesson['titleLatin'],
        'level': lesson['level'],
        'blocks': json.dumps(merged_blocks, ensure_ascii=False),
        'isActive': True,
        'estimatedMinutes': 5
    }
    
    # Preserve other metadata fields from existing doc if it exists
    if existing_doc:
        for k in ['orderIndex', 'isPremium', 'description', 'thumbnailUrl', 'audioUrl', 'heroMediaUrl', 'heroMediaType', 'heroPosterUrl', 'hero_media', 'tracing', 'order']:
            if k in existing_doc and existing_doc[k] is not None:
                payload[k] = existing_doc[k]

    # 3. Update or create the document
    if existing_doc:
        print(f"🔄 Updating existing lesson document: {lesson_id}")
        cmd_update = [
            'appwrite', 'databases', 'update-document',
            '--database-id', 'olitun_db',
            '--collection-id', 'lessons',
            '--document-id', lesson_id,
            '--data', json.dumps(payload, ensure_ascii=False)
        ]
        res_update = subprocess.run(cmd_update, capture_output=True, text=True)
        if res_update.returncode == 0:
            print(f"✅ Successfully updated {lesson_id}")
        else:
            print(f"❌ Failed to update {lesson_id}: {res_update.stderr}")
    else:
        print(f"➕ Creating new lesson document: {lesson_id}")
        cmd_create = [
            'appwrite', 'databases', 'create-document',
            '--database-id', 'olitun_db',
            '--collection-id', 'lessons',
            '--document-id', lesson_id,
            '--data', json.dumps(payload, ensure_ascii=False),
            '--permissions', 'read("any")'
        ]
        res_create = subprocess.run(cmd_create, capture_output=True, text=True)
        if res_create.returncode == 0:
            print(f"✅ Successfully created {lesson_id}")
        else:
            print(f"❌ Failed to create {lesson_id}: {res_create.stderr}")

print("\n🎉 Seeding complete!")
