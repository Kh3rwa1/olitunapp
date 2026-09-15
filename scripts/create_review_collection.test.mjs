import test from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import { spawn } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SCRIPT_PATH = path.join(__dirname, 'create_review_collection.mjs');

function runScript(args = [], env = {}) {
  return new Promise((resolve) => {
    const proc = spawn(process.execPath, [SCRIPT_PATH, ...args], {
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

async function createMockServer(handler) {
  const server = http.createServer(handler);
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  const port = server.address().port;
  return {
    server,
    endpoint: `http://127.0.0.1:${port}`,
    close: () => new Promise((r) => server.close(r)),
  };
}

function standardTable() {
  return {
    $id: 'review_states',
    name: 'Review States',
    permissions: [],
    rowSecurity: true,
    columns: [
      { key: 'userId', type: 'string', size: 80, required: true, status: 'available' },
      { key: 'itemId', type: 'string', size: 120, required: true, status: 'available' },
      { key: 'itemType', type: 'enum', elements: ['word', 'sentence'], required: true, status: 'available' },
      { key: 'stateJson', type: 'string', size: 8192, required: true, status: 'available' },
      { key: 'nextReviewAt', type: 'datetime', required: true, status: 'available' },
      { key: 'lastReviewedAt', type: 'datetime', required: false, status: 'available' },
      { key: 'schemaVersion', type: 'integer', default: 3, required: false, status: 'available' },
    ],

    indexes: [
      {
        key: 'idx_user_nextReview',
        type: 'key',
        columns: ['userId', 'nextReviewAt'],
        orders: ['ASC', 'ASC'],
        status: 'available',
      },
      {
        key: 'idx_user_lastReviewed',
        type: 'key',
        columns: ['userId', 'lastReviewedAt'],
        orders: ['ASC', 'DESC'],
        status: 'available',
      },
    ],
  };
}

// 1. Missing API key fails safely
test('1. create_review_collection: fails safely when APPWRITE_API_KEY is missing', async () => {
  const result = await runScript(['--apply'], {
    APPWRITE_API_KEY: '',
    APPWRITE_PROJECT_ID: 'test_proj',
  });
  assert.equal(result.code, 1);
  assert.match(result.stderr, /APPWRITE_API_KEY is required/);
});

// 2. Missing project ID fails safely
test('2. create_review_collection: fails safely when APPWRITE_PROJECT_ID is missing', async () => {
  const result = await runScript(['--apply'], {
    APPWRITE_API_KEY: 'test_key',
    APPWRITE_PROJECT_ID: '',
  });
  assert.equal(result.code, 1);
  assert.match(result.stderr, /APPWRITE_PROJECT_ID is required/);
});

// 3. Neither --apply nor --verify-only passed
test('3. create_review_collection: fails safely when neither --apply nor --verify-only is passed', async () => {
  const result = await runScript([], {
    APPWRITE_API_KEY: 'test_key',
    APPWRITE_PROJECT_ID: 'test_proj',
  });
  assert.equal(result.code, 1);
  assert.match(result.stderr, /Either --apply or --verify-only must be specified/);
});

// 4. Both --apply and --verify-only passed
test('4. create_review_collection: fails safely when both --apply and --verify-only are passed', async () => {
  const result = await runScript(['--apply', '--verify-only'], {
    APPWRITE_API_KEY: 'test_key',
    APPWRITE_PROJECT_ID: 'test_proj',
  });
  assert.equal(result.code, 1);
  assert.match(result.stderr, /mutually exclusive/);
});

// 5. Safe summary masks API key
test('5. create_review_collection: safe summary masks API key and prints host/project/db/table/mode', async () => {
  const server = await createMockServer((req, res) => {
    if (req.url === '/tablesdb/olitun_db' && req.method === 'GET') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ $id: 'olitun_db' }));
      return;
    }
    if (req.url === '/tablesdb/olitun_db/tables/review_states' && req.method === 'GET') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(standardTable()));
      return;
    }
    res.writeHead(404);
    res.end();
  });

  try {
    const rawSecret = 'secret_super_confidential_api_token_12345';
    const result = await runScript(['--verify-only'], {
      APPWRITE_ENDPOINT: server.endpoint,
      APPWRITE_PROJECT_ID: 'proj_safe_test',
      APPWRITE_API_KEY: rawSecret,
    });

    assert.equal(result.code, 0);
    assert.doesNotMatch(result.stdout, new RegExp(rawSecret));
    assert.match(result.stdout, /secr\.\.\.2345/);
    assert.match(result.stdout, /Project ID: proj_safe_test/);
    assert.match(result.stdout, /Database:\s+olitun_db/);
    assert.match(result.stdout, /Table:\s+review_states/);
    assert.match(result.stdout, /Mode:\s+VERIFY-ONLY/);
  } finally {
    await server.close();
  }
});

