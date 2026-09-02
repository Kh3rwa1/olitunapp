import test from 'node:test';
import assert from 'node:assert/strict';

import {
  parseCSV,
  extractLastAffirmationRow,
  generateAffirmationHash,
  appwriteClient,
  resolveSheetUrl,
  syncAffirmationFromSheet,
  default as handler,
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

test('appwriteClient never trusts request headers for credentials', () => {
  const env = {
    APPWRITE_FUNCTION_API_ENDPOINT: 'https://api.example.test/v1',
    APPWRITE_FUNCTION_PROJECT_ID: 'proj_test',
    APPWRITE_FUNCTION_API_KEY: 'server-key',
  };
  const client = appwriteClient(env);
  assert.equal(client.headers['X-Appwrite-Key'], 'server-key');
  // A request-shaped object is no longer accepted as an argument at all —
  // passing one yields "missing config" instead of honoring its headers.
  assert.throws(
    () => appwriteClient({ headers: { 'x-appwrite-key': 'attacker-supplied-key' } }),
    /Missing Appwrite/,
  );
});

test('appwriteClient throws when endpoint or project id is missing', () => {
  assert.throws(() => appwriteClient({}), /Missing Appwrite/);
});

test('resolveSheetUrl uses the configured Google Sheets URL', () => {
  const url = resolveSheetUrl({ GOOGLE_SHEET_CSV_URL: 'https://docs.google.com/spreadsheets/d/xyz/gviz/tq?tqx=out:csv' });
  assert.ok(url.startsWith('https://docs.google.com/'));
});

test('resolveSheetUrl falls back to the built-in default', () => {
  assert.ok(resolveSheetUrl({}).startsWith('https://docs.google.com/'));
});

test('resolveSheetUrl rejects non-Google and non-HTTPS URLs (SSRF guard)', () => {
  assert.throws(() => resolveSheetUrl({ GOOGLE_SHEET_CSV_URL: 'https://evil.example.com/sheet.csv' }), /Google Sheets host/);
  assert.throws(() => resolveSheetUrl({ GOOGLE_SHEET_CSV_URL: 'http://docs.google.com/sheet.csv' }), /HTTPS/);
  assert.throws(() => resolveSheetUrl({ GOOGLE_SHEET_CSV_URL: 'not a url' }), /valid URL/);
});

function mockRes() {
  const calls = [];
  return {
    calls,
    json(payload, status) {
      calls.push({ payload, status: status || 200 });
      return payload;
    },
  };
}

test('handler ignores client-sent sheetUrl and force in the request body', async () => {
  const fetchCalls = [];
  const originalFetch = global.fetch;
  global.fetch = async (url) => {
    fetchCalls.push(String(url));
    return {
      ok: true,
      text: async () =>
        `"olChikiText","santaliPhonetic","englishMeaning","category","audioUrl","isPremium"\n` +
        `"ᱥᱟᱹᱜᱩᱱ ᱫᱟᱨᱟᱢ","Sagun daram","Welcome to wisdom","identity","","FALSE"`,
    };
  };

  const databases = {
    listDocuments: async () => ({ documents: [] }),
    createDocument: async (dbId, colId, docId, payload) => ({ $id: docId, ...payload }),
  };

  try {
    const res = mockRes();
    await handler({
      req: {
        body: JSON.stringify({
          sheetUrl: 'https://evil.example.com/steal.csv',
          force: true,
        }),
        headers: { 'x-appwrite-key': 'attacker-key' },
      },
      res,
      log: () => {},
      error: () => {},
      databases,
    });

    assert.equal(fetchCalls.length, 1, 'exactly one upstream fetch');
    assert.ok(
      fetchCalls[0].startsWith('https://docs.google.com/'),
      `fetch used the allow-listed sheet, got ${fetchCalls[0]}`,
    );
    assert.equal(res.calls.length, 1);
    assert.equal(res.calls[0].payload.ok, true);
    assert.equal(res.calls[0].payload.synced, true);
  } finally {
    global.fetch = originalFetch;
  }
});

test('handler performs no fetch and returns 500 when the configured sheet URL is not a Google host', async () => {
  const fetchCalls = [];
  const originalFetch = global.fetch;
  const originalSheetUrl = process.env.GOOGLE_SHEET_CSV_URL;
  process.env.GOOGLE_SHEET_CSV_URL = 'https://evil.example.com/x.csv';
  global.fetch = async (url) => {
    fetchCalls.push(String(url));
    return { ok: true, text: async () => 'x' };
  };

  try {
    const res = mockRes();
    await handler({
      req: { body: JSON.stringify({ sheetUrl: 'https://docs.google.com/ok.csv' }), headers: {} },
      res,
      log: () => {},
      error: () => {},
      databases: { listDocuments: async () => ({ documents: [] }), createDocument: async () => ({}) },
    });

    assert.equal(fetchCalls.length, 0, 'no upstream fetch for a non-Google configured URL');
    assert.equal(res.calls[0].status, 500);
    assert.match(res.calls[0].payload.error, /Google Sheets host/);
  } finally {
    global.fetch = originalFetch;
    if (originalSheetUrl === undefined) {
      delete process.env.GOOGLE_SHEET_CSV_URL;
    } else {
      process.env.GOOGLE_SHEET_CSV_URL = originalSheetUrl;
    }
  }
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
