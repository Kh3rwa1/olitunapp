#!/bin/bash
# Seed Ol Chiki curriculum via the live API
# Run: bash scripts/seed_via_api.sh

API="https://olitun.in/admin-panel/api/v1"
CT="Content-Type: application/json"

echo "=========================================="
echo "🌟 Olitun Ol Chiki Curriculum Seeder"
echo "=========================================="

# Helper function
post() {
  local endpoint=$1
  local data=$2
  local result=$(curl -s -X POST "$API/$endpoint" -H "$CT" -d "$data")
  echo "$result"
}

put() {
  local endpoint=$1
  local data=$2
  local result=$(curl -s -X PUT "$API/$endpoint" -H "$CT" -d "$data")
  echo "$result"
}

# ============================================================
# 1. UPDATE CATEGORIES (they already exist, so use PUT)
# ============================================================
echo ""
echo "📂 Updating categories..."

put "categories.php" '{"id":"cat_alphabet","titleOlChiki":"ᱚᱞ ᱪᱤᱠᱤ ᱟᱠᱷᱟ","titleLatin":"Alphabet","iconName":"alphabet","gradientPreset":"skyBlue","order":0,"isActive":true,"totalLessons":30,"description":"Learn the 30 letters of Ol Chiki script."}'
put "categories.php" '{"id":"cat_numbers","titleOlChiki":"ᱮᱞᱠᱷᱟ ᱠᱚ","titleLatin":"Numbers","iconName":"numbers","gradientPreset":"peach","order":1,"isActive":true,"totalLessons":10,"description":"Master counting from 0 to 9 and beyond."}'
put "categories.php" '{"id":"cat_words","titleOlChiki":"ᱨᱚᱲ ᱠᱚ","titleLatin":"Common Words","iconName":"words","gradientPreset":"mint","order":2,"isActive":true,"totalLessons":50,"description":"Expand your vocabulary with common Santali words."}'
put "categories.php" '{"id":"cat_sentences","titleOlChiki":"ᱣᱟᱠᱭ ᱠᱚ","titleLatin":"Phrases","iconName":"stories","gradientPreset":"sunset","order":3,"isActive":true,"totalLessons":20,"description":"Learn useful phrases for daily conversation."}'

echo ""
echo "✅ Categories updated!"

# ============================================================
# 2. DELETE OLD LETTERS, then POST ALL 30
# ============================================================
echo ""
echo "📝 Clearing old letters..."
curl -s -X DELETE "$API/letters.php?id=l_a" > /dev/null
curl -s -X DELETE "$API/letters.php?id=l_aa" > /dev/null
curl -s -X DELETE "$API/letters.php?id=l_i" > /dev/null

echo "📝 Seeding 30 letters..."

# Row 1: ᱚ ᱛ ᱜ ᱝ ᱞ
post "letters.php" '{"id":"l_la","charOlChiki":"ᱚ","transliterationLatin":"La (a)","order":0,"isActive":true,"exampleWord":"ᱚᱞ (Ol - Write)"}'
post "letters.php" '{"id":"l_at","charOlChiki":"ᱛ","transliterationLatin":"At (t)","order":1,"isActive":true,"exampleWord":"ᱛᱟᱹᱠᱟᱹ (Taka - Money)"}'
post "letters.php" '{"id":"l_ag","charOlChiki":"ᱜ","transliterationLatin":"Ag (g)","order":2,"isActive":true,"exampleWord":"ᱜᱟᱞᱚᱡ (Galoj - Story)"}'
post "letters.php" '{"id":"l_ang","charOlChiki":"ᱝ","transliterationLatin":"Ang (ng)","order":3,"isActive":true,"exampleWord":"ᱟᱝ (Ang - Body)"}'
post "letters.php" '{"id":"l_al","charOlChiki":"ᱞ","transliterationLatin":"Al (l)","order":4,"isActive":true,"exampleWord":"ᱞᱟᱫᱩ (Ladu - Sweet)"}'

