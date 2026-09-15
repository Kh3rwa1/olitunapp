#!/usr/bin/env node
/**
 * Validates corpus identity integrity across:
 *   - assets/seed/words.json
 *   - assets/seed/sentences.json
 *   - assets/seed/review_item_id_migrations.json
 *
 * Exits nonzero with actionable error messages for:
 *   - missing IDs, blank IDs
 *   - duplicate word IDs, duplicate sentence IDs
 *   - word/sentence cross-type ID collisions
 *   - malformed aliases, duplicate aliases, ambiguous aliases, alias cycles
 *   - missing alias targets, alias type mismatches
 *   - duplicate tombstones, IDs both active and tombstoned
 *   - malformed manifest schema versions
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export function validateCorpus({ words, sentences, manifest, fileNames = {} }) {
  const wordsFile = fileNames.words || 'assets/seed/words.json';
  const sentencesFile = fileNames.sentences || 'assets/seed/sentences.json';
  const manifestFile = fileNames.manifest || 'assets/seed/review_item_id_migrations.json';

  const errors = [];

  function addError(file, message, id = null) {
    errors.push({ file, message, id });
  }

  // 1. Validate manifest schemaVersion and top-level arrays
  if (!manifest || typeof manifest !== 'object' || Array.isArray(manifest)) {
    addError(manifestFile, 'Manifest must be a JSON object');
    return { valid: false, errors };
  }

  if (
    typeof manifest.schemaVersion !== 'number' ||
    !Number.isInteger(manifest.schemaVersion) ||
    manifest.schemaVersion !== 1
  ) {
    addError(
      manifestFile,
      `Invalid schemaVersion: ${manifest.schemaVersion}. Expected integer 1`
    );
  }

  if (!Array.isArray(manifest.aliases)) {
    addError(manifestFile, 'Manifest aliases must be an array');
  }
  if (!Array.isArray(manifest.tombstones)) {
    addError(manifestFile, 'Manifest tombstones must be an array');
  }

  // 2. Validate words
  const wordIds = new Set();
  if (Array.isArray(words)) {
    words.forEach((w, index) => {
      if (!w || typeof w !== 'object') {
        addError(wordsFile, `Word entry at index ${index} is not an object`);
        return;
      }
      if (typeof w.id !== 'string') {
        addError(wordsFile, `Missing or non-string id at index ${index}`);
        return;
      }
      const trimmedId = w.id.trim();
      if (trimmedId.length === 0) {
        addError(wordsFile, `Blank id at index ${index}`);
        return;
      }
      if (wordIds.has(trimmedId)) {
        addError(wordsFile, `Duplicate word ID: "${trimmedId}"`, trimmedId);
      } else {
        wordIds.add(trimmedId);
      }
    });
  } else {
    addError(wordsFile, 'Words catalog must be an array');
  }

  // 3. Validate sentences
  const sentenceIds = new Set();
  if (Array.isArray(sentences)) {
    sentences.forEach((s, index) => {
      if (!s || typeof s !== 'object') {
        addError(sentencesFile, `Sentence entry at index ${index} is not an object`);
        return;
      }
      if (typeof s.id !== 'string') {
        addError(sentencesFile, `Missing or non-string id at index ${index}`);
        return;
      }
      const trimmedId = s.id.trim();
      if (trimmedId.length === 0) {
        addError(sentencesFile, `Blank id at index ${index}`);
        return;
      }
      if (sentenceIds.has(trimmedId)) {
        addError(sentencesFile, `Duplicate sentence ID: "${trimmedId}"`, trimmedId);
      } else {
        sentenceIds.add(trimmedId);
      }
    });
  } else {
    addError(sentencesFile, 'Sentences catalog must be an array');
  }

  // 4. Word / Sentence cross-type collisions
  for (const id of wordIds) {
    if (sentenceIds.has(id)) {
      addError(
        wordsFile,
        `Cross-type ID collision: "${id}" exists in both words and sentences`,
        id
      );
    }
  }

  // 5. Tombstones validation
  const tombstoneIds = new Set();
  const rawTombstones = Array.isArray(manifest.tombstones) ? manifest.tombstones : [];
  rawTombstones.forEach((t, index) => {
    if (!t || typeof t !== 'object') {
      addError(manifestFile, `Tombstone entry at index ${index} is not an object`);
      return;
    }
    if (t.itemType !== 'word' && t.itemType !== 'sentence') {
      addError(
        manifestFile,
        `Invalid tombstone itemType "${t.itemType}" at index ${index}. Must be "word" or "sentence"`,
        t.id
      );
      return;
    }
    if (typeof t.id !== 'string' || t.id.trim().length === 0) {
      addError(manifestFile, `Missing or blank tombstone id at index ${index}`);
      return;
    }
    const id = t.id.trim();
    if (tombstoneIds.has(id)) {
      addError(manifestFile, `Duplicate tombstone ID: "${id}"`, id);
    } else {
      tombstoneIds.add(id);
    }

    if (wordIds.has(id) || sentenceIds.has(id)) {
      addError(
        manifestFile,
        `ID "${id}" is both active in corpus and marked as tombstone`,
        id
      );
    }
  });

  // 6. Aliases validation
  const aliasFromMap = new Map(); // from -> { to, itemType }
  const rawAliases = Array.isArray(manifest.aliases) ? manifest.aliases : [];
  rawAliases.forEach((a, index) => {
    if (!a || typeof a !== 'object') {
      addError(manifestFile, `Alias entry at index ${index} is not an object`);
      return;
    }
    if (a.itemType !== 'word' && a.itemType !== 'sentence') {
      addError(
        manifestFile,
        `Invalid alias itemType "${a.itemType}" at index ${index}. Must be "word" or "sentence"`,
        a.from
      );
      return;
    }
    if (typeof a.from !== 'string' || a.from.trim().length === 0) {
      addError(manifestFile, `Missing or blank alias "from" at index ${index}`);
      return;
    }
    if (typeof a.to !== 'string' || a.to.trim().length === 0) {
      addError(manifestFile, `Missing or blank alias "to" at index ${index}`);
      return;
    }
    const from = a.from.trim();
    const to = a.to.trim();

    if (from === to) {
      addError(
        manifestFile,
        `Malformed alias: "from" and "to" must be different: "${from}"`,
        from
      );
      return;
    }

    if (aliasFromMap.has(from)) {
      const prev = aliasFromMap.get(from);
      if (prev.to === to) {
        addError(manifestFile, `Duplicate alias: "${from}" -> "${to}"`, from);
      } else {
        addError(
          manifestFile,
          `Ambiguous alias: source "${from}" maps to both "${prev.to}" and "${to}"`,
          from
        );
      }
      return;
    }

    if (wordIds.has(from) || sentenceIds.has(from)) {
      addError(
        manifestFile,
        `Aliased source ID "${from}" is still active in the corpus`,
        from
      );
    }

    if (tombstoneIds.has(from)) {
      addError(
        manifestFile,
        `ID "${from}" is both aliased and tombstoned`,
        from
      );
    }

    aliasFromMap.set(from, { to, itemType: a.itemType });
  });

  // 7. Resolve alias chains, check cycles, targets, and type matches
  for (const [startFrom, info] of aliasFromMap.entries()) {
    const visited = new Set([startFrom]);
    let currFrom = startFrom;
    let currTarget = info.to;
    let hasCycle = false;

    while (aliasFromMap.has(currTarget)) {
      if (visited.has(currTarget)) {
        addError(
          manifestFile,
          `Alias cycle detected: chain starting from "${startFrom}" loops back to "${currTarget}"`,
          startFrom
        );
        hasCycle = true;
        break;
      }
      visited.add(currTarget);
      currFrom = currTarget;
      currTarget = aliasFromMap.get(currTarget).to;
    }

    if (hasCycle) continue;

    // currTarget is the final canonical target
    const targetIsWord = wordIds.has(currTarget);
    const targetIsSentence = sentenceIds.has(currTarget);

    if (!targetIsWord && !targetIsSentence) {
      addError(
        manifestFile,
        `Missing alias target: final target "${currTarget}" for alias "${startFrom}" does not exist in active corpus`,
        startFrom
      );
      continue;
    }

    if (info.itemType === 'word' && !targetIsWord) {
      addError(
        manifestFile,
        `Alias type mismatch: alias "${startFrom}" has itemType "word" but target "${currTarget}" is in sentences corpus`,
        startFrom
      );
    } else if (info.itemType === 'sentence' && !targetIsSentence) {
      addError(
        manifestFile,
        `Alias type mismatch: alias "${startFrom}" has itemType "sentence" but target "${currTarget}" is in words corpus`,
        startFrom
      );
    }
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}

export function loadAndValidateCorpus(rootDir = process.cwd()) {
  const wordsPath = path.join(rootDir, 'assets', 'seed', 'words.json');
  const sentencesPath = path.join(rootDir, 'assets', 'seed', 'sentences.json');
  const manifestPath = path.join(
    rootDir,
    'assets',
    'seed',
    'review_item_id_migrations.json'
  );

  let words, sentences, manifest;
  try {
    words = JSON.parse(fs.readFileSync(wordsPath, 'utf8'));
  } catch (e) {
    console.error(`❌ Failed to read words file: ${wordsPath} (${e.message})`);
    return { valid: false, errors: [{ file: wordsPath, message: e.message }] };
  }

  try {
    sentences = JSON.parse(fs.readFileSync(sentencesPath, 'utf8'));
  } catch (e) {
    console.error(`❌ Failed to read sentences file: ${sentencesPath} (${e.message})`);
    return { valid: false, errors: [{ file: sentencesPath, message: e.message }] };
  }

  try {
    manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  } catch (e) {
    console.error(`❌ Failed to read manifest file: ${manifestPath} (${e.message})`);
    return { valid: false, errors: [{ file: manifestPath, message: e.message }] };
  }

  return validateCorpus({
    words,
    sentences,
    manifest,
    fileNames: {
      words: path.relative(rootDir, wordsPath),
      sentences: path.relative(rootDir, sentencesPath),
      manifest: path.relative(rootDir, manifestPath),
    },
  });
}

const __filename = fileURLToPath(import.meta.url);
const isDirectCall = process.argv[1] && path.resolve(process.argv[1]) === path.resolve(__filename);

if (isDirectCall) {
  const result = loadAndValidateCorpus();
  if (!result.valid) {
    console.error(`\n❌ Review Corpus ID Integrity Check FAILED with ${result.errors.length} error(s):\n`);
    for (const err of result.errors) {
      const idPrefix = err.id ? ` [ID: ${err.id}]` : '';
      console.error(`  - [${err.file}]${idPrefix} ${err.message}`);
    }
    console.error('');
    process.exit(1);
  }
  console.log('✅ Review corpus ID integrity verified. All IDs, aliases, and tombstones are consistent.\n');
}
