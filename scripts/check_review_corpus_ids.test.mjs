import test from 'node:test';
import assert from 'node:assert/strict';
import { validateCorpus } from './check_review_corpus_ids.mjs';

function baseCorpus() {
  return {
    words: [
      { id: 'w1', wordLatin: 'word1', wordOlChiki: 'ᱚ' },
      { id: 'w2', wordLatin: 'word2', wordOlChiki: 'ᱛ' },
    ],
    sentences: [
      { id: 's1', sentenceLatin: 'sentence1', sentenceOlChiki: 'ᱚ ᱛ' },
      { id: 's2', sentenceLatin: 'sentence2', sentenceOlChiki: 'ᱛ ᱚ' },
    ],
    manifest: {
      schemaVersion: 1,
      aliases: [],
      tombstones: [],
    },
  };
}

test('valid corpus passes without errors', () => {
  const corpus = baseCorpus();
  const res = validateCorpus(corpus);
  assert.equal(res.valid, true);
  assert.equal(res.errors.length, 0);
});

test('fails on missing ID in words', () => {
  const corpus = baseCorpus();
  corpus.words.push({ wordLatin: 'noId' });
  const res = validateCorpus(corpus);
  assert.equal(res.valid, false);
  assert.ok(res.errors.some((e) => e.message.includes('Missing or non-string id')));
});

test('fails on blank ID in words', () => {
  const corpus = baseCorpus();
  corpus.words.push({ id: '   ', wordLatin: 'blank' });
  const res = validateCorpus(corpus);
  assert.equal(res.valid, false);
  assert.ok(res.errors.some((e) => e.message.includes('Blank id')));
});

test('fails on duplicate word IDs', () => {
  const corpus = baseCorpus();
  corpus.words.push({ id: 'w1', wordLatin: 'dup' });
  const res = validateCorpus(corpus);
  assert.equal(res.valid, false);
  assert.ok(res.errors.some((e) => e.message.includes('Duplicate word ID: "w1"')));
});

test('fails on duplicate sentence IDs', () => {
  const corpus = baseCorpus();
  corpus.sentences.push({ id: 's1', sentenceLatin: 'dup' });
  const res = validateCorpus(corpus);
  assert.equal(res.valid, false);
  assert.ok(res.errors.some((e) => e.message.includes('Duplicate sentence ID: "s1"')));
});

test('fails on cross-type ID collisions between words and sentences', () => {
  const corpus = baseCorpus();
  corpus.sentences.push({ id: 'w1', sentenceLatin: 'collision' });
  const res = validateCorpus(corpus);
  assert.equal(res.valid, false);
  assert.ok(res.errors.some((e) => e.message.includes('Cross-type ID collision: "w1"')));
});

test('fails on malformed manifest schema versions', () => {
  const corpus = baseCorpus();
  corpus.manifest.schemaVersion = 2; // only 1 allowed currently
  let res = validateCorpus(corpus);
  assert.equal(res.valid, false);
  assert.ok(res.errors.some((e) => e.message.includes('Invalid schemaVersion')));

  corpus.manifest.schemaVersion = '1';
  res = validateCorpus(corpus);
  assert.equal(res.valid, false);
});

test('fails on malformed aliases (missing fields, from == to, invalid itemType)', () => {
  const corpus = baseCorpus();
  corpus.manifest.aliases.push({ itemType: 'unknown', from: 'old', to: 'w1' });
  let res = validateCorpus(corpus);
  assert.equal(res.valid, false);
  assert.ok(res.errors.some((e) => e.message.includes('Invalid alias itemType')));

  const corpus2 = baseCorpus();
  corpus2.manifest.aliases.push({ itemType: 'word', from: 'same', to: 'same' });
  res = validateCorpus(corpus2);
  assert.equal(res.valid, false);
  assert.ok(res.errors.some((e) => e.message.includes('must be different')));
});

test('fails on duplicate aliases', () => {
  const corpus = baseCorpus();
  corpus.manifest.aliases.push(
    { itemType: 'word', from: 'w_old', to: 'w1' },
    { itemType: 'word', from: 'w_old', to: 'w1' }
  );
  const res = validateCorpus(corpus);
  assert.equal(res.valid, false);
  assert.ok(res.errors.some((e) => e.message.includes('Duplicate alias')));
});

test('fails on ambiguous aliases (same from to multiple targets)', () => {
  const corpus = baseCorpus();
  corpus.manifest.aliases.push(
    { itemType: 'word', from: 'w_old', to: 'w1' },
    { itemType: 'word', from: 'w_old', to: 'w2' }
  );
  const res = validateCorpus(corpus);
  assert.equal(res.valid, false);
  assert.ok(res.errors.some((e) => e.message.includes('Ambiguous alias')));
});

test('fails on alias cycles', () => {
  const corpus = baseCorpus();
  corpus.manifest.aliases.push(
    { itemType: 'word', from: 'a', to: 'b' },
    { itemType: 'word', from: 'b', to: 'c' },
    { itemType: 'word', from: 'c', to: 'a' }
  );
  const res = validateCorpus(corpus);
  assert.equal(res.valid, false);
  assert.ok(res.errors.some((e) => e.message.includes('Alias cycle detected')));
});

test('fails on missing alias targets', () => {
  const corpus = baseCorpus();
  corpus.manifest.aliases.push({ itemType: 'word', from: 'old_w', to: 'non_existent' });
  const res = validateCorpus(corpus);
  assert.equal(res.valid, false);
  assert.ok(res.errors.some((e) => e.message.includes('Missing alias target')));
});

test('fails on alias type mismatches', () => {
  const corpus = baseCorpus();
  // alias declares itemType word, but targets s1 (sentence)
  corpus.manifest.aliases.push({ itemType: 'word', from: 'old_x', to: 's1' });
  const res = validateCorpus(corpus);
  assert.equal(res.valid, false);
  assert.ok(res.errors.some((e) => e.message.includes('Alias type mismatch')));
});

test('fails on duplicate tombstones', () => {
  const corpus = baseCorpus();
  corpus.manifest.tombstones.push(
    { itemType: 'word', id: 'deleted_1' },
    { itemType: 'word', id: 'deleted_1' }
  );
  const res = validateCorpus(corpus);
  assert.equal(res.valid, false);
  assert.ok(res.errors.some((e) => e.message.includes('Duplicate tombstone ID: "deleted_1"')));
});

test('fails when an ID is both active and tombstoned', () => {
  const corpus = baseCorpus();
  corpus.manifest.tombstones.push({ itemType: 'word', id: 'w1' });
  const res = validateCorpus(corpus);
  assert.equal(res.valid, false);
  assert.ok(res.errors.some((e) => e.message.includes('both active in corpus and marked as tombstone')));
});

test('fails when an aliased source ID is still active in corpus', () => {
  const corpus = baseCorpus();
  corpus.manifest.aliases.push({ itemType: 'word', from: 'w2', to: 'w1' });
  const res = validateCorpus(corpus);
  assert.equal(res.valid, false);
  assert.ok(res.errors.some((e) => e.message.includes('Aliased source ID "w2" is still active')));
});

test('supports valid alias chain resolving to active target', () => {
  const corpus = baseCorpus();
  corpus.manifest.aliases.push(
    { itemType: 'word', from: 'step1', to: 'step2' },
    { itemType: 'word', from: 'step2', to: 'w1' }
  );
  const res = validateCorpus(corpus);
  assert.equal(res.valid, true);
  assert.equal(res.errors.length, 0);
});