# Row 2: ᱟ ᱠ ᱡ ᱢ ᱣ
post "letters.php" '{"id":"l_laa","charOlChiki":"ᱟ","transliterationLatin":"Laa (aa)","order":5,"isActive":true,"exampleWord":"ᱟᱹᱜᱩ (Agu - Fire)"}'
post "letters.php" '{"id":"l_ak","charOlChiki":"ᱠ","transliterationLatin":"Ak (k)","order":6,"isActive":true,"exampleWord":"ᱠᱟᱛᱷᱟ (Katha - Word)"}'
post "letters.php" '{"id":"l_aj","charOlChiki":"ᱡ","transliterationLatin":"Aj (j)","order":7,"isActive":true,"exampleWord":"ᱡᱟᱱ (Jan - People)"}'
post "letters.php" '{"id":"l_am","charOlChiki":"ᱢ","transliterationLatin":"Am (m)","order":8,"isActive":true,"exampleWord":"ᱢᱟᱸ (Maa - Mother)"}'
post "letters.php" '{"id":"l_aw","charOlChiki":"ᱣ","transliterationLatin":"Aw (w)","order":9,"isActive":true,"exampleWord":"ᱣᱟᱦᱟᱸ (Waha - See)"}'

# Row 3: ᱤ ᱥ ᱦ ᱧ ᱨ
post "letters.php" '{"id":"l_li","charOlChiki":"ᱤ","transliterationLatin":"Li (i)","order":10,"isActive":true,"exampleWord":"ᱤᱨᱟᱹ (Ira - Sun)"}'
post "letters.php" '{"id":"l_is","charOlChiki":"ᱥ","transliterationLatin":"Is (s)","order":11,"isActive":true,"exampleWord":"ᱥᱟᱱᱟᱢ (Sanam - All)"}'
post "letters.php" '{"id":"l_ih","charOlChiki":"ᱦ","transliterationLatin":"Ih (h)","order":12,"isActive":true,"exampleWord":"ᱦᱟᱹᱠᱩ (Haku - Fish)"}'
post "letters.php" '{"id":"l_iny","charOlChiki":"ᱧ","transliterationLatin":"Iny (ny)","order":13,"isActive":true,"exampleWord":"ᱧᱩᱛᱩᱢ (Nyutum - Health)"}'
post "letters.php" '{"id":"l_ir","charOlChiki":"ᱨ","transliterationLatin":"Ir (r)","order":14,"isActive":true,"exampleWord":"ᱨᱟᱥᱤ (Rasi - Rope)"}'

# Row 4: ᱩ ᱪ ᱫ ᱬ ᱭ
post "letters.php" '{"id":"l_lu","charOlChiki":"ᱩ","transliterationLatin":"Lu (u)","order":15,"isActive":true,"exampleWord":"ᱩᱞ (Ul - Mango)"}'
post "letters.php" '{"id":"l_uc","charOlChiki":"ᱪ","transliterationLatin":"Uc (c)","order":16,"isActive":true,"exampleWord":"ᱪᱟ (Ca - Tea)"}'
post "letters.php" '{"id":"l_ud","charOlChiki":"ᱫ","transliterationLatin":"Ud (d)","order":17,"isActive":true,"exampleWord":"ᱫᱟᱠ (Dak - Water)"}'
post "letters.php" '{"id":"l_unn","charOlChiki":"ᱬ","transliterationLatin":"Unn (nn)","order":18,"isActive":true,"exampleWord":"ᱵᱟᱬ (Ban - Sound)"}'
post "letters.php" '{"id":"l_uy","charOlChiki":"ᱭ","transliterationLatin":"Uy (y)","order":19,"isActive":true,"exampleWord":"ᱭᱟᱠ (Yak - Liver)"}'

