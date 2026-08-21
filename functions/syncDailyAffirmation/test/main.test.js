import test from 'node:test';
import assert from 'node:assert/strict';

import {
  parseCSV,
  extractLastAffirmationRow,
  generateAffirmationHash,
  parseBody,
  syncAffirmationFromSheet,
} from '../src/main.js';

test('parseCSV handles basic and quoted CSV values correctly', () => {
  const csv = `"olChikiText","santaliPhonetic","englishMeaning","category","audioUrl","isPremium"\r
"ᱫᱤᱱᱟᱹᱢ ᱦᱤᱞᱚᱜ","Dinam hilog","Every day, wisdom","identity","https://example.com/audio.mp3","FALSE"`;

  const rows = parseCSV(csv);
  assert.equal(rows.length, 2);
  assert.equal(rows[0][0], 'olChikiText');
  assert.equal(rows[1][0], 'ᱫᱤᱱᱟᱹᱢ ᱦᱤᱞᱚᱜ');
  assert.equal(rows[1][1], 'Dinam hilog');
  assert.equal(rows[1][2], 'Every day, wisdom');
  assert.equal(rows[1][3], 'identity');
  assert.equal(rows[1][4], 'https://example.com/audio.mp3');
  assert.equal(rows[1][5], 'FALSE');
});

test('parseCSV handles escaped quotes and newlines', () => {
  const csv = `"Col1","Col2"\n"He said ""Hello""","Line1\nLine2"`;
  const rows = parseCSV(csv);
  assert.equal(rows.length, 2);
  assert.equal(rows[1][0], 'He said "Hello"');
  assert.equal(rows[1][1], 'Line1\nLine2');
});

test('extractLastAffirmationRow returns null when only header exists', () => {
  const csv = `"olChikiText","santaliPhonetic","englishMeaning","category","audioUrl","isPremium"\n`;
  const rows = parseCSV(csv);
  const result = extractLastAffirmationRow(rows);
  assert.equal(result, null);
});

test('extractLastAffirmationRow extracts the last non-empty row correctly', () => {
  const csv = `"olChikiText","santaliPhonetic","englishMeaning","category","audioUrl","isPremium"
"ᱥᱟᱹᱜᱩᱱ ᱑","Sagun 1","Greeting 1","identity","","FALSE"
"ᱥᱟᱹᱜᱩᱱ ᱒","Sagun 2","Greeting 2","wealth","https://cdn.example.com/2.mp3","TRUE"
,,,,"",
`;

  const rows = parseCSV(csv);
  const result = extractLastAffirmationRow(rows);
  assert.notEqual(result, null);
  assert.equal(result.olChikiText, 'ᱥᱟᱹᱜᱩᱱ ᱒');
  assert.equal(result.santaliPhonetic, 'Sagun 2');
  assert.equal(result.englishMeaning, 'Greeting 2');
  assert.equal(result.category, 'wealth');
  assert.equal(result.audioUrl, 'https://cdn.example.com/2.mp3');
  assert.equal(result.isPremium, true);
});

test('extractLastAffirmationRow falls back to identity for unknown category', () => {
  const csv = `"olChikiText","santaliPhonetic","englishMeaning","category","audioUrl","isPremium"
"ᱥᱟᱹᱜᱩᱱ","Sagun","Greeting","random_unknown_cat","","no"`;

  const rows = parseCSV(csv);
  const result = extractLastAffirmationRow(rows);
  assert.equal(result.category, 'identity');
  assert.equal(result.isPremium, false);
});

test('generateAffirmationHash generates deterministic hash', () => {
  const data1 = {
    olChikiText: 'ᱥᱟᱹᱜᱩᱱ',
    santaliPhonetic: 'Sagun',
    englishMeaning: 'Greeting',
  };
  const data2 = {
    olChikiText: 'ᱥᱟᱹᱜᱩᱱ',
    santaliPhonetic: 'Sagun',
    englishMeaning: 'Greeting',
  };
  assert.equal(generateAffirmationHash(data1), generateAffirmationHash(data2));
  assert.equal(generateAffirmationHash(data1).length, 32);
});

test('parseBody handles empty, string, and object inputs', () => {
  assert.deepEqual(parseBody(''), {});
  assert.deepEqual(parseBody('invalid json'), {});
  assert.deepEqual(parseBody('{"force":true}'), { force: true });
  assert.deepEqual(parseBody({ force: true }), { force: true });
});

test('syncAffirmationFromSheet skips duplicate insertion if already up to date', async () => {
  const mockDatabases = {
    listDocuments: async (dbId, colId, queries) => {
      return {
        documents: [
          {
            $id: 'existing-doc-1',
            olChikiText: 'ᱥᱟᱹᱜᱩᱱ ᱫᱟᱨᱟᱢ',
            santaliPhonetic: 'Sagun daram',
            englishMeaning: 'Welcome to wisdom',
            order: 5,
            publishedAt: '2026-08-20T10:00:00.000Z',
          },
        ],
      };
    },
    createDocument: async () => {
      throw new Error('Should not be called for duplicate');
    },
  };

  // Mock global fetch for sheet CSV
  const originalFetch = global.fetch;
  global.fetch = async () => ({
    ok: true,
    text: async () =>
      `"olChikiText","santaliPhonetic","englishMeaning","category","audioUrl","isPremium"\n` +
      `"ᱥᱟᱹᱜᱩᱱ ᱫᱟᱨᱟᱢ","Sagun daram","Welcome to wisdom","identity","","FALSE"`,
  });

  try {
    const result = await syncAffirmationFromSheet({
      databases: mockDatabases,
      sheetUrl: 'https://example.com/test.csv',
      force: false,
      log: () => {},
    });

    assert.equal(result.ok, true);
    assert.equal(result.synced, false);
    assert.equal(result.reason, 'already_up_to_date');
    assert.equal(result.documentId, 'existing-doc-1');
  } finally {
    global.fetch = originalFetch;
  }
});