// 6. Fails safely when targeting production without --confirm-prod
test('6. create_review_collection: fails safely when targeting production without --confirm-prod', async () => {
  const result = await runScript(['--apply'], {
    APPWRITE_ENDPOINT: 'https://cloud.appwrite.io/v1',
    APPWRITE_PROJECT_ID: 'prod_proj',
    APPWRITE_API_KEY: 'prod_key',
  });
  assert.equal(result.code, 1);
  assert.match(result.stderr, /Targeting production endpoint requires --confirm-prod flag/);
});

// 7. Fails safely when database does not exist
test('7. create_review_collection: fails safely when database does not exist', async () => {
  const server = await createMockServer((req, res) => {
    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ message: 'Database not found' }));
  });

  try {
    const result = await runScript(['--apply'], {
      APPWRITE_ENDPOINT: server.endpoint,
      APPWRITE_PROJECT_ID: 'test_proj',
      APPWRITE_API_KEY: 'test_key',
    });
    assert.equal(result.code, 1);
    assert.match(result.stderr, /Target database "olitun_db" does not exist/);
  } finally {
    await server.close();
  }
});

// 8. Creates table with empty permissions and rowSecurity: true (function-managed writes)
test('8. create_review_collection: creates table with empty permissions and rowSecurity: true', async () => {
  let tableCreated = null;
  const server = await createMockServer((req, res) => {
    let bodyStr = '';
    req.on('data', (d) => (bodyStr += d));
    req.on('end', () => {
      const body = bodyStr ? JSON.parse(bodyStr) : null;
      if (req.url === '/tablesdb/olitun_db' && req.method === 'GET') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ $id: 'olitun_db' }));
        return;
      }
      if (req.url === '/tablesdb/olitun_db/tables/review_states' && req.method === 'GET') {
        if (!tableCreated) {
          res.writeHead(404);
          res.end();
          return;
        }
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(standardTable()));
        return;
      }
      if (req.url === '/tablesdb/olitun_db/tables' && req.method === 'POST') {
        tableCreated = body;
        res.writeHead(201, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ $id: 'review_states', ...body }));
        return;
      }
      if (req.url.includes('/columns/') && req.method === 'POST') {
        res.writeHead(202, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ key: body.key, status: 'processing' }));
        return;
      }
      if (req.url.endsWith('/indexes') && req.method === 'POST') {
        res.writeHead(201, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ key: body.key, status: 'available' }));
        return;
      }
      res.writeHead(404);
      res.end();
    });
  });

  try {
    const result = await runScript(['--apply'], {
      APPWRITE_ENDPOINT: server.endpoint,
      APPWRITE_PROJECT_ID: 'test_proj',
      APPWRITE_API_KEY: 'test_key',
    });
    assert.equal(result.code, 0, result.stderr);
    assert.ok(tableCreated);
    assert.deepEqual(tableCreated.permissions, []);
    assert.equal(tableCreated.rowSecurity, true);
  } finally {
    await server.close();
  }
});

// 9. Updates table permissions/rowSecurity when drifted in apply mode
test('9. create_review_collection: updates table permissions/rowSecurity when drifted in apply mode', async () => {
  let tableUpdated = null;
  const server = await createMockServer((req, res) => {
    let bodyStr = '';
    req.on('data', (d) => (bodyStr += d));
    req.on('end', () => {
      const body = bodyStr ? JSON.parse(bodyStr) : null;
      if (req.url === '/tablesdb/olitun_db' && req.method === 'GET') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ $id: 'olitun_db' }));
        return;
      }
      if (req.url === '/tablesdb/olitun_db/tables/review_states' && req.method === 'GET') {
        const table = standardTable();
        if (!tableUpdated) {
          table.permissions = ['create("users")']; // Drifted: legacy insecure permission
          table.rowSecurity = false;
        }
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(table));
        return;
      }
      if (req.url === '/tablesdb/olitun_db/tables/review_states' && req.method === 'PUT') {
        tableUpdated = body;
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ $id: 'review_states', ...body }));
        return;
      }
      res.writeHead(404);
      res.end();
    });
  });

  try {
    const result = await runScript(['--apply'], {
      APPWRITE_ENDPOINT: server.endpoint,
      APPWRITE_PROJECT_ID: 'test_proj',
      APPWRITE_API_KEY: 'test_key',
    });
    assert.equal(result.code, 0, result.stderr);
    assert.ok(tableUpdated);
    assert.deepEqual(tableUpdated.permissions, []);
    assert.equal(tableUpdated.rowSecurity, true);
  } finally {
    await server.close();
  }
});

