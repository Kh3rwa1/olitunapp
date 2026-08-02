import re
import os
import json

vocab_path = '/Users/dulorai/olitun/olitunapp/lib/shared/providers/seeders/vocab_seeder.dart'

with open(vocab_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Identify all Lesson IDs and their offsets
lesson_matches = list(re.finditer(r"'id':\s*'(lesson_(?:vocab|sentences)_\w+)'", content))
print("Found", len(lesson_matches), "lessons.")

# 2. Find all LessonBlockModel blocks
block_matches = list(re.finditer(r"LessonBlockModel\((.*?)\n\s*\),?", content, re.DOTALL))
print("Found", len(block_matches), "blocks.")

# Let's map blocks to their active lessons
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
        # Parse lesson details from the matching region
        # Find the titleLatin, titleOlChiki, level around the lesson match
        lesson_region = content[active_match.start():block.start()]
        title_latin_m = re.search(r"'titleLatin':\s*'(.*?)',", lesson_region)
        title_ol_m = re.search(r"'titleOlChiki':\s*'(.*?)',", lesson_region)
        level_m = re.search(r"'level':\s*'(.*?)',", lesson_region)
        
        lessons_data[active_id] = {
            'id': active_id,
            'titleLatin': title_latin_m.group(1) if title_latin_m else '',
            'titleOlChiki': title_ol_m.group(1) if title_ol_m else '',
            'level': level_m.group(1) if level_m else 'beginner',
            'blocks': []
        }
        block_index = 0
        
    block_content = block.group(1)
    
    # Parse fields
    type_match = re.search(r"type:\s*['\"](.*?)['\"],", block_content, re.DOTALL)
    b_type = type_match.group(1) if type_match else 'text'
    
    ol_match = re.search(r"textOlChiki:\s*['\"](.*?)['\"],", block_content, re.DOTALL)
    b_ol = ol_match.group(1) if ol_match else ''
    
    latin_match = re.search(r"textLatin:\s*['\"](.*?)['\"],", block_content, re.DOTALL)
    b_latin = latin_match.group(1) if latin_match else ''
    
    # Parse data dictionary
    data_match = re.search(r"data:\s*const\s*\{(.*?)\},", block_content, re.DOTALL)
    b_data = {}
    if data_match:
        # Extract fields from the dictionary string using regex
        dict_content = data_match.group(1)
        for field in ['emotion', 'storyArc', 'growthValue', 'characterGoal', 'imageDirection', 'bodyLanguage', 'learningMoment']:
            fm = re.search(fr"'{field}':\s*'(.*?)',", dict_content, re.DOTALL)
            if fm:
                # Unescape single quotes
                b_data[field] = fm.group(1).replace("\\'", "'")
                
    # Build the final block object (just like what is stored in Appwrite database)
    block_obj = {
        'id': '',
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

print("Parsed first lesson details:")
first_id = list(lessons_data.keys())[0]
print(json.dumps(lessons_data[first_id], indent=2, ensure_ascii=False))
