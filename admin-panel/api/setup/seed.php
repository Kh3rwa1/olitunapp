<?php
if (isset($_SERVER['HTTP_ORIGIN']) && preg_match('/^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/', $_SERVER['HTTP_ORIGIN'])) {
    header("Access-Control-Allow-Origin: " . $_SERVER['HTTP_ORIGIN']);
    header("Vary: Origin");
}
header("Content-Type: application/json; charset=UTF-8");

include_once '../core/db.php';

try {
    $database = new Database();
    $db = $database->getConnection();
    
    // Seed Categories
    $categories = [
        ['alphabets', 'ᱚᱞ ᱪᱤᱠᱤ', 'Ol Chiki Alphabet', 'alphabet', 'skyBlue', 0, 1, 30, 'Learn the Ol Chiki script basics.'],
        ['numbers', 'ᱮᱞᱠᱷᱟ', 'Numbers', 'numbers', 'peach', 1, 1, 10, 'Learn numbers 1-100.'],
        ['words', 'ᱯᱟᱹᱨᱥᱤ', 'Common Words', 'words', 'mint', 2, 1, 20, 'Everyday vocabulary.'],
        ['phrases', 'ᱛᱮᱞᱟ ᱯᱟᱹᱨᱥᱤ', 'Phrases', 'stories', 'sunset', 3, 1, 15, 'Useful phrases for conversation.']
    ];

    $stmt = $db->prepare("REPLACE INTO categories (id, title_ol_chiki, title_latin, icon_name, gradient_preset, `order`, is_active, total_lessons, description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
    foreach ($categories as $cat) {
        $stmt->execute($cat);
    }
    echo "Categories seeded.\n";

    // Seed Lessons
    $lessons = [
        ['alphabets_1', 'alphabets', 'ᱯᱟᱹᱦᱤᱞ ᱯᱟᱹᱴ', 'Introduction to Ol Chiki', 'beginner', 0, 1, 5, 'Learn about the Ol Chiki script, invented by Pandit Raghunath Murmu in 1925 for the Santali language.'],
        ['alphabets_2', 'alphabets', 'ᱚᱠᱤᱞ ᱠᱚ', 'Vowels (ᱚ-ᱩ)', 'beginner', 1, 1, 8, 'Master the six basic vowels of Ol Chiki: ᱚ (a), ᱟ (aa), ᱤ (i), ᱩ (u), ᱮ (e), and ᱳ (o).'],
        ['alphabets_3', 'alphabets', 'ᱚᱞ ᱠᱚ', 'Consonants Part 1', 'beginner', 2, 1, 10, 'Learn the first set of consonants: ᱠ (k), ᱜ (g), ᱝ (ng), ᱪ (c), ᱡ (j).'],
        ['numbers_1', 'numbers', 'ᱮᱞᱠᱷᱟ ᱑-᱕', 'Numbers 1-5', 'beginner', 0, 1, 5, 'Learn to count from 1 to 5: ᱑ (mit), ᱒ (bar), ᱓ (pe), ᱔ (pon), ᱕ (mone).'],
        ['numbers_2', 'numbers', 'ᱮᱞᱠᱷᱟ ᱖-᱑᱐', 'Numbers 6-10', 'beginner', 1, 1, 5, 'Continue counting from 6 to 10: ᱖ (turui), ᱗ (eae), ᱘ (irel), ᱙ (are), ᱑᱐ (gel).'],
        ['words_1', 'words', 'ᱱᱳᱣᱟ ᱯᱟᱹᱨᱥᱤ', 'Greetings', 'beginner', 0, 1, 7, 'Learn essential Santali greetings: ᱡᱚᱦᱟᱨ (Johar), ᱥᱮᱨᱢᱟ (Serma).']
    ];

    $stmt = $db->prepare("REPLACE INTO lessons (id, category_id, title_ol_chiki, title_latin, level, `order`, is_active, estimated_minutes, description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
    foreach ($lessons as $lesson) {
        $stmt->execute($lesson);
    }
    echo "Lessons seeded.\n";

    // Seed Letters (Sample)
    $letters = [
        ['l_a', 'alphabets', 'ᱚ', 'a', '', 0, 1, 'vowel', 'The sound "a" as in "about".', '', 'a.mp3'],
        ['l_t', 'alphabets', 'ᱛ', 'at/t', '', 1, 1, 'consonant', 'The sound "t" as in "top".', '', 't.mp3'],
        ['l_g', 'alphabets', 'ᱜ', 'ag/g', '', 2, 1, 'consonant', 'The sound "g" as in "go".', '', 'g.mp3'],
        ['l_l', 'alphabets', 'ᱞ', 'al/l', '', 3, 1, 'consonant', 'The sound "l" as in "low".', '', 'l.mp3'],
        ['l_aa', 'alphabets', 'ᱟ', 'aa', '', 4, 1, 'vowel', 'The sound "aa" as in "father".', '', 'aa.mp3']
    ];
    // Note: Schema has category_id in letters table? Check schema.
    // Schema says: letters (id, category_id, symbol_ol_chiki, symbol_latin, ...)
    // Wait, letters usually belong to alphabets category implicitly or explicitly? Schema has it as FK to categories?
    // Let's check schema.sql structure if possible. 
    // Assuming schema is: (id, category_id, symbol_ol_chiki, symbol_latin, image_url, `order`, is_active, type, description, pronunciation_guide, audio_url)
    
    $stmt = $db->prepare("REPLACE INTO letters (id, category_id, symbol_ol_chiki, symbol_latin, image_url, `order`, is_active, type, description, pronunciation_guide, audio_url) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
    foreach ($letters as $letter) {
        $stmt->execute($letter);
    }
    echo "Letters seeded.\n";

    // Seed Numbers (Sample)
    $numbers = [
        ['n_1', 'numbers', '᱑', '1', 'mit', '', 0, 1, 'One'],
        ['n_2', 'numbers', '᱒', '2', 'bar', '', 1, 1, 'Two'],
        ['n_3', 'numbers', '᱓', '3', 'pe', '', 2, 1, 'Three'],
        ['n_4', 'numbers', '᱔', '4', 'pon', '', 3, 1, 'Four'],
        ['n_5', 'numbers', '᱕', '5', 'mone', '', 4, 1, 'Five']
    ];
    // Schema: numbers (id, category_id, symbol_ol_chiki, symbol_latin, name_latin, image_url, `order`, is_active, description)

    $stmt = $db->prepare("REPLACE INTO numbers (id, category_id, symbol_ol_chiki, symbol_latin, name_latin, image_url, `order`, is_active, description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
    foreach ($numbers as $num) {
        $stmt->execute($num);
    }
    echo "Numbers seeded.\n";

    // Seed Rhymes
    $rhymes = [
        ['rhyme_1', 'Animal', 'Wild Animals', 'ᱦᱟᱹᱛᱤ ᱞᱟᱹᱜᱤᱫ', 'Hati Lagit', 'assets/images/rhyme_hati.png', 'https://example.com/audio1.mp3', 'ᱦᱟᱹᱛᱤ ᱞᱟᱹᱜᱤᱫ ᱦᱟᱹᱛᱤ...\nᱥᱮᱛᱟ ᱞᱟᱹᱜᱤᱫ ᱥᱮᱛᱟ...', 'Hati lagit hati...\nSeta lagit seta...'],
        ['rhyme_2', 'Nature', 'Mountains', 'ᱵᱩᱨᱩ ᱨᱮ', 'Buru Re', '', '', 'ᱵᱩᱨᱩ ᱨᱮ ᱵᱩᱨᱩ...\nᱡᱷᱟᱨᱱᱟ ᱨᱮ ᱡᱷᱟᱨᱱᱟ...', 'Buru re buru...\nJharna re jharna...']
    ];
    // Schema: rhymes (id, category, subcategory, title_ol_chiki, title_latin, thumbnail_url, audio_url, content_ol_chiki, content_latin)
    // Note: timestamps are handled by default current_timestamp usually, or we skip them.

    $stmt = $db->prepare("REPLACE INTO rhymes (id, category, subcategory, title_ol_chiki, title_latin, thumbnail_url, audio_url, content_ol_chiki, content_latin) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
    foreach ($rhymes as $rhyme) {
        $stmt->execute($rhyme);
    }
    echo "Rhymes seeded.\n";

    echo json_encode(["status" => "success", "message" => "Database seeded successfully."]);

} catch(PDOException $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