// 10. Creates all 7 columns with exact specifications
test('10. create_review_collection: creates all 7 columns with exact specifications', async () => {
  const columnsCreated = [];
  const server = await createMockServer((req, res) => {
    let bodyStr = '';
    req.on('data', (d) => (bodyStr += d));
    req.on('end', () => {
      const body = bodyStr ? JSON.parse(bodyStr) : null;
      if (req.url === '/tablesdb/olitun_db' && req.method === 'GET') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ $id: 'olitun_db' }));
        return;
      }
      if (req.url === '/tablesdb/olitun_db/tables/review_states' && req.method === 'GET') {
        const table = standardTable();
        if (columnsCreated.length < 7) {
          table.columns = columnsCreated.map((c) => ({
            key: c.body.key,
            type: c.type,
            ...c.body,
            status: 'available',
          }));
        }
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(table));
        return;
      }
      if (req.url.includes('/columns/') && req.method === 'POST') {
        const type = req.url.split('/').pop();
        columnsCreated.push({ type, body });
        res.writeHead(202, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ key: body.key, status: 'processing' }));
        return;
      }
      if (req.url.endsWith('/indexes') && req.method === 'POST') {
        res.writeHead(201, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ key: body.key, status: 'available' }));
        return;
      }
      res.writeHead(404);
      res.end();
    });
  });

  try {
    const result = await runScript(['--apply'], {
      APPWRITE_ENDPOINT: server.endpoint,
      APPWRITE_PROJECT_ID: 'test_proj',
      APPWRITE_API_KEY: 'test_key',
    });
    assert.equal(result.code, 0, result.stderr);
    assert.equal(columnsCreated.length, 7);

    const keys = columnsCreated.map((c) => c.body.key);
    assert.deepEqual(keys, [
      'userId',
      'itemId',
      'itemType',
      'stateJson',
      'nextReviewAt',
      'lastReviewedAt',
      'schemaVersion',
    ]);

    // Check specific columns
    const userId = columnsCreated.find((c) => c.body.key === 'userId');
    assert.equal(userId.type, 'string');
    assert.equal(userId.body.size, 80);
    assert.equal(userId.body.required, true);

    const itemType = columnsCreated.find((c) => c.body.key === 'itemType');
    assert.equal(itemType.type, 'enum');
    assert.deepEqual(itemType.body.elements, ['word', 'sentence']);

    const stateJson = columnsCreated.find((c) => c.body.key === 'stateJson');
    assert.equal(stateJson.type, 'string');
    assert.equal(stateJson.body.size, 8192);

    const schemaVersion = columnsCreated.find((c) => c.body.key === 'schemaVersion');
    assert.equal(schemaVersion.type, 'integer');
    assert.equal(schemaVersion.body.default, 3);
  } finally {

    await server.close();
  }
});

// 11. Skips existing columns idempotently without error
test('11. create_review_collection: skips existing columns idempotently without error', async () => {
  const columnsCreated = [];
  const server = await createMockServer((req, res) => {
    let bodyStr = '';
    req.on('data', (d) => (bodyStr += d));
    req.on('end', () => {
      const body = bodyStr ? JSON.parse(bodyStr) : null;
      if (req.url === '/tablesdb/olitun_db' && req.method === 'GET') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ $id: 'olitun_db' }));
        return;
      }
      if (req.url === '/tablesdb/olitun_db/tables/review_states' && req.method === 'GET') {
        const table = standardTable();
        // Initially only userId exists
        if (columnsCreated.length === 0) {
          table.columns = [
            { key: 'userId', type: 'string', size: 80, required: true, status: 'available' },
          ];
        }
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(table));
        return;
      }
      if (req.url.includes('/columns/') && req.method === 'POST') {
        columnsCreated.push(body.key);
        res.writeHead(202, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ key: body.key, status: 'processing' }));
        return;
      }
      res.writeHead(404);
      res.end();
    });
  });

  try {
    const result = await runScript(['--apply'], {
      APPWRITE_ENDPOINT: server.endpoint,
      APPWRITE_PROJECT_ID: 'test_proj',
      APPWRITE_API_KEY: 'test_key',
    });
    assert.equal(result.code, 0, result.stderr);
    assert.equal(columnsCreated.includes('userId'), false);
    assert.equal(columnsCreated.length, 6);
  } finally {
    await server.close();
  }
});

