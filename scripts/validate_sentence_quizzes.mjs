#!/usr/bin/env node
/**
 * Validates bundled sentence lessons for quiz generation.
 *
 * For every active lesson in assets/seed/sentence_lessons.json it checks:
 *  - at least 5 valid sentence blocks (textOlChiki + textLatin);
 *  - at least 5 estimated questions in English and Hindi
 *    (unique prompts, capped at 10 like LessonQuizGenerator; Hindi/Bengali/
 *    Odia additionally require an explicit localized meaning — romanized
 *    Santali must never be presented as an Indic meaning);
 *  - no duplicate prompts (the generator rejects them as duplicate_content);
 *  - canonical sourceSentenceId attribution is reported (questions without
 *    it are non-memory and contribute no mastery).
 *
 * Generator-side invariants (no title-fallback questions, four unique
 * non-empty options, valid correctIndex) are enforced by
 * test/features/quiz/seed_sentence_quiz_validation_test.dart, which runs
 * the real LessonQuizGenerator.
 *
 * Usage: node scripts/validate_sentence_quizzes.mjs [--repo <root>]
 * Exits 1 when any active lesson violates the thresholds.
 */
import fs from 'node:fs';
import path from 'node:path';

const MIN_BLOCKS = 5;
const MIN_QUESTIONS = 5;
const MAX_QUESTIONS = 10;

const args = process.argv.slice(2);
const repoFlag = args.indexOf('--repo');
const repoRoot = repoFlag === -1 ? process.cwd() : args[repoFlag + 1];
const seedPath = path.join(
  repoRoot,
  'assets',
  'seed',
  'sentence_lessons.json',
);

const nonEmpty = (value) =>
  typeof value === 'string' && value.trim().length > 0;

// Production stores meanings under block `meta` instead of `data`
// (seed files use `data`); explicit `data` wins on conflicts.
function payload(block) {
  const data =
    block.data && typeof block.data === 'object' ? block.data : {};
  const meta =
    block.meta && typeof block.meta === 'object' ? block.meta : {};
  return { ...meta, ...data };
}

function explicitMeaning(block, lang) {
  const merged = payload(block);
  if (nonEmpty(merged[`meaning_${lang}`])) return true;
  if (lang === 'hi') return nonEmpty(block.textHindi ?? merged.textHindi);
  if (lang === 'bn') return nonEmpty(block.textBengali ?? merged.textBengali);
  if (lang === 'or') return nonEmpty(block.textOdia ?? merged.textOdia);
  return false;
}

function estimateQuestions(blocks, lang) {
  const seen = new Set();
  let count = 0;
  const reasons = [];
  blocks.forEach((block, index) => {
    const ol = (block.textOlChiki ?? '').trim();
    const latin = (block.textLatin ?? '').trim();
    if (!ol) {
      reasons.push({ index, reason: 'missing_ol_chiki' });
      return;
    }
    if (!latin) {
      reasons.push({ index, reason: 'missing_latin' });
      return;
    }
    if (
      (lang === 'hi' || lang === 'bn' || lang === 'or') &&
      !explicitMeaning(block, lang)
    ) {
      reasons.push({ index, reason: 'missing_meaning' });
      return;
    }
    if (seen.has(ol)) {
      reasons.push({ index, reason: 'duplicate_content' });
      return;
    }
    seen.add(ol);
    count += 1;
  });
  return { count: Math.min(count, MAX_QUESTIONS), reasons };
}

function main() {
  const lessons = JSON.parse(fs.readFileSync(seedPath, 'utf8'));
  let failures = 0;
  console.log(
    'lesson_id,blocks,valid_en,q_en,q_hi,duplicates,attributed,finding',
  );
  for (const lesson of lessons) {
    if (lesson.isActive === false) continue;
    const blocks = (lesson.blocks ?? []).filter((b) => b.type !== 'quiz');
    const validEn = blocks.filter(
      (b) => nonEmpty(b.textOlChiki) && nonEmpty(b.textLatin),
    ).length;
    const en = estimateQuestions(blocks, 'en');
    const hi = estimateQuestions(blocks, 'hi');
    const attributed = blocks.filter((b) => {
      const merged = payload(b);
      return ['sourceSentenceId', 'sentenceId', 'sourceSentence'].some((k) =>
        nonEmpty(merged[k]),
      );
    }).length;
    const findings = [];
    if (validEn < MIN_BLOCKS) findings.push(`only ${validEn} valid blocks`);
    if (en.count < MIN_QUESTIONS)
      findings.push(`only ${en.count} en questions`);
    if (hi.count < MIN_QUESTIONS)
      findings.push(`only ${hi.count} hi questions`);
    if (findings.length > 0) failures += 1;
    console.log(
      [
        lesson.id,
        blocks.length,
        validEn,
        en.count,
        hi.count,
        en.reasons.filter((r) => r.reason === 'duplicate_content').length,
        attributed,
        findings.join('; ') || 'ok',
      ].join(','),
    );
  }
  if (failures > 0) {
    console.error(
      `\n${failures} active lesson(s) below thresholds ` +
        `(${MIN_BLOCKS} blocks / ${MIN_QUESTIONS} questions). ` +
        'See docs/audits/sentence_quiz_generation_audit.md.',
    );
    process.exit(1);
  }
  console.log('\nAll active sentence lessons meet quiz thresholds.');
}

main();