# Row 5: ᱮ ᱯ ᱰ ᱱ ᱲ
post "letters.php" '{"id":"l_le","charOlChiki":"ᱮ","transliterationLatin":"Le (e)","order":20,"isActive":true,"exampleWord":"ᱮᱢ (Em - Then)"}'
post "letters.php" '{"id":"l_ep","charOlChiki":"ᱯ","transliterationLatin":"Ep (p)","order":21,"isActive":true,"exampleWord":"ᱯᱟᱲᱟᱣ (Paraw - Lesson)"}'
post "letters.php" '{"id":"l_edd","charOlChiki":"ᱰ","transliterationLatin":"Edd (dd)","order":22,"isActive":true,"exampleWord":"ᱰᱟᱦᱟᱨ (Dahar - Road)"}'
post "letters.php" '{"id":"l_en","charOlChiki":"ᱱ","transliterationLatin":"En (n)","order":23,"isActive":true,"exampleWord":"ᱱᱟᱶᱟ (Nawa - New)"}'
post "letters.php" '{"id":"l_err","charOlChiki":"ᱲ","transliterationLatin":"Err (rr)","order":24,"isActive":true,"exampleWord":"ᱚᱲᱟᱜ (Orag - House)"}'

# Row 6: ᱳ ᱴ ᱵ ᱶ ᱷ
post "letters.php" '{"id":"l_lo","charOlChiki":"ᱳ","transliterationLatin":"Lo (o)","order":25,"isActive":true,"exampleWord":"ᱳᱞ (Ol - Write)"}'
post "letters.php" '{"id":"l_ott","charOlChiki":"ᱴ","transliterationLatin":"Ott (tt)","order":26,"isActive":true,"exampleWord":"ᱴᱟᱠᱟ (Taka - Coin)"}'
post "letters.php" '{"id":"l_obb","charOlChiki":"ᱵ","transliterationLatin":"Obb (b)","order":27,"isActive":true,"exampleWord":"ᱵᱟᱦᱟ (Baha - Flower)"}'
post "letters.php" '{"id":"l_ov","charOlChiki":"ᱶ","transliterationLatin":"Ov (v)","order":28,"isActive":true,"exampleWord":"ᱶᱟᱹᱠ (Vak - Sound)"}'
post "letters.php" '{"id":"l_oh","charOlChiki":"ᱷ","transliterationLatin":"Oh (h)","order":29,"isActive":true,"exampleWord":"ᱷᱚ (Ho - Yes)"}'

echo ""
echo "✅ 30 letters seeded!"

# ============================================================
# 3. SEED ALL 10 DIGITS
# ============================================================
echo ""
echo "🔢 Seeding 10 digits..."

post "numbers.php" '{"id":"n_0","numeral":"᱐","value":0,"nameOlChiki":"ᱥᱩᱱ","nameLatin":"Sun (Zero)","order":0}'
post "numbers.php" '{"id":"n_1","numeral":"᱑","value":1,"nameOlChiki":"ᱢᱤᱛ","nameLatin":"Mit (One)","order":1}'
post "numbers.php" '{"id":"n_2","numeral":"᱒","value":2,"nameOlChiki":"ᱵᱟᱨ","nameLatin":"Bar (Two)","order":2}'
post "numbers.php" '{"id":"n_3","numeral":"᱓","value":3,"nameOlChiki":"ᱯᱮ","nameLatin":"Pe (Three)","order":3}'
post "numbers.php" '{"id":"n_4","numeral":"᱔","value":4,"nameOlChiki":"ᱯᱚᱱ","nameLatin":"Pon (Four)","order":4}'
post "numbers.php" '{"id":"n_5","numeral":"᱕","value":5,"nameOlChiki":"ᱢᱚᱬᱮ","nameLatin":"Mone (Five)","order":5}'
post "numbers.php" '{"id":"n_6","numeral":"᱖","value":6,"nameOlChiki":"ᱛᱩᱨᱩᱭ","nameLatin":"Turui (Six)","order":6}'
post "numbers.php" '{"id":"n_7","numeral":"᱗","value":7,"nameOlChiki":"ᱮᱭᱟᱭ","nameLatin":"Eae (Seven)","order":7}'
post "numbers.php" '{"id":"n_8","numeral":"᱘","value":8,"nameOlChiki":"ᱤᱨᱟᱹᱞ","nameLatin":"Irel (Eight)","order":8}'
post "numbers.php" '{"id":"n_9","numeral":"᱙","value":9,"nameOlChiki":"ᱟᱨᱮ","nameLatin":"Are (Nine)","order":9}'

