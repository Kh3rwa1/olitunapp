import json
import subprocess

def get_all_lessons():
    all_docs = []
    offset = 0
    limit = 25
    while True:
        cmd = [
            'appwrite', '--json', 'databases', 'list-documents',
            '--database-id', 'olitun_db',
            '--collection-id', 'lessons',
            '--queries', f'limit({limit})', f'offset({offset})'
        ]
        res = subprocess.run(cmd, capture_output=True, text=True)
        if res.returncode != 0:
            print("Error listing documents:", res.stderr)
            break
        try:
            data = json.loads(res.stdout)
            docs = data.get('documents', [])
            if not docs:
                break
            all_docs.extend(docs)
            if len(docs) < limit:
                break
            offset += limit
        except Exception as e:
            print("JSON parse error:", e)
            break
    return all_docs

lessons = get_all_lessons()
print(f"Total lessons in DB: {len(lessons)}")
for i, l in enumerate(lessons):
    print(f"{i+1:2d}. ID: {l.get('$id'):<40} Title: {l.get('titleLatin')}")