// 12. Bounded polling waits for processing columns and succeeds when available
test('12. create_review_collection: bounded polling waits for processing columns and succeeds when available', async () => {
  let getCount = 0;
  const server = await createMockServer((req, res) => {
    if (req.url === '/tablesdb/olitun_db' && req.method === 'GET') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ $id: 'olitun_db' }));
      return;
    }
    if (req.url === '/tablesdb/olitun_db/tables/review_states' && req.method === 'GET') {
      getCount++;
      const table = standardTable();
      if (getCount <= 2) {
        // First 2 calls: processing
        table.columns[0].status = 'processing';
      }
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(table));
      return;
    }
    res.writeHead(404);
    res.end();
  });

  try {
    const result = await runScript(['--apply'], {
      APPWRITE_ENDPOINT: server.endpoint,
      APPWRITE_PROJECT_ID: 'test_proj',
      APPWRITE_API_KEY: 'test_key',
      POLL_INTERVAL_MS: '50',
    });
    assert.equal(result.code, 0, result.stderr);
    assert.ok(getCount >= 3);
  } finally {
    await server.close();
  }
});

// 13. Bounded polling times out safely when columns stay processing
test('13. create_review_collection: bounded polling times out safely when columns stay processing', async () => {
  const server = await createMockServer((req, res) => {
    if (req.url === '/tablesdb/olitun_db' && req.method === 'GET') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ $id: 'olitun_db' }));
      return;
    }
    if (req.url === '/tablesdb/olitun_db/tables/review_states' && req.method === 'GET') {
      const table = standardTable();
      table.columns[0].status = 'processing'; // always processing
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(table));
      return;
    }
    res.writeHead(404);
    res.end();
  });

  try {
    const result = await runScript(['--apply'], {
      APPWRITE_ENDPOINT: server.endpoint,
      APPWRITE_PROJECT_ID: 'test_proj',
      APPWRITE_API_KEY: 'test_key',
      POLL_TIMEOUT_MS: '150',
      POLL_INTERVAL_MS: '50',
    });
    assert.equal(result.code, 1);
    assert.match(result.stderr, /Columns did not become available within timeout/);
  } finally {
    await server.close();
  }
});

// 14. Creates both indexes with exact columns and orders
test('14. create_review_collection: creates both indexes with exact columns and orders', async () => {
  const indexesCreated = [];
  const server = await createMockServer((req, res) => {
    let bodyStr = '';
    req.on('data', (d) => (bodyStr += d));
    req.on('end', () => {
      const body = bodyStr ? JSON.parse(bodyStr) : null;
      if (req.url === '/tablesdb/olitun_db' && req.method === 'GET') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ $id: 'olitun_db' }));
        return;
      }
      if (req.url === '/tablesdb/olitun_db/tables/review_states' && req.method === 'GET') {
        const table = standardTable();
        table.indexes = indexesCreated.map((i) => ({ ...i, status: 'available' }));
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(table));
        return;
      }
      if (req.url.endsWith('/indexes') && req.method === 'POST') {
        indexesCreated.push(body);
        res.writeHead(201, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ key: body.key, status: 'available' }));
        return;
      }
      res.writeHead(404);
      res.end();
    });
  });

  try {
    const result = await runScript(['--apply'], {
      APPWRITE_ENDPOINT: server.endpoint,
      APPWRITE_PROJECT_ID: 'test_proj',
      APPWRITE_API_KEY: 'test_key',
    });
    assert.equal(result.code, 0, result.stderr);
    assert.equal(indexesCreated.length, 2);

    const idx1 = indexesCreated.find((i) => i.key === 'idx_user_nextReview');
    assert.deepEqual(idx1.columns, ['userId', 'nextReviewAt']);
    assert.deepEqual(idx1.orders, ['ASC', 'ASC']);

    const idx2 = indexesCreated.find((i) => i.key === 'idx_user_lastReviewed');
    assert.deepEqual(idx2.columns, ['userId', 'lastReviewedAt']);
    assert.deepEqual(idx2.orders, ['ASC', 'DESC']);
  } finally {
    await server.close();
  }
});

