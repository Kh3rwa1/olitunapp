import fs from 'fs';

const cache = JSON.parse(fs.readFileSync('scripts/translations_cache.json', 'utf8'));

// 1. Remove old part files first
for (let i = 1; i <= 30; i++) {
  try { fs.unlinkSync(`lib/core/languages/indic_translations_sentences_part${i}.dart`); } catch (_) {}
  try { fs.unlinkSync(`lib/core/languages/indic_translations_words_part${i}.dart`); } catch (_) {}
}

// 2. Generate split Dart sentence files (max 60 items per part -> ~360 formatted lines)
const sentenceEntries = Object.entries(cache.sentences || {});
console.log(`Loaded ${sentenceEntries.length} sentence entries from cache.`);

function chunkArray(array, size) {
  const chunks = [];
  for (let i = 0; i < array.length; i += size) {
    chunks.push(array.slice(i, i + size));
  }
  return chunks;
}

const sentenceChunks = chunkArray(sentenceEntries, 60);
console.log(`Split sentences into ${sentenceChunks.length} chunks.`);

function escapeDart(str) {
  return (str || '')
    .replace(/\\/g, '\\\\')
    .replace(/'/g, "\\'")
    .replace(/\$/g, '\\$')
    .replace(/\n/g, '\\n')
    .replace(/\r/g, '');
}

const sentencePartClassNames = [];

sentenceChunks.forEach((chunk, index) => {
  const partNum = index + 1;
  const className = `IndicTranslationsSentencesPart${partNum}`;
  sentencePartClassNames.push(className);

  const lines = [
    `/// Auto-generated sentence translations chunk part ${partNum} for Indic languages.`,
    `class ${className} {`,
    `  const ${className}._();`,
    ``,
    `  static const Map<String, Map<String, String>> translations = {`,
  ];

  for (const [key, val] of chunk) {
    const escapedKey = escapeDart(key);
    const bn = escapeDart(val.bn || '');
    const hi = escapeDart(val.hi || '');
    const or = escapeDart(val.or || '');
    const en = escapeDart(val.en || key);
    lines.push(`    '${escapedKey}': {'bn': '${bn}', 'hi': '${hi}', 'or': '${or}', 'en': '${en}'},`);
  }

  lines.push(`  };`);
  lines.push(`}`);
  lines.push(``);

  fs.writeFileSync(`lib/core/languages/indic_translations_sentences_part${partNum}.dart`, lines.join('\n'), 'utf8');
});

// Write master sentences aggregator
const sentenceAggregatorLines = [
  ...sentencePartClassNames.map((c, i) => `import 'indic_translations_sentences_part${i + 1}.dart';`),
  ``,
  `/// Auto-generated aggregated sentence translations for Bengali, Hindi, Odia, and English.`,
  `class IndicTranslationsSentences {`,
  `  const IndicTranslationsSentences._();`,
  ``,
  `  static const Map<String, Map<String, String>> translations = {`,
  ...sentencePartClassNames.map(c => `    ...${c}.translations,`),
  `  };`,
  `}`,
  ``
];
fs.writeFileSync('lib/core/languages/indic_translations_sentences.dart', sentenceAggregatorLines.join('\n'), 'utf8');

// 3. Generate split Dart words files (max 60 items per part -> ~360 formatted lines)
const wordEntries = Object.entries(cache.words || {});
console.log(`Loaded ${wordEntries.length} word entries from cache.`);
const wordChunks = chunkArray(wordEntries, 60);
console.log(`Split words into ${wordChunks.length} chunks.`);

const wordPartClassNames = [];

wordChunks.forEach((chunk, index) => {
  const partNum = index + 1;
  const className = `IndicTranslationsWordsPart${partNum}`;
  wordPartClassNames.push(className);

  const lines = [
    `/// Auto-generated vocabulary translations chunk part ${partNum} for Indic languages.`,
    `class ${className} {`,
    `  const ${className}._();`,
    ``,
    `  static const Map<String, Map<String, String>> translations = {`,
  ];

  for (const [key, val] of chunk) {
    const escapedKey = escapeDart(key);
    const bn = escapeDart(val.bn || '');
    const hi = escapeDart(val.hi || '');
    const or = escapeDart(val.or || '');
    const en = escapeDart(val.en || key);
    lines.push(`    '${escapedKey}': {'bn': '${bn}', 'hi': '${hi}', 'or': '${or}', 'en': '${en}'},`);
  }

  lines.push(`  };`);
  lines.push(`}`);
  lines.push(``);

  fs.writeFileSync(`lib/core/languages/indic_translations_words_part${partNum}.dart`, lines.join('\n'), 'utf8');
});

// Write master words aggregator
const wordAggregatorLines = [
  ...wordPartClassNames.map((c, i) => `import 'indic_translations_words_part${i + 1}.dart';`),
  ``,
  `/// Auto-generated aggregated vocabulary translations for Bengali, Hindi, Odia, and English.`,
  `class IndicTranslationsWords {`,
  `  const IndicTranslationsWords._();`,
  ``,
  `  static const Map<String, Map<String, String>> translations = {`,
  ...wordPartClassNames.map(c => `    ...${c}.translations,`),
  `  };`,
  `}`,
  ``
];
fs.writeFileSync('lib/core/languages/indic_translations_words.dart', wordAggregatorLines.join('\n'), 'utf8');

console.log('✅ Generated all Dart modular translation files with 60-item chunks.');
