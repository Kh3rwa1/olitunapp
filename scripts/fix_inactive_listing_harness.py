from pathlib import Path

root = Path(__file__).resolve().parents[1]
path = root / 'functions/test/authorized_lesson_listing.test.js'
value = path.read_text(encoding='utf-8')
old = "    categoryId,\n    order,\n    titleLatin: `Lesson ${order}`,"
new = "    categoryId,\n    order,\n    isActive: true,\n    titleLatin: `Lesson ${order}`,"
if value.count(old) != 1:
    raise RuntimeError('authorized lesson listing helper anchor drift')
path.write_text(value.replace(old, new, 1), encoding='utf-8')
print('inactive listing test harness corrected')
