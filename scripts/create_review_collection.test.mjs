import test from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import { spawn } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SCRIPT_PATH = path.join(__dirname, 'create_review_collection.mjs');

function runScript(env = {}) {
  return new Promise((resolve) => {
    const proc = spawn(process.execPath, [SCRIPT_PATH], {
      env: {
        ...process.env,
        ...env,
      },
    });

    let stdout = '';
    let stderr = '';
    proc.stdout.on('data', (d) => (stdout += d.toString()));
    proc.stderr.on('data', (d) => (stderr += d.toString()));

    proc.on('close', (code) => {
      resolve({ code, stdout, stderr });
    });
  });
}

test('create_review_collection: fails safely when APPWRITE_API_KEY is missing', async () => {
  const result = await runScript({
    APPWRITE_API_KEY: '',
  });
  assert.equal(result.code, 1);
  assert.match(result.stderr, /APPWRITE_API_KEY is required/);
});

test('create_review_collection: creates table, all 7 columns, and 2 indexes idempotently', async () => {
  const createdColumns = [];
  const createdIndexes = [];
  let tableCreated = false;

  const server = http.createServer((req, res) => {
    let bodyStr = '';
    req.on('data', (chunk) => (bodyStr += chunk.toString()));
    req.on('end', () => {
      const body = bodyStr ? JSON.parse(bodyStr) : null;

      if (req.url === '/tablesdb/olitun_db/tables' && req.method === 'POST') {
        tableCreated = true;
        res.writeHead(201, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ $id: 'review_states', name: 'Review States' }));
        return;
      }

      if (req.url === '/tablesdb/olitun_db/tables/review_states' && req.method === 'GET') {
        // Return whatever columns have been created so far, marked available
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(
          JSON.stringify({
            $id: 'review_states',
            columns: createdColumns.map((c) => ({
              key: c.body.key,
              status: 'available',
            })),
          })
        );
        return;
      }

      if (req.url.startsWith('/tablesdb/olitun_db/tables/review_states/columns/') && req.method === 'POST') {
        createdColumns.push({
          type: req.url.split('/').pop(),
          body,
        });
        res.writeHead(202, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ key: body.key, status: 'processing' }));
        return;
      }

      if (req.url === '/tablesdb/olitun_db/tables/review_states/indexes' && req.method === 'POST') {
        createdIndexes.push(body);
        res.writeHead(201, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ key: body.key, status: 'available' }));
        return;
      }

      res.writeHead(404);
      res.end('Not found');
    });
  });

  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  const port = server.address().port;
  const endpoint = `http://127.0.0.1:${port}`;

  try {
    const result = await runScript({
      APPWRITE_ENDPOINT: endpoint,
      APPWRITE_PROJECT_ID: 'test_project',
      APPWRITE_API_KEY: 'test_secret_key',
    });

    assert.equal(result.code, 0, `Script failed with error: ${result.stderr}`);
    assert.ok(tableCreated);
    assert.match(result.stdout, /review_states ready/);

    // Verify all 7 columns created with correct specifications
    const columnKeys = createdColumns.map((c) => c.body.key);
    assert.deepEqual(
      columnKeys.sort(),
      ['itemId', 'itemType', 'lastReviewedAt', 'nextReviewAt', 'schemaVersion', 'stateJson', 'userId'].sort()
    );

    // Verify column attributes
    const userIdCol = createdColumns.find((c) => c.body.key === 'userId');
    assert.equal(userIdCol.type, 'string');
    assert.equal(userIdCol.body.size, 80);
    assert.equal(userIdCol.body.required, true);

    const stateJsonCol = createdColumns.find((c) => c.body.key === 'stateJson');
    assert.equal(stateJsonCol.type, 'string');
    assert.equal(stateJsonCol.body.size, 8192);
    assert.equal(stateJsonCol.body.required, true);

    const itemTypeCol = createdColumns.find((c) => c.body.key === 'itemType');
    assert.equal(itemTypeCol.type, 'enum');
    assert.deepEqual(itemTypeCol.body.elements, ['word', 'sentence']);
    assert.equal(itemTypeCol.body.required, true);

    const nextReviewAtCol = createdColumns.find((c) => c.body.key === 'nextReviewAt');
    assert.equal(nextReviewAtCol.type, 'datetime');
    assert.equal(nextReviewAtCol.body.required, true);

    const lastReviewedAtCol = createdColumns.find((c) => c.body.key === 'lastReviewedAt');
    assert.equal(lastReviewedAtCol.type, 'datetime');
    assert.equal(lastReviewedAtCol.body.required, false);

    const schemaVersionCol = createdColumns.find((c) => c.body.key === 'schemaVersion');
    assert.equal(schemaVersionCol.type, 'integer');
    assert.equal(schemaVersionCol.body.default, 2);
    assert.equal(schemaVersionCol.body.required, false);

    // Verify both indexes
    assert.equal(createdIndexes.length, 2);
    const nextReviewIndex = createdIndexes.find((i) => i.key === 'idx_user_nextReview');
    assert.ok(nextReviewIndex);
    assert.deepEqual(nextReviewIndex.columns, ['userId', 'nextReviewAt']);
    assert.deepEqual(nextReviewIndex.orders, ['ASC', 'ASC']);

    const lastReviewedIndex = createdIndexes.find((i) => i.key === 'idx_user_lastReviewed');
    assert.ok(lastReviewedIndex);
    assert.deepEqual(lastReviewedIndex.columns, ['userId', 'lastReviewedAt']);
    assert.deepEqual(lastReviewedIndex.orders, ['ASC', 'DESC']);
  } finally {
    server.close();
  }
});
