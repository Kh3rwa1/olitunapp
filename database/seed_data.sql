-- Seed Categories
INSERT INTO `categories` (id, title_ol_chiki, title_latin, icon_name, gradient_preset, order_index, is_active, total_lessons, description) VALUES
('cat_alphabet', 'ᱚᱞ ᱪᱤᱠᱤ', 'Alphabet', 'alphabet', 'skyBlue', 0, 1, 6, 'Learn the Ol Chiki script letters'),
('cat_numbers', 'ᱮᱞᱠᱷᱟ', 'Numbers', 'numbers', 'sunset', 1, 1, 4, 'Learn Santali numbers and counting'),
('cat_words', 'ᱨᱚᱲ', 'Words', 'words', 'forest', 2, 1, 5, 'Build your Santali vocabulary'),
('cat_sentences', 'ᱣᱟᱠᱭ', 'Sentences', 'stories', 'ocean', 3, 1, 4, 'Form sentences in Santali');

-- Seed Lessons for Alphabet
INSERT INTO `lessons` (id, category_id, title_ol_chiki, title_latin, level, order_index, is_active, estimated_minutes, description) VALUES
('less_vowels_1', 'cat_alphabet', 'ᱚᱞ ᱪᱤᱠᱤ ᱟᱹᱲᱟᱝ', 'Vowels (Part 1)', 'beginner', 0, 1, 5, 'Learn the first 3 Ol Chiki vowels'),
('less_vowels_2', 'cat_alphabet', 'ᱚᱞ ᱪᱤᱠᱤ ᱟᱹᱲᱟᱝ', 'Vowels (Part 2)', 'beginner', 1, 1, 5, 'Learn the next 3 Ol Chiki vowels');

-- Seed Letters (Sample)
INSERT INTO `letters` (id, char_ol_chiki, transliteration_latin, order_index, is_active, example_word) VALUES
('l_a', 'ᱚ', 'La', 0, 1, 'Ol'),
('l_aa', 'ᱟ', 'Aah', 1, 1, 'At'),
('l_i', 'ᱤ', 'Li', 2, 1, 'Ir');
