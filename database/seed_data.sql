-- Seed Categories
INSERT INTO `categories` (id, title_ol_chiki, title_latin, icon_name, gradient_preset, order_index, is_active, total_lessons, description) VALUES
('cat_alphabet', 'ᱚᱞ ᱪᱤᱠᱤ ᱟᱠᱷᱟ', 'Alphabet', 'alphabet', 'skyBlue', 0, 1, 30, 'Learn the Ol Chiki script letters'),
('cat_numbers', 'ᱮᱞᱠᱷᱟ ᱠᱚ', 'Numbers', 'numbers', 'sunset', 1, 1, 10, 'Learn Santali numbers and counting'),
('cat_words', 'ᱨᱚᱲ ᱠᱚ', 'Words', 'words', 'forest', 2, 1, 50, 'Build your Santali vocabulary'),
('cat_sentences', 'ᱣᱟᱠᱭ ᱠᱚ', 'Sentences', 'stories', 'ocean', 3, 1, 20, 'Form sentences in Santali');

-- Seed All 30 Letters
INSERT INTO `letters` (id, char_ol_chiki, transliteration_latin, order_index, is_active, example_word) VALUES
('l_la', 'ᱚ', 'La (a)', 0, 1, 'Ol'), ('l_at', 'ᱛ', 'At (t)', 1, 1, 'At'), ('l_ag', 'ᱜ', 'Ag (g)', 2, 1, 'Ag'), ('l_ang', 'ᱝ', 'Ang (ng)', 3, 1, 'Ang'), ('l_al', 'ᱞ', 'Al (l)', 4, 1, 'Al'),
('l_laa', 'ᱟ', 'Laa (aa)', 5, 1, 'Aa'), ('l_ak', 'ᱠ', 'Ak (k)', 6, 1, 'Ka'), ('l_aj', 'ᱡ', 'Aj (j)', 7, 1, 'Ja'), ('l_am', 'ᱢ', 'Am (m)', 8, 1, 'Ma'), ('l_aw', 'ᱣ', 'Aw (w)', 9, 1, 'Wa'),
('l_li', 'ᱤ', 'Li (i)', 10, 1, 'Ir'), ('l_is', 'ᱥ', 'Is (s)', 11, 1, 'Si'), ('l_ih', 'ᱦ', 'Ih (h)', 12, 1, 'Ha'), ('l_iny', 'ᱧ', 'Iny (ny)', 13, 1, 'Ny'), ('l_ir', 'ᱨ', 'Ir (r)', 14, 1, 'Ra'),
('l_lu', 'ᱩ', 'Lu (u)', 15, 1, 'Ul'), ('l_uc', 'ᱪ', 'Uc (c)', 16, 1, 'Ca'), ('l_ud', 'ᱫ', 'Ud (d)', 17, 1, 'Da'), ('l_unn', 'ᱬ', 'Unn (nn)', 18, 1, 'Nn'), ('l_uy', 'ᱭ', 'Uy (y)', 19, 1, 'Ya'),
('l_le', 'ᱮ', 'Le (e)', 20, 1, 'En'), ('l_ep', 'ᱯ', 'Ep (p)', 21, 1, 'Pa'), ('l_edd', 'ᱰ', 'Edd (dd)', 22, 1, 'Dd'), ('l_en', 'ᱱ', 'En (n)', 23, 1, 'Na'), ('l_err', 'ᱲ', 'Err (rr)', 24, 1, 'Rr'),
('l_lo', 'ᱳ', 'Lo (o)', 25, 1, 'Ol'), ('l_ott', 'ᱴ', 'Ott (tt)', 26, 1, 'Tt'), ('l_obb', 'ᱵ', 'Obb (b)', 27, 1, 'Ba'), ('l_ov', 'ᱶ', 'Ov (v)', 28, 1, 'Va'), ('l_oh', 'ᱷ', 'Oh (h)', 29, 1, 'Ha');

-- Seed All 10 Digits
INSERT INTO `numbers` (id, numeral, value, name_ol_chiki, name_latin, order_index) VALUES
('n_0', '᱐', 0, 'ᱥᱩᱱ', 'Sun', 0), ('n_1', '᱑', 1, 'ᱢᱤᱛ', 'Mit', 1), ('n_2', '᱒', 2, 'ᱵᱟᱨ', 'Bar', 2), ('n_3', '', 3, 'ᱯᱮ', 'Pe', 3), ('n_4', '᱔', 4, 'ᱯᱚᱱ', 'Pon', 4),
('n_5', '᱕', 5, 'ᱢᱚᱬᱮ', 'Mone', 5), ('n_6', '᱖', 6, 'ᱛᱩᱨᱩᱭ', 'Turui', 6), ('n_7', '᱗', 7, 'ᱮᱭᱟᱭ', 'Eae', 7), ('n_8', '᱘', 8, 'ᱤᱨᱟᱹᱞ', 'Irel', 8), ('n_9', '᱙', 9, 'ᱟᱨᱮ', 'Are', 9);

