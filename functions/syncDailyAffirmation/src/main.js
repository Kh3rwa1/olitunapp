import { createHash, randomUUID } from 'crypto';
import { Client, Databases, ID, Query } from 'node-appwrite';

export const DATABASE_ID =
  process.env.APPWRITE_DATABASE_ID ||
  process.env.OLITUN_APPWRITE_DATABASE_ID ||
  'olitun_db';
export const AFFIRMATIONS_COLLECTION = 'daily_affirmations';
export const DEFAULT_SHEET_CSV_URL =
  'https://docs.google.com/spreadsheets/d/1zJXlcPzXtWxHyvpifqnA832HR2L5DCTX8RmnfypBxOk/gviz/tq?tqx=out:csv';

const ALLOWED_CATEGORIES = new Set(['identity', 'habit', 'wealth', 'culture']);

/**
 * Parse CSV text conforming to RFC 4180.
 * Handles quotes, escaped quotes (""), commas within quotes, and multi-line rows.
 */
export function parseCSV(csvText) {
  if (!csvText || typeof csvText !== 'string') return [];

  const rows = [];
  let currentRow = [];
  let currentCell = '';
  let inQuotes = false;
  let i = 0;

  while (i < csvText.length) {
    const char = csvText[i];
    const nextChar = csvText[i + 1];

    if (inQuotes) {
      if (char === '"' && nextChar === '"') {
        currentCell += '"';
        i += 2;
        continue;
      } else if (char === '"') {
        inQuotes = false;
        i++;
        continue;
      } else {
        currentCell += char;
        i++;
        continue;
      }
    } else {
      if (char === '"') {
        inQuotes = true;
        i++;
        continue;
      } else if (char === ',') {
        currentRow.push(currentCell.trim());
        currentCell = '';
        i++;
        continue;
      } else if (char === '\r' && nextChar === '\n') {
        currentRow.push(currentCell.trim());
        currentCell = '';
        rows.push(currentRow);
        currentRow = [];
        i += 2;
        continue;
      } else if (char === '\n' || char === '\r') {
        currentRow.push(currentCell.trim());
        currentCell = '';
        rows.push(currentRow);
        currentRow = [];
        i++;
        continue;
      } else {
        currentCell += char;
        i++;
        continue;
      }
    }
  }

  if (currentCell.length > 0 || currentRow.length > 0) {
    currentRow.push(currentCell.trim());
    rows.push(currentRow);
  }

  return rows;
}

/**
 * Extract the last valid affirmation row from parsed CSV rows.
 */
export function extractLastAffirmationRow(rows) {
  if (!rows || rows.length <= 1) return null;

  const headerRow = rows[0].map((h) => String(h || '').trim().toLowerCase());
  const headerMap = {};
  headerRow.forEach((col, idx) => {
    if (col.includes('olchiki') || col.includes('ol_chiki')) headerMap.olChikiText = idx;
    else if (col.includes('phonetic') || col.includes('santali')) headerMap.santaliPhonetic = idx;
    else if (col.includes('meaning') || col.includes('english')) headerMap.englishMeaning = idx;
    else if (col.includes('category')) headerMap.category = idx;
    else if (col.includes('audio')) headerMap.audioUrl = idx;
    else if (col.includes('premium')) headerMap.isPremium = idx;
  });

  // Default fallback column positions if headers were not named standardly
  const olChikiIdx = headerMap.olChikiText ?? 0;
  const phoneticIdx = headerMap.santaliPhonetic ?? 1;
  const meaningIdx = headerMap.englishMeaning ?? 2;
  const categoryIdx = headerMap.category ?? 3;
  const audioIdx = headerMap.audioUrl ?? 4;
  const premiumIdx = headerMap.isPremium ?? 5;

  // Scan backwards for the last row with non-empty required fields
  for (let r = rows.length - 1; r >= 1; r--) {
    const row = rows[r];
    if (!row || row.length === 0) continue;

    const olChikiText = (row[olChikiIdx] || '').trim();
    const santaliPhonetic = (row[phoneticIdx] || '').trim();
    const englishMeaning = (row[meaningIdx] || '').trim();

    if (olChikiText && santaliPhonetic && englishMeaning) {
      let category = (row[categoryIdx] || 'identity').trim().toLowerCase();
      if (!ALLOWED_CATEGORIES.has(category)) {
        category = 'identity';
      }

      const audioUrl = (row[audioIdx] || '').trim() || null;
      const premiumRaw = (row[premiumIdx] || '').trim().toLowerCase();
      const isPremium = premiumRaw === 'true' || premiumRaw === '1' || premiumRaw === 'yes';

      return {
        olChikiText: olChikiText.slice(0, 500),
        santaliPhonetic: santaliPhonetic.slice(0, 500),
        englishMeaning: englishMeaning.slice(0, 500),
        category,
        audioUrl: audioUrl ? audioUrl.slice(0, 1024) : null,
        isPremium,
      };
    }
  }

  return null;
}

export function generateAffirmationHash(data) {
  const content = `${data.olChikiText}|${data.santaliPhonetic}|${data.englishMeaning}`.trim();
  return createHash('sha256').update(content).digest('hex').slice(0, 32);
}

