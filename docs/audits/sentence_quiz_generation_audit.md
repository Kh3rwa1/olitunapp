# Sentence Quiz Generation Audit

Date: 2026-09-18
Scope: all 23 lessons in `assets/seed/sentence_lessons.json` (every entry is
active — none sets `isActive: false`, matching the `LessonModel.fromJson`
default of `true`).
Validator: `node scripts/validate_sentence_quizzes.mjs` (block-level checks)
plus `test/features/quiz/seed_sentence_quiz_validation_test.dart`, which runs
the real `LessonQuizGenerator` over the bundled seed.

## Background

Sentence lessons whose blocks were missing or malformed used to finish with a
single meaningless question ("Choose the correct Hindi title for this
lesson") produced by the `questions.isEmpty` title fallback in
`lib/features/quiz/domain/lesson_quiz_generator.dart`. The fallback has been
removed: invalid content now yields an empty quiz and the UI fails closed
with "Quiz unavailable — this lesson does not contain enough valid questions
yet." No production Appwrite data was modified for this audit.

## Method

For each active lesson, non-`quiz` blocks were evaluated with the same rules
the generator enforces:

- valid block: non-empty `textOlChiki` + `textLatin`;
- Hindi/Bengali/Odia additionally require an explicit localized meaning
  (`data.meaning_<lang>` or the `textHindi`/`textBengali`/`textOdia` field) —
  romanized Santali is never presented as an Indic meaning
  (`missing_meaning`);
- duplicate `textOlChiki` prompts are rejected (`duplicate_content`);
- estimated questions = unique valid prompts capped at 10 (the generator
  always has enough generic distractors to build four unique options, and
  rejects the block as `insufficient_distractors` otherwise).

Rejection diagnostics carry lesson ID and block index only — never sentence
text or translations.

## Results

| Lesson ID | Title | Blocks | Valid | Q(en) | Q(hi) | Duplicates | Rejection reasons |
|---|---|---|---|---|---|---|---|
| lesson_sentences_basics | Basic Sentences | 20 | 20 | 10 | 10 | 0 | — |
| lesson_sentences_conversations | Daily Conversations | 20 | 20 | 10 | 10 | 0 | — |
| lesson_sentences_polite | Greetings & Politeness | 20 | 20 | 10 | 10 | 0 | — |
| lesson_sentences_time_weather | Time & Weather | 20 | 20 | 10 | 10 | 0 | — |
| lesson_sentences_complex_beginner | Simple Dialogues & Routines | 20 | 20 | 10 | 10 | 0 | — |
| lesson_sentences_complex_intermed | Village & Social Life | 20 | 20 | 10 | 10 | 0 | — |
| lesson_sentences_complex_advanced | Traditional Wisdom & Ecology | 20 | 20 | 10 | 10 | 0 | — |
| lesson_sentences_conversational_1 | Modern Conversational Exchanges I | 22 | 22 | 10 | 10 | 0 | — |
| lesson_sentences_conversational_2 | Modern Conversational Exchanges II | 22 | 22 | 10 | 10 | 0 | — |
| lesson_sentences_conversational_3 | Modern Conversational Exchanges III | 22 | 22 | 10 | 10 | 0 | — |
| lesson_sentences_folk_1 | Cultural Proverbs & Wisdom I | 22 | 22 | 10 | 10 | 0 | — |
| lesson_sentences_folk_2 | Cultural Proverbs & Wisdom II | 23 | 23 | 10 | 10 | 0 | — |
| lesson_sentences_folk_3 | Cultural Proverbs & Wisdom III | 23 | 23 | 10 | 10 | 0 | — |
| lesson_grammar_pronouns | Santali Pronouns & Persons | 7 | 7 | 7 | 7 | 0 | — |
| lesson_grammar_questions_cases | Questions & Direction Markers | 7 | 7 | 7 | 7 | 0 | — |
| lesson_grammar_verb_tenses | Verb Tenses & Suffixes | 3 | 3 | 3 | 3 | 0 | thin content (3 valid blocks) |
| lesson_grammar_possessives | Possessives & Pronouns | 3 | 3 | 3 | 3 | 0 | thin content (3 valid blocks) |
| lesson_grammar_plurals_numbers | Plurals & Number Agreements | 2 | 2 | 2 | 2 | 0 | thin content (2 valid blocks) |
| lesson_grammar_conjunctions | Conjunctions & Connectors | 2 | 2 | 2 | 2 | 0 | thin content (2 valid blocks) |
| lesson_story_fox_crow | The Clever Crow & The Water Pot | 5 | 5 | 5 | 5 | 0 | — |
| lesson_story_deer_tiger | The Wise Deer & The Tiger | 5 | 5 | 5 | 5 | 0 | — |
| lesson_story_two_birds | The Two Birds of Marang Buru | 5 | 5 | 5 | 5 | 0 | — |
| lesson_story_village_harvest | The Joy of Sohrai Harvest | 5 | 5 | 5 | 5 | 0 | — |

Counts exclude authored `quiz`-type blocks (the four thin grammar lessons and
the four stories each embed quiz links, which are quiz references, not
sentence content). Bengali/Odia meaning coverage matches Hindi for every
lesson above.

## Findings

1. **The 1/1 title quiz hit every lesson through the full-screen quiz
   route, not because of per-lesson content.** The lesson catalog is
   intentionally metadata-only (`learnerLessonsProvider`: "Catalog providers
   intentionally keep lesson blocks empty"); the full body arrives via
   `learnerLessonDetailProvider`, which `LessonBlockDetailScreen` uses but
   `quizResultProvider` did not. Every `dynamic_quiz_*` opened through
   `/quiz/:quizId` therefore generated from zero blocks and took the title
   fallback. `quizResultProvider` now hydrates through the detail boundary
   before generating (loading while hydrating, fail-closed error when
   hydration fails, direct generation for lessons that already carry
   blocks) — covered by
   `test/features/quiz/quiz_result_hydration_test.dart`. "Modern
   Conversational Exchanges III" is healthy in the bundled seed (22 valid
   blocks, 10 Hindi questions from `data.meaning_hi`), so with hydration it
   generates real sentence questions.
2. **Four lessons generate fewer than five questions**: the grammar lessons
   listed above (3/3/2/2). They need more sentence blocks (content work —
   no production data was changed).
3. **No lesson has duplicate prompts** (`duplicate_content` never fires on
   current seed) and Bengali/Odia coverage is complete.
4. **No seed sentence block carries a `sourceSentenceId`** (or legacy
   alias), so all generated sentence questions are non-memory: they never
   contribute mastery tracking. Adding canonical sentence IDs is content work
   requiring explicit approval and is out of scope here. The generator
   preserves `sourceSentenceId` end-to-end when present (tested), and the
   publish boundary (`validateQuizForPublish`) still fails closed on
   unattributed memory questions.
