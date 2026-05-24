import os
import re

def extract_field(m, field):
    match = re.search(rf"{field}:\s*'((?:\\'|[^'])*)'", m)
    if match:
        return match.group(1).replace("\\'", "'").replace('\\"', '"')
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
    parts = list_content.split('WordModel(')[1:]
    
    seeds = []
    for part in parts:
        seed_data = {}
        for field in ["wordOlChiki", "wordLatin", "meaning", "id"]:
            val = extract_field(part, field)
            if val is not None:
                seed_data[field] = val
        if seed_data:
            # Enforce that every seed has at least the basic fields (id, wordOlChiki, wordLatin, meaning)
            # Default missing fields to empty strings to avoid KeyErrors
            for field in ["wordOlChiki", "wordLatin", "meaning", "id"]:
                if field not in seed_data:
                    seed_data[field] = ""
            seeds.append(seed_data)
    return seeds

def extract_vocab_blocks(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    blocks = []
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

def is_exact_match(text, word):
    t = text.strip()
    dash_regex = re.compile(r'\s*[\-–—−]\s*')
    parts = dash_regex.split(t) if dash_regex.search(t) else [t]
    
    for part in parts:
        p = part.lower()
        if (word['wordOlChiki'].lower() == p or 
            word['wordLatin'].lower() == p or 
            word['meaning'].lower() == p):
            return True
    return False

def resolve_word(text, words):
    # Try exact matches first
    for w in words:
        if is_exact_match(text, w):
            return w
            
    # Try fuzzy matches fallback (starts with or exact token)
    for w in words:
        t = text.strip().lower()
        e = w['wordOlChiki'].strip().lower()
        if t == e:
            return w
        separators = [' ', '-', '–', '—', '−', '.', '!', '?', ':', ';']
        for s in separators:
            if t.startswith(f"{e}{s}"):
                return w
        tokens = re.split(r'[\s\-\–\—\−\.\!\?\:\;]', t)
        if tokens and tokens[0] == e:
            return w
            
    return None

def main():
    workspace = "/Users/dulorai/olitun/olitunapp"
    words_file = os.path.join(workspace, "lib/shared/providers/words_provider.dart")
    vocab_file = os.path.join(workspace, "lib/shared/providers/seeders/vocab_seeder.dart")
    
    words = extract_seed_words(words_file)
    blocks = extract_vocab_blocks(vocab_file)
    
    print(f"Checking {len(blocks)} vocab blocks...")
    
    grandfather_resolved = None
    grandmother_resolved = None
    unresolved_count = 0
    hijacked_count = 0
    
    for b in blocks:
        text_ol = b['textOlChiki']
        text_lat = b['textLatin']
        
        # Skip special combine / punctuation blocks
        if len(text_ol) <= 1 or all(c in ' ᱾,.-?!:' for c in text_ol):
            continue
            
        # Try resolving via Ol Chiki text first
        resolved = resolve_word(text_ol, words)
        if not resolved and text_lat:
            resolved = resolve_word(text_lat, words)
            
        if text_ol == 'ᱜᱚᱲᱚᱢ ᱦᱟᱲᱟᱢ':
            grandfather_resolved = resolved
        elif text_ol == 'ᱜᱚᱲᱚᱢ ᱵᱩᱰᱷᱤ':
            grandmother_resolved = resolved
            
        if not resolved:
            unresolved_count += 1
            print(f"❌ Unresolved block: '{text_ol}' ({text_lat})")
        else:
            # Check if it was hijacked
            # If we teach "ᱜᱚᱲᱚᱢ ᱦᱟᱲᱟᱢ" (Grandfather), it should resolve to w_f10
            if text_ol == 'ᱜᱚᱲᱚᱢ ᱦᱟᱲᱟᱢ' and resolved['id'] != 'w_f10':
                print(f"🚨 HIJACKED Grandfather: resolved to {resolved['id']} ({resolved['meaning']}) instead of w_f10")
                hijacked_count += 1
            elif text_ol == 'ᱜᱚᱲᱚᱢ ᱵᱩᱰᱷᱤ' and resolved['id'] != 'w_f11':
                print(f"🚨 HIJACKED Grandmother: resolved to {resolved['id']} ({resolved['meaning']}) instead of w_f11")
                hijacked_count += 1
                
    print("\n--- Summary ---")
    print(f"Unresolved blocks: {unresolved_count}")
    print(f"Hijacked blocks: {hijacked_count}")
    if grandfather_resolved:
        print(f"Grandfather ('ᱜᱚᱲᱚᱢ ᱦᱟᱲᱟᱢ') resolved to: {grandfather_resolved['id']} ({grandfather_resolved['meaning']})")
    else:
        print("Grandfather unresolved!")
        
    if grandmother_resolved:
        print(f"Grandmother ('ᱜᱚᱲᱚᱢ ᱵᱩᱰᱷᱤ') resolved to: {grandmother_resolved['id']} ({grandmother_resolved['meaning']})")
    else:
        print("Grandmother unresolved!")
        
if __name__ == "__main__":
    main()
