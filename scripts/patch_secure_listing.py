#!/usr/bin/env python3
"""Temporary focused fixer for secure lesson-list verification."""
from pathlib import Path

source_path = Path('lib/features/lessons/data/datasources/lesson_remote_datasource.dart')
source = source_path.read_text()
replacements = {
    "          if (categoryId != null) 'categoryId': categoryId,": "          'categoryId': ?categoryId,",
    "          if (cursor != null) 'cursor': cursor,": "          'cursor': ?cursor,",
}
for old, new in replacements.items():
    if source.count(old) != 1:
        raise SystemExit(f'Unexpected analyzer-fix anchor: {old}')
    source = source.replace(old, new, 1)
source_path.write_text(source)

test_path = Path('test/features/lessons/lesson_remote_datasource_list_authorized_test.dart')
test_source = test_path.read_text()
for old, new in {
    '      () => dataSource.getLessons(),': '      dataSource.getLessons,',
    '      () => unavailable.getLessons(),': '      unavailable.getLessons,',
}.items():
    if test_source.count(old) != 1:
        raise SystemExit(f'Unexpected test-lint anchor: {old}')
    test_source = test_source.replace(old, new, 1)
test_path.write_text(test_source)