echo ""
echo "✅ 10 digits seeded!"

# ============================================================
# 4. SEED ADDITIONAL LESSONS
# ============================================================
echo ""
echo "📚 Seeding lessons..."

post "lessons.php" '{"id":"less_intro","categoryId":"cat_alphabet","titleOlChiki":"ᱚᱞ ᱪᱤᱠᱤ ᱢᱮᱱᱟᱜ","titleLatin":"Introduction to Ol Chiki","level":"beginner","order":0,"isActive":true,"estimatedMinutes":5,"description":"Learn about the history and basics of Ol Chiki script.","blocks":[{"type":"text","contentJson":{"textOlChiki":"ᱚᱞ ᱪᱤᱠᱤ ᱫᱚ ᱯᱚᱸᱰᱮᱛ ᱨᱟᱜᱷᱩᱱᱟᱛᱷ ᱢᱩᱨᱢᱩ ᱑᱙᱒᱕ ᱨᱮ ᱛᱮᱭᱟᱨ ᱟᱠᱟᱫ-ᱟ᱾","textLatin":"Ol Chiki was created by Pandit Raghunath Murmu in 1925 for the Santali language."}},{"type":"text","contentJson":{"textOlChiki":"ᱱᱚᱶᱟ ᱠᱷᱚᱱ ᱨᱮ ᱑᱐ ᱜᱚᱴᱟᱝ ᱚᱠᱷᱚᱨ ᱢᱮᱱᱟᱜ-ᱟ: ᱖ ᱨᱟᱦᱟ ᱟᱲᱟᱝ ᱟᱨ ᱒᱔ ᱠᱮᱪᱮᱫ ᱟᱲᱟᱝ᱾","textLatin":"The script has 30 letters: 6 vowels and 24 consonants."}}]}'

post "lessons.php" '{"id":"less_vowels","categoryId":"cat_alphabet","titleOlChiki":"ᱨᱟᱦᱟ ᱟᱲᱟᱝ ᱠᱚ","titleLatin":"The Vowels","level":"beginner","order":1,"isActive":true,"estimatedMinutes":10,"description":"Master the 6 basic vowels of Ol Chiki.","blocks":[{"type":"text","contentJson":{"textOlChiki":"ᱚᱞ ᱪᱤᱠᱤ ᱨᱮ ᱖ ᱜᱚᱴᱟᱝ ᱨᱟᱦᱟ ᱟᱲᱟᱝ ᱢᱮᱱᱟᱜ-ᱟ:","textLatin":"There are 6 vowels in Ol Chiki:"}},{"type":"text","contentJson":{"textOlChiki":"ᱚ (a) • ᱟ (aa) • ᱤ (i) • ᱩ (u) • ᱮ (e) • ᱳ (o)","textLatin":"ᱚ (a) • ᱟ (aa) • ᱤ (i) • ᱩ (u) • ᱮ (e) • ᱳ (o)"}},{"type":"text","contentJson":{"textOlChiki":"ᱱᱚᱶᱟ ᱖ ᱨᱟᱦᱟ ᱟᱲᱟᱝ ᱫᱚ ᱥᱟᱱᱟᱢ ᱨᱚᱲ ᱨᱮ ᱞᱟᱹᱠᱛᱤ ᱠᱟᱱᱟ᱾","textLatin":"These 6 vowels are used in all words."}}]}'

