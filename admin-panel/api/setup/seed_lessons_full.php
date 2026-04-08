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
    
    // Clear existing data to ensure a fresh comprehensive seed if needed
    // WARNING: Be careful with clearing data on live. 
    // Using REPLACE INTO instead to avoid total wipe but update all standard IDs.

    // 1. Seed Categories
    $categories = [
        ['cat_alphabet', 'ᱚᱞ ᱪᱤᱠᱤ ᱟᱠᱷᱟ', 'Ol Chiki Alphabet', 'alphabet', 'skyBlue', 0, 1, 30, 'Learn the 30 letters of the Ol Chiki script.'],
        ['cat_numbers', 'ᱮᱞᱠᱷᱟ ᱠᱚ', 'Numbers', 'numbers', 'peach', 1, 1, 10, 'Master counting from 0 to 9 and beyond.'],
        ['cat_words', 'ᱨᱚᱲ ᱠᱚ', 'Common Words', 'words', 'mint', 2, 1, 50, 'Expand your vocabulary with common Santali words.'],
        ['cat_phrases', 'ᱣᱟᱠᱭ ᱠᱚ', 'Phrases', 'stories', 'sunset', 3, 1, 20, 'Learn useful phrases for daily conversation.'],
        ['cat_rhymes', 'ᱥᱮᱨᱮᱧ ᱠᱚ', 'Rhymes', 'music_note', 4, 1, 15, 'Fun Santali rhymes for all ages.']
    ];

    $stmt = $db->prepare("REPLACE INTO categories (id, title_ol_chiki, title_latin, icon_name, gradient_preset, order_index, is_active, total_lessons, description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
    foreach ($categories as $cat) {
        $stmt->execute($cat);
    }
    echo "Categories seeded.\n";

    // 2. Seed All 30 Letters
    $letters = [
        ['l_la', 'ᱚ', 'La (a)', 0, 1, 'Ol (Write)', 'la.mp3'],
        ['l_at', 'ᱛ', 'At (t)', 1, 1, 'At (Place)', 'at.mp3'],
        ['l_ag', 'ᱜ', 'Ag (g)', 2, 1, 'Ag (Bring)', 'ag.mp3'],
        ['l_ang', 'ᱝ', 'Ang (ng)', 3, 1, 'Ang (Light)', 'ang.mp3'],
        ['l_al', 'ᱞ', 'Al (l)', 4, 1, 'Al (Write)', 'al.mp3'],
        
        ['l_laa', 'ᱟ', 'Laa (aa)', 5, 1, 'Aa (Aah)', 'laa.mp3'],
        ['l_ak', 'ᱠ', 'Ak (k)', 6, 1, 'Ka (Word)', 'ak.mp3'],
        ['l_aj', 'ᱡ', 'Aj (j)', 7, 1, 'Ja (Water)', 'aj.mp3'],
        ['l_am', 'ᱢ', 'Am (m)', 8, 1, 'Ma (Mother)', 'am.mp3'],
        ['l_aw', 'ᱣ', 'Aw (w)', 9, 1, 'Wa (See)', 'aw.mp3'],
        
        ['l_li', 'ᱤ', 'Li (i)', 10, 1, 'Ir (Harvest)', 'li.mp3'],
        ['l_is', 'ᱥ', 'Is (s)', 11, 1, 'Si (Plough)', 'is.mp3'],
        ['l_ih', 'ᱦ', 'Ih (h)', 12, 1, 'Ha (Fish)', 'ih.mp3'],
        ['l_iny', 'ᱧ', 'Iny (ny)', 13, 1, 'Ny (See)', 'iny.mp3'],
        ['l_ir', 'ᱨ', 'Ir (r)', 14, 1, 'Ra (Cry)', 'ir.mp3'],
        
        ['l_lu', 'ᱩ', 'Lu (u)', 15, 1, 'Ul (Mango)', 'lu.mp3'],
        ['l_uc', 'ᱪ', 'Uc (c)', 16, 1, 'Ca (Tea)', 'uc.mp3'],
        ['l_ud', 'ᱫ', 'Ud (d)', 17, 1, 'Da (Water)', 'ud.mp3'],
        ['l_unn', 'ᱬ', 'Unn (nn)', 18, 1, 'Nn (Sound)', 'unn.mp3'],
        ['l_uy', 'ᱭ', 'Uy (y)', 19, 1, 'Ya (Friend)', 'uy.mp3'],
        
        ['l_le', 'ᱮ', 'Le (e)', 20, 1, 'En (Then)', 'le.mp3'],
        ['l_ep', 'ᱯ', 'Ep (p)','21', 1, 'Pa (Read)', 'ep.mp3'],
        ['l_edd', 'ᱰ', 'Edd (dd)', 22, 1, 'Dd (Drum)', 'edd.mp3'],
        ['l_en', 'ᱱ', 'En (n)', 23, 1, 'Na (Now)', 'en.mp3'],
        ['l_err', 'ᱲ', 'Err (rr)', 24, 1, 'Rr (Sound)', 'err.mp3'],
        
        ['l_lo', 'ᱳ', 'Lo (o)', 25, 1, 'Ol (Write)', 'lo.mp3'],
        ['l_ott', 'ᱴ', 'Ott (tt)', 26, 1, 'Tt (Sound)', 'ott.mp3'],
        ['l_obb', 'ᱵ', 'Obb (b)', 27, 1, 'Ba (Flower)', 'obb.mp3'],
        ['l_ov', 'ᱶ', 'Ov (v)', 28, 1, 'Va (Sound)', 'ov.mp3'],
        ['l_oh', 'ᱷ', 'Oh (h)', 29, 1, 'Ha (Yes)', 'oh.mp3']
    ];

    $stmt = $db->prepare("REPLACE INTO letters (id, char_ol_chiki, transliteration_latin, order_index, is_active, example_word, audio_url) VALUES (?, ?, ?, ?, ?, ?, ?)");
    foreach ($letters as $letter) {
        $stmt->execute($letter);
    }
    echo "Letters seeded.\n";

    // 3. Seed All 10 Digits
    $numbers = [
        ['n_0', '᱐', 0, 'ᱥᱩᱱ', 'Sun', 0],
        ['n_1', '᱑', 1, 'ᱢᱤᱛ', 'Mit', 1],
        ['n_2', '᱒', 2, 'ᱵᱟᱨ', 'Bar', 2],
        ['n_3', '᱓', 3, 'ᱯᱮ', 'Pe', 3],
        ['n_4', '᱔', 4, 'ᱯᱚᱱ', 'Pon', 4],
        ['n_5', '᱕', 5, 'ᱢᱚᱬᱮ', 'Mone', 5],
        ['n_6', '᱖', 6, 'ᱛᱩᱨᱩᱭ', 'Turui', 6],
        ['n_7', '᱗', 7, 'ᱮᱭᱟᱭ', 'Eae', 7],
        ['n_8', '８', 8, 'ᱤᱨᱟᱹᱞ', 'Irel', 8],
        ['n_9', '᱙', 9, 'ᱟᱨᱮ', 'Are', 9]
    ];

    $stmt = $db->prepare("REPLACE INTO numbers (id, numeral, value, name_ol_chiki, name_latin, order_index) VALUES (?, ?, ?, ?, ?, ?)");
    foreach ($numbers as $num) {
        $stmt->execute($num);
    }
    echo "Numbers seeded.\n";

    // 4. Seed Lessons
    $lessons = [
        ['less_intro', 'cat_alphabet', 'ᱚᱞ ᱪᱤᱠᱤ ᱢᱮᱱᱟᱜ', 'Introduction to Ol Chiki', 'beginner', 0, 1, 5, 'Learn about the history and basics of Ol Chiki script.'],
        ['less_vowels', 'cat_alphabet', 'ᱨᱟᱦᱟ ᱟᱲᱟᱝ ᱠᱚ', 'The Vowels', 'beginner', 1, 1, 10, 'Master the 6 basic vowels of Ol Chiki.'],
        ['less_consonants_1', 'cat_alphabet', 'ᱠᱮᱪᱮᱫ ᱟᱲᱟᱝ ᱠᱚ ᱑', 'Consonants (Part 1)', 'beginner', 2, 1, 15, 'Learn the first group of consonants.'],
        ['less_counting_basic', 'cat_numbers', 'ᱞᱮᱠᱷᱟ ᱑-᱑᱐', 'Counting 1-10', 'beginner', 0, 1, 5, 'Learn basic counting in Santali.'],
        ['less_greetings', 'cat_phrases', 'ᱡᱚᱦᱟᱨ ᱨᱚᱲ ᱠᱚ', 'Greetings', 'beginner', 0, 1, 8, 'Essential Santali greetings for daily life.']
    ];

    $stmt = $db->prepare("REPLACE INTO lessons (id, category_id, title_ol_chiki, title_latin, level, order_index, is_active, estimated_minutes, description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
    foreach ($lessons as $lesson) {
        $stmt->execute($lesson);
    }
    echo "Lessons seeded.\n";

    // 5. Seed Lesson Blocks for "The Vowels"
    $vowel_blocks = [
        ['block_v_1', 'less_vowels', 'text', json_encode([
            'textOlChiki' => 'ᱚᱞ ᱪᱤᱠᱤ ᱨᱮ ᱖ ᱜᱚᱴᱟᱝ ᱨᱟᱦᱟ ᱟᱲᱟᱝ ᱢᱮᱱᱟᱜ-ᱟ:',
            'textLatin' => 'There are 6 vowels in Ol Chiki:'
        ]), 0],
        ['block_v_2', 'less_vowels', 'text', json_encode([
            'textOlChiki' => 'ᱚ (La), ᱟ (Laa), ᱤ (Li), ᱩ (Lu), ᱮ (Le), ᱳ (Lo)',
            'textLatin' => 'o, aa, i, u, e, o'
        ]), 1],
        ['block_v_3', 'less_vowels', 'image', json_encode([
            'url' => 'https://example.com/assets/vowels_chart.png',
            'caption' => 'Ol Chiki Vowels Chart'
        ]), 2]
    ];

    $stmt = $db->prepare("REPLACE INTO lesson_blocks (id, lesson_id, type, content_json, order_index) VALUES (?, ?, ?, ?, ?)");
    foreach ($vowel_blocks as $block) {
        $stmt->execute($block);
    }
    echo "Lesson blocks seeded.\n";

    echo json_encode(["status" => "success", "message" => "Full Ol Chiki curriculum seeded successfully!"]);

} catch(PDOException $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