export function parseBody(body) {
  if (!body) return {};
  if (typeof body === 'object') return body;
  try {
    return JSON.parse(body);
  } catch (_) {
    return {};
  }
}

export function appwriteClient(env = process.env) {
  const endpoint =
    env.APPWRITE_FUNCTION_API_ENDPOINT ||
    env.APPWRITE_ENDPOINT ||
    env.OLITUN_APPWRITE_ENDPOINT;
  const projectId =
    env.APPWRITE_FUNCTION_PROJECT_ID ||
    env.APPWRITE_PROJECT_ID ||
    env.OLITUN_APPWRITE_PROJECT_ID;
  const apiKey =
    env.APPWRITE_FUNCTION_API_KEY ||
    env.APPWRITE_API_KEY ||
    env.OLITUN_APPWRITE_API_KEY;

  if (!endpoint || !projectId || !apiKey) {
    throw new Error('Missing Appwrite endpoint, project ID, or API key.');
  }

  return new Client().setEndpoint(endpoint).setProject(projectId).setKey(apiKey);
}

/**
 * Fetch and sync the latest affirmation from Google Sheet into Appwrite.
 */
export async function syncAffirmationFromSheet({
  databases,
  sheetUrl = process.env.GOOGLE_SHEET_CSV_URL || DEFAULT_SHEET_CSV_URL,
  force = false,
  log = console.log,
}) {
  log(`Fetching Google Sheet CSV from: ${sheetUrl}`);
  const response = await fetch(sheetUrl);
  if (!response.ok) {
    throw new Error(`Failed to fetch Google Sheet CSV: HTTP ${response.status} ${response.statusText}`);
  }

  const csvText = await response.text();
  const rows = parseCSV(csvText);
  const latestAffirmation = extractLastAffirmationRow(rows);

  if (!latestAffirmation) {
    log('No valid affirmation rows found in the Google Sheet.');
    return {
      ok: true,
      synced: false,
      reason: 'no_rows_found',
    };
  }

  const affirmationHash = generateAffirmationHash(latestAffirmation);

  // Check if this affirmation matches the most recent record or already exists
  const existingDocs = await databases.listDocuments(DATABASE_ID, AFFIRMATIONS_COLLECTION, [
    Query.orderDesc('publishedAt'),
    Query.limit(5),
  ]);

  if (!force && existingDocs.documents.length > 0) {
    const mostRecent = existingDocs.documents[0];
    const mostRecentHash = generateAffirmationHash(mostRecent);
    if (mostRecentHash === affirmationHash) {
      log(`Affirmation is already up to date (Hash: ${affirmationHash}). Skipping duplicate creation.`);
      return {
        ok: true,
        synced: false,
        reason: 'already_up_to_date',
        documentId: mostRecent.$id,
        affirmation: latestAffirmation,
      };
    }
  }

  // Calculate highest order
  let nextOrder = 1;
  if (existingDocs.documents.length > 0) {
    const maxOrderDoc = await databases.listDocuments(DATABASE_ID, AFFIRMATIONS_COLLECTION, [
      Query.orderDesc('order'),
      Query.limit(1),
    ]);
    if (maxOrderDoc.documents.length > 0) {
      nextOrder = (maxOrderDoc.documents[0].order || 0) + 1;
    }
  }

  const newDocId = randomUUID().replace(/-/g, '').slice(0, 32);
  const nowIso = new Date().toISOString();

  const docPayload = {
    olChikiText: latestAffirmation.olChikiText,
    santaliPhonetic: latestAffirmation.santaliPhonetic,
    englishMeaning: latestAffirmation.englishMeaning,
    category: latestAffirmation.category,
    audioUrl: latestAffirmation.audioUrl,
    isPremium: latestAffirmation.isPremium,
    order: nextOrder,
    publishedAt: nowIso,
  };

  const createdDoc = await databases.createDocument(
    DATABASE_ID,
    AFFIRMATIONS_COLLECTION,
    newDocId,
    docPayload,
  );

  log(`Successfully synced new affirmation "${latestAffirmation.santaliPhonetic}" (Doc ID: ${createdDoc.$id}, Order: ${nextOrder}).`);

  return {
    ok: true,
    synced: true,
    documentId: createdDoc.$id,
    order: nextOrder,
    publishedAt: nowIso,
    affirmation: docPayload,
  };
}

export default async ({ req, res, log, error }) => {
  try {
    const body = parseBody(req.body);
    const sheetUrl = body.sheetUrl || process.env.GOOGLE_SHEET_CSV_URL || DEFAULT_SHEET_CSV_URL;
    const force = Boolean(body.force);

    const client = appwriteClient();
    const databases = new Databases(client);

    const result = await syncAffirmationFromSheet({
      databases,
      sheetUrl,
      force,
      log: log || console.log,
    });

    return res.json(result);
  } catch (err) {
    const message = err?.message || String(err);
    if (error) error(`Google Sheet Affirmation Sync Error: ${message}`);
    return res.json(
      {
        ok: false,
        error: message,
      },
      500,
    );
  }
};