post "lessons.php" '{"id":"less_consonants_1","categoryId":"cat_alphabet","titleOlChiki":"ᱠᱮᱪᱮᱫ ᱟᱲᱟᱝ ᱠᱚ ᱑","titleLatin":"Consonants (Part 1)","level":"beginner","order":2,"isActive":true,"estimatedMinutes":15,"description":"Learn the first group of consonants.","blocks":[{"type":"text","contentJson":{"textOlChiki":"ᱯᱟᱹᱦᱤᱞ ᱖ ᱠᱮᱪᱮᱫ ᱟᱲᱟᱝ: ᱛ ᱜ ᱝ ᱞ ᱠ ᱡ","textLatin":"First 6 consonants: At, Ag, Ang, Al, Ak, Aj"}},{"type":"text","contentJson":{"textOlChiki":"ᱛ (At) - ᱛᱟᱹᱠᱟᱹ (Money)\nᱜ (Ag) - ᱜᱟᱞᱚᱡ (Story)\nᱝ (Ang) - ᱟᱝ (Body)\nᱞ (Al) - ᱞᱟᱫᱩ (Sweet)\nᱠ (Ak) - ᱠᱟᱛᱷᱟ (Word)\nᱡ (Aj) - ᱡᱟᱱ (People)","textLatin":"At - Taka (Money)\nAg - Galoj (Story)\nAng - Ang (Body)\nAl - Ladu (Sweet)\nAk - Katha (Word)\nAj - Jan (People)"}}]}'

post "lessons.php" '{"id":"less_counting_basic","categoryId":"cat_numbers","titleOlChiki":"ᱞᱮᱠᱷᱟ ᱑-᱑᱐","titleLatin":"Counting 1-10","level":"beginner","order":0,"isActive":true,"estimatedMinutes":5,"description":"Learn basic counting in Santali.","blocks":[{"type":"text","contentJson":{"textOlChiki":"᱑ ᱢᱤᱛ, ᱒ ᱵᱟᱨ, ᱓ ᱯᱮ, ᱔ ᱯᱚᱱ, ᱕ ᱢᱚᱬᱮ","textLatin":"1 Mit, 2 Bar, 3 Pe, 4 Pon, 5 Mone"}},{"type":"text","contentJson":{"textOlChiki":"᱖ ᱛᱩᱨᱩᱭ, ᱗ ᱮᱭᱟᱭ, ᱘ ᱤᱨᱟᱹᱞ, ᱙ ᱟᱨᱮ, ᱑᱐ ᱜᱮᱞ","textLatin":"6 Turui, 7 Eae, 8 Irel, 9 Are, 10 Gel"}}]}'

post "lessons.php" '{"id":"less_greetings","categoryId":"cat_sentences","titleOlChiki":"ᱡᱚᱦᱟᱨ ᱨᱚᱲ ᱠᱚ","titleLatin":"Greetings","level":"beginner","order":0,"isActive":true,"estimatedMinutes":8,"description":"Essential Santali greetings for daily life.","blocks":[{"type":"text","contentJson":{"textOlChiki":"ᱡᱚᱦᱟᱨ! = Hello!\nᱟᱢ ᱫᱚ ᱪᱮᱫ ᱧᱩᱛᱩᱢ ᱠᱟᱱᱟ? = How are you?\nᱤᱧ ᱫᱚ ᱵᱟᱝ ᱧᱩᱛᱩᱢ ᱠᱟᱱᱟ = I am fine\nᱥᱮᱨᱢᱟ ᱡᱚᱦᱟᱨ = Good morning","textLatin":"Johar! = Hello!\nAm do ced nyutum kana? = How are you?\nIng do bang nyutum kana = I am fine\nSerma Johar = Good morning"}}]}'

echo ""
echo "✅ Lessons seeded!"

echo ""
echo "=========================================="
echo "🎉 COMPLETE! All Ol Chiki data seeded!"
echo "=========================================="
echo "Open your app to see the changes."