// 15. Skips existing indexes idempotently without error
test('15. create_review_collection: skips existing indexes idempotently without error', async () => {
  const indexesCreated = [];
  const server = await createMockServer((req, res) => {
    let bodyStr = '';
    req.on('data', (d) => (bodyStr += d));
    req.on('end', () => {
      const body = bodyStr ? JSON.parse(bodyStr) : null;
      if (req.url === '/tablesdb/olitun_db' && req.method === 'GET') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ $id: 'olitun_db' }));
        return;
      }
      if (req.url === '/tablesdb/olitun_db/tables/review_states' && req.method === 'GET') {
        const table = standardTable();
        // idx_user_nextReview already exists; once idx_user_lastReviewed is created, return both
        if (indexesCreated.length === 0) {
          table.indexes = [table.indexes[0]];
        }
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(table));
        return;
      }
      if (req.url.endsWith('/indexes') && req.method === 'POST') {
        indexesCreated.push(body.key);
        res.writeHead(201, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ key: body.key, status: 'available' }));
        return;
      }
      res.writeHead(404);
      res.end();
    });
  });

  try {
    const result = await runScript(['--apply'], {
      APPWRITE_ENDPOINT: server.endpoint,
      APPWRITE_PROJECT_ID: 'test_proj',
      APPWRITE_API_KEY: 'test_key',
    });
    assert.equal(result.code, 0, result.stderr);
    assert.equal(indexesCreated.length, 1);
    assert.equal(indexesCreated[0], 'idx_user_lastReviewed');
  } finally {
    await server.close();
  }
});

// 16. --verify-only issues zero mutating HTTP requests (only GET)
test('16. create_review_collection: --verify-only issues zero mutating HTTP requests (only GET)', async () => {
  const methods = [];
  const server = await createMockServer((req, res) => {
    methods.push(req.method);
    if (req.url === '/tablesdb/olitun_db' && req.method === 'GET') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ $id: 'olitun_db' }));
      return;
    }
    if (req.url === '/tablesdb/olitun_db/tables/review_states' && req.method === 'GET') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(standardTable()));
      return;
    }
    res.writeHead(404);
    res.end();
  });

  try {
    const result = await runScript(['--verify-only'], {
      APPWRITE_ENDPOINT: server.endpoint,
      APPWRITE_PROJECT_ID: 'test_proj',
      APPWRITE_API_KEY: 'test_key',
    });
    assert.equal(result.code, 0, result.stderr);
    assert.ok(methods.length > 0);
    assert.ok(methods.every((m) => m === 'GET'), `Found non-GET methods: ${methods}`);
  } finally {
    await server.close();
  }
});

// 17. --verify-only passes with exit code 0 when remote schema matches 100%
test('17. create_review_collection: --verify-only passes with exit code 0 when remote schema matches 100%', async () => {
  const server = await createMockServer((req, res) => {
    if (req.url === '/tablesdb/olitun_db' && req.method === 'GET') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ $id: 'olitun_db' }));
      return;
    }
    if (req.url === '/tablesdb/olitun_db/tables/review_states' && req.method === 'GET') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(standardTable()));
      return;
    }
    res.writeHead(404);
    res.end();
  });

  try {
    const result = await runScript(['--verify-only'], {
      APPWRITE_ENDPOINT: server.endpoint,
      APPWRITE_PROJECT_ID: 'test_proj',
      APPWRITE_API_KEY: 'test_key',
    });
    assert.equal(result.code, 0, result.stderr);
    assert.match(result.stdout, /matches expected specification exactly \(0 drift\)/);
  } finally {
    await server.close();
  }
});

// 18. --verify-only detects missing table and exits with non-zero code
test('18. create_review_collection: --verify-only detects missing table and exits with non-zero code', async () => {
  const server = await createMockServer((req, res) => {
    if (req.url === '/tablesdb/olitun_db' && req.method === 'GET') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ $id: 'olitun_db' }));
      return;
    }
    res.writeHead(404);
    res.end();
  });

  try {
    const result = await runScript(['--verify-only'], {
      APPWRITE_ENDPOINT: server.endpoint,
      APPWRITE_PROJECT_ID: 'test_proj',
      APPWRITE_API_KEY: 'test_key',
    });
    assert.equal(result.code, 1);
    assert.match(result.stderr, /Table "review_states" does not exist/);
  } finally {
    await server.close();
  }
});

