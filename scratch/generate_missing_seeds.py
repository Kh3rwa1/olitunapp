import os
import re

def extract_field(m, field):
    # Match single-quoted string with potential escaped characters
    match = re.search(rf"{field}:\s*'((?:\\'|[^'])*)'", m)
    if match:
        return match.group(1).replace("\\'", "'").replace('\\"', '"')
    # Match double-quoted string with potential escaped characters
    match = re.search(rf'{field}:\s*"((?:\\"|[^"])*)"', m)
    if match:
        return match.group(1).replace('\\"', '"').replace("\\'", "'")
    return None

def extract_seed_words(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    list_match = re.search(r'List<WordModel>\s+_seedWords\s*=\s*\[(.*?)\];', content, re.DOTALL)
    if not list_match:
        print("Could not find _seedWords list")
        return []
    
    list_content = list_match.group(1)
    instances = re.findall(r'WordModel\((.*?)\)', list_content, re.DOTALL)
    
    seeds = []
    for inst in instances:
        seed_data = {}
        for field in ["wordOlChiki", "wordLatin", "meaning", "id", "category"]:
            val = extract_field(inst, field)
            if val is not None:
                seed_data[field] = val
        if seed_data:
            seeds.append(seed_data)
    return seeds

def extract_vocab_blocks(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    blocks = []
    # Split by LessonBlockModel( and skip the first part (preamble)
    parts = content.split('LessonBlockModel(')[1:]
    for part in parts:
        type_val = extract_field(part, 'type')
        if type_val == 'text':
            text_ol = extract_field(part, 'textOlChiki')
            text_lat = extract_field(part, 'textLatin')
            if text_ol:
                blocks.append({
                    'textOlChiki': text_ol.strip(),
                    'textLatin': text_lat.strip() if text_lat else ''
                })
    return blocks

def main():
    workspace = "/Users/dulorai/olitun/olitunapp"
    words_file = os.path.join(workspace, "lib/shared/providers/words_provider.dart")
    vocab_file = os.path.join(workspace, "lib/shared/providers/seeders/vocab_seeder.dart")
    greeting_file = os.path.join(workspace, "lib/shared/providers/seeders/greeting_seeder.dart")
    
    seeds = extract_seed_words(words_file)
    vocab_blocks = extract_vocab_blocks(vocab_file)
    greeting_blocks = extract_vocab_blocks(greeting_file)
    
    all_blocks = vocab_blocks + greeting_blocks
    
    seed_ols = {s['wordOlChiki'] for s in seeds}
    
    print(f"Loaded {len(seeds)} seed words.")
    print(f"Loaded {len(all_blocks)} text blocks from vocab & greeting seeders.")
    
    missing = []
    seen = set()
    
    for b in all_blocks:
        ol = b['textOlChiki']
        lat = b['textLatin']
        
        # Skip special combine / punctuation blocks
        if len(ol) <= 1 or all(c in ' ᱾,.-?!:' for c in ol):
            continue
            
        if ol in seed_ols or ol in seen:
            continue
            
        # Parse transliteration and meaning
        # e.g., "Marang – Big / Great"
        translit = lat
        meaning = ""
        if '–' in lat:
            parts = lat.split('–')
            translit = parts[0].strip()
            meaning = parts[1].strip()
        elif '-' in lat:
            parts = lat.split('-')
            translit = parts[0].strip()
            meaning = parts[1].strip()
            
        seen.add(ol)
        missing.append({
            'wordOlChiki': ol,
            'wordLatin': translit,
            'meaning': meaning or translit,
        })
        
    print(f"Found {len(missing)} missing words.")
    
    # Let's generate the Dart code to append
    # We will use category 'extra' and starting ID w_extra_1
    start_id = 1
    dart_code = []
    for m in missing:
        # Check if the word is already one of the modified grandfather/grandmother (skip)
        if m['wordOlChiki'] in ['ᱜᱚᱲᱚᱢ ᱦᱟᱲᱟᱢ', 'ᱜᱚᱲᱚᱢ ᱵᱩᱰᱷᱤ']:
            continue
        id_str = f"w_extra_{start_id}"
        code = f"""    WordModel(
      id: '{id_str}',
      wordOlChiki: '{m['wordOlChiki']}',
      wordLatin: '{m['wordLatin']}',
      meaning: '{m['meaning'].replace("'", "\\'")}',
      category: 'extra',
      order: {200 + start_id},
    ),"""
        dart_code.append(code)
        start_id += 1
        
    output_path = os.path.join(workspace, "scratch/missing_seeds.dart")
    with open(output_path, "w", encoding="utf-8") as out:
        out.write("\n".join(dart_code))
    print(f"Generated {len(dart_code)} seeds and wrote them to {output_path}")

if __name__ == "__main__":
    main()
