import re
import json

file_path = '/Users/dulorai/olitun/olitunapp/lib/shared/providers/sentences_provider.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Find _seedSentences list block
sentences_match = re.search(r'static final List<SentenceModel> _seedSentences = \[(.*?)\];', content, re.DOTALL)
if not sentences_match:
    print("Failed to find seed sentences.")
    exit(1)

sentences_content = sentences_match.group(1)

# Find each SentenceModel block
sentence_blocks = re.findall(r'SentenceModel\((.*?)\),', sentences_content, re.DOTALL)

csv_header = 'ID,Kind,Title,Title Ol Chiki,Ol Chiki,Subtitle,Category,Published,Premium,Order,Tags,Meaning Block,Usage Block,Audio Block URL,Audio Block Transcript,Blocks JSON,Updated At\n'

csv_rows = []

for block in sentence_blocks:
    fields = {}
    for line in block.split('\n'):
        line = line.strip()
        if not line:
            continue
        match = re.match(r'(\w+):\s*(.*?),?$', line)
        if match:
            k = match.group(1)
            v = match.group(2).strip()
            if (v.startswith("'") and v.endswith("'")) or (v.startswith('"') and v.endswith('"')):
                v = v[1:-1]
            fields[k] = v

    s_id = fields.get('id', '')
    sentenceOlChiki = fields.get('sentenceOlChiki', '')
    sentenceLatin = fields.get('sentenceLatin', '')
    meaning = fields.get('meaning', '')
    pronunciation = fields.get('pronunciation', '')
    category = fields.get('category', '')
    order = fields.get('order', '0')
    audioUrl = fields.get('audioUrl', '')
    usage = fields.get('usage', '')
    isActive = fields.get('isActive', 'true')
    isPremium = fields.get('isPremium', 'false')

    blocks = []
    meaning_block = meaning
    usage_block = usage
    audio_url_block = audioUrl
    audio_transcript_block = pronunciation if audioUrl else ''

    if meaning:
        blocks.append({
            'id': 'meaning',
            'order': 0,
            'type': 'text',
            'markdown': meaning
        })
    if usage:
        blocks.append({
            'id': 'usage',
            'order': len(blocks),
            'type': 'text',
            'markdown': usage
        })
    if audioUrl:
        blocks.append({
            'id': 'pronunciation_audio',
            'order': len(blocks),
            'type': 'audio',
            'media': {
                'url': audioUrl,
                'fileId': '',
                'kind': 'audio'
            },
            'transcript': pronunciation
        })

    blocks_json = json.dumps(blocks, ensure_ascii=False)

    row = [
        s_id,
        'sentence',
        sentenceLatin,
        sentenceOlChiki,
        sentenceOlChiki,
        meaning,
        category,
        isActive,
        isPremium,
        order,
        '', # tags
        meaning_block,
        usage_block,
        audio_url_block,
        audio_transcript_block,
        blocks_json,
        '2026-06-05T12:00:00Z' # Updated At
    ]

    escaped_row = []
    for val in row:
        escaped = val.replace('"', '""')
        escaped_row.append(f'"{escaped}"')
    csv_rows.append(','.join(escaped_row))

csv_content = csv_header + '\n'.join(csv_rows)

output_path = '/Users/dulorai/olitun/olitunapp/Olitun_sentence_Export.csv'
with open(output_path, 'w', encoding='utf-8') as f:
    f.write(csv_content)

print(f"Successfully generated CSV with {len(csv_rows)} rows.")
