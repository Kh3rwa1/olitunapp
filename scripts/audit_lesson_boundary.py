#!/usr/bin/env python3
"""Temporary exhaustive source audit for lesson and entitlement boundaries."""
from pathlib import Path

ROOTS = [Path('lib'), Path('functions'), Path('scripts')]
EXTRA_FILES = [Path('appwrite.json'), Path('appwrite.config.json')]
SUFFIXES = {'.dart', '.js', '.mjs', '.cjs', '.json', '.yaml', '.yml', '.ts'}
NEEDLES = (
    "'lessons'",
    '"lessons"',
    'course_purchases',
    'PAYMENT_COLLECTION_ID',
    'ContentKind.lesson',
)
SKIP_PARTS = {'node_modules', 'build', '.dart_tool', 'coverage'}

paths = []
for root in ROOTS:
    for path in root.rglob('*'):
        if path.is_file() and path.suffix in SUFFIXES and not (set(path.parts) & SKIP_PARTS):
            paths.append(path)
paths.extend(path for path in EXTRA_FILES if path.exists())

output = []
for path in sorted(set(paths)):
    try:
        lines = path.read_text(errors='replace').splitlines()
    except OSError:
        continue
    matches = [index for index, line in enumerate(lines) if any(needle in line for needle in NEEDLES)]
    if not matches:
        continue
    output.append(f'===== {path} =====')
    emitted = set()
    for match in matches:
        start = max(0, match - 3)
        end = min(len(lines), match + 4)
        if emitted and start <= max(emitted) + 1:
            start = max(emitted) + 1
        for index in range(start, end):
            if index in emitted:
                continue
            marker = '>' if index == match else ' '
            output.append(f'{marker}{index + 1:5}: {lines[index]}')
            emitted.add(index)
        output.append('')
    output.append('')

Path('.ci-lesson-boundary-audit.txt').write_text('\n'.join(output) + '\n')
print(f'Audited {len(paths)} source files; wrote {len(output)} report lines.')