// 19. --verify-only detects missing column and exits with non-zero code
test('19. create_review_collection: --verify-only detects missing column and exits with non-zero code', async () => {
  const server = await createMockServer((req, res) => {
    if (req.url === '/tablesdb/olitun_db' && req.method === 'GET') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ $id: 'olitun_db' }));
      return;
    }
    if (req.url === '/tablesdb/olitun_db/tables/review_states' && req.method === 'GET') {
      const table = standardTable();
      table.columns = table.columns.filter((c) => c.key !== 'stateJson');
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(table));
      return;
    }
    res.writeHead(404);
    res.end();
  });

  try {
    const result = await runScript(['--verify-only'], {
      APPWRITE_ENDPOINT: server.endpoint,
      APPWRITE_PROJECT_ID: 'test_proj',
      APPWRITE_API_KEY: 'test_key',
    });
    assert.equal(result.code, 1);
    assert.match(result.stderr, /Missing column: "stateJson"/);
  } finally {
    await server.close();
  }
});

// 20. --verify-only detects column attribute drift and exits with non-zero code
test('20. create_review_collection: --verify-only detects column attribute drift and exits with non-zero code', async () => {
  const server = await createMockServer((req, res) => {
    if (req.url === '/tablesdb/olitun_db' && req.method === 'GET') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ $id: 'olitun_db' }));
      return;
    }
    if (req.url === '/tablesdb/olitun_db/tables/review_states' && req.method === 'GET') {
      const table = standardTable();
      const userIdCol = table.columns.find((c) => c.key === 'userId');
      userIdCol.size = 50; // Drifted from 80
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(table));
      return;
    }
    res.writeHead(404);
    res.end();
  });

  try {
    const result = await runScript(['--verify-only'], {
      APPWRITE_ENDPOINT: server.endpoint,
      APPWRITE_PROJECT_ID: 'test_proj',
      APPWRITE_API_KEY: 'test_key',
    });
    assert.equal(result.code, 1);
    assert.match(result.stderr, /size drift: expected 80, got 50/);
  } finally {
    await server.close();
  }
});

// 21. --verify-only detects missing index and exits with non-zero code
test('21. create_review_collection: --verify-only detects missing index and exits with non-zero code', async () => {
  const server = await createMockServer((req, res) => {
    if (req.url === '/tablesdb/olitun_db' && req.method === 'GET') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ $id: 'olitun_db' }));
      return;
    }
    if (req.url === '/tablesdb/olitun_db/tables/review_states' && req.method === 'GET') {
      const table = standardTable();
      table.indexes = table.indexes.filter((i) => i.key !== 'idx_user_lastReviewed');
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(table));
      return;
    }
    res.writeHead(404);
    res.end();
  });

  try {
    const result = await runScript(['--verify-only'], {
      APPWRITE_ENDPOINT: server.endpoint,
      APPWRITE_PROJECT_ID: 'test_proj',
      APPWRITE_API_KEY: 'test_key',
    });
    assert.equal(result.code, 1);
    assert.match(result.stderr, /Missing index: "idx_user_lastReviewed"/);
  } finally {
    await server.close();
  }
});

// 22. --verify-only detects permission or rowSecurity drift and exits with non-zero code
test('22. create_review_collection: --verify-only detects permission or rowSecurity drift and exits with non-zero code', async () => {
  const server = await createMockServer((req, res) => {
    if (req.url === '/tablesdb/olitun_db' && req.method === 'GET') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ $id: 'olitun_db' }));
      return;
    }
    if (req.url === '/tablesdb/olitun_db/tables/review_states' && req.method === 'GET') {
      const table = standardTable();
      table.rowSecurity = false; // Drifted
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(table));
      return;
    }
    res.writeHead(404);
    res.end();
  });

  try {
    const result = await runScript(['--verify-only'], {
      APPWRITE_ENDPOINT: server.endpoint,
      APPWRITE_PROJECT_ID: 'test_proj',
      APPWRITE_API_KEY: 'test_key',
    });
    assert.equal(result.code, 1);
    assert.match(result.stderr, /Table rowSecurity drift: expected true, got false/);
  } finally {
    await server.close();
  }
});
