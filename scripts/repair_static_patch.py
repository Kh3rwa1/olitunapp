from pathlib import Path

path = Path(__file__).resolve().with_name('patch_static_codeql.py')
value = path.read_text(encoding='utf-8')
old = "`${JSON.stringify(rollback, null, 2)}\\n`"
new = "`${JSON.stringify(rollback, null, 2)}\\\\n`"
count = value.count(old)
if count != 2:
    raise RuntimeError(f'expected two rollback newline literals, found {count}')
path.write_text(value.replace(old, new), encoding='utf-8')
print('rollback newline anchors escaped for Python')
