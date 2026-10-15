#!/usr/bin/env node
// Copy every Appwrite Storage file into R2 at `<bucketId>/<fileId>`.
//
// The Worker serves public media from R2 at /api/v1/assets/<bucket>/<fileId>
// and paid media (paid_media/<fileId>) through signed URLs. Until a file is
// copied, /api/v1/assets redirects to Appwrite Storage; after this script has
// run, everything is served from R2.
//
// USAGE (from cloudflare/backend):
//   node scripts/copy_appwrite_storage_to_r2.mjs ~/.appwrite/olitun_deploy_key --dry-run
//   node scripts/copy_appwrite_storage_to_r2.mjs ~/.appwrite/olitun_deploy_key
//
// The first argument is a file containing an Appwrite server API key with
// buckets.read + files.read. It is read from disk and never printed.
//
// Options:
//   --dry-run              List and check only; download/write nothing.
//   --buckets a,b          Only these Appwrite buckets (default: every bucket
//                          the Worker knows: audio, images, animations, avatars,
//                          videos, cover_videos, html, paid_media).
//   --endpoint URL         Appwrite API (default https://sgp.cloud.appwrite.io/v1)
//   --project ID           Appwrite project (default 699495910038e39622c5)
//   --r2-bucket NAME       R2 bucket (default olitun-assets)
//   --worker-url URL       Worker origin used to detect already-copied public
//                          files (default https://olitun-api.dulalkisku0.workers.dev)
//   --state FILE           Local record of copied keys
//                          (default ./.r2-copy-state.json)
//   --concurrency N        Parallel copies (default 4)
//
// Writing to R2: with R2_ACCOUNT_ID, R2_ACCESS_KEY_ID and R2_SECRET_ACCESS_KEY
// set (an R2 API token for olitun-assets), the S3 API is used for both the
// existence check (HEAD) and the upload (PUT). Otherwise each file is written
// with `npx wrangler r2 object put <r2-bucket>/<key> --remote --file ...
// --content-type ...` (needs `wrangler login`), and existence is decided from
// the state file plus a HEAD to the Worker's public asset route (200 = in R2;
// paid_media is not public, so it relies on the state file).
//
// Idempotent: existing objects are skipped, so it is safe to re-run after a
// failure. Content-Type is taken from Appwrite's mimeType. Exit code 1 if any
// file failed.

import { createHash, createHmac } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { homedir, tmpdir } from 'node:os';
import { join, resolve } from 'node:path';

const KNOWN_BUCKETS = ['audio', 'images', 'animations', 'avatars', 'videos', 'cover_videos', 'html', 'paid_media', 'profile_avatars'];

// The avatar catalogue (GET /api/v1/avatars) lists R2 `avatars/<file name>`
// and derives ids/labels from the Lottie file name, so the Appwrite
// `profile_avatars` bucket is stored by name under that prefix.
function r2KeyFor(bucketId, file) {
  if (bucketId === 'profile_avatars') {
    return `avatars/${String(file.name || file.$id).replace(/[\\/]/g, '_')}`;
  }
  return `${bucketId}/${file.$id}`;
}
const PRIVATE_BUCKETS = new Set(['paid_media']);
const PAGE_SIZE = 100;

function parseArgs(argv) {
  const opts = {
    keyFile: '',
    dryRun: false,
    buckets: null,
    endpoint: 'https://sgp.cloud.appwrite.io/v1',
    project: '699495910038e39622c5',
    r2Bucket: 'olitun-assets',
    workerUrl: 'https://olitun-api.dulalkisku0.workers.dev',
    state: './.r2-copy-state.json',
    concurrency: 4,
  };
  const rest = [...argv];
  while (rest.length) {
    const arg = rest.shift();
    const value = () => {
      const v = rest.shift();
      if (v === undefined) throw new Error(`${arg} needs a value`);
      return v;
    };
    if (arg === '--dry-run') opts.dryRun = true;
    else if (arg === '--buckets') opts.buckets = value().split(',').map((s) => s.trim()).filter(Boolean);
    else if (arg === '--endpoint') opts.endpoint = value().replace(/\/+$/, '');
    else if (arg === '--project') opts.project = value();
    else if (arg === '--r2-bucket') opts.r2Bucket = value();
    else if (arg === '--worker-url') opts.workerUrl = value().replace(/\/+$/, '');
    else if (arg === '--state') opts.state = value();
    else if (arg === '--concurrency') opts.concurrency = Math.max(1, Number(value()) || 1);
    else if (arg === '-h' || arg === '--help') {
      console.log(readFileSync(new URL(import.meta.url), 'utf8').split('\n').filter((l) => l.startsWith('//')).join('\n'));
      process.exit(0);
    } else if (arg.startsWith('--')) throw new Error(`Unknown option ${arg}`);
    else if (!opts.keyFile) opts.keyFile = arg;
    else throw new Error(`Unexpected argument ${arg}`);
  }
  if (!opts.keyFile) throw new Error('Usage: copy_appwrite_storage_to_r2.mjs <appwrite-key-file> [--dry-run] [options]');
  return opts;
}

// ---------------- Appwrite Storage REST ----------------

function appwrite(opts, key) {
  const headers = { 'X-Appwrite-Project': opts.project, 'X-Appwrite-Key': key };
  async function getJson(path, queries = []) {
    const url = new URL(`${opts.endpoint}${path}`);
    for (const q of queries) url.searchParams.append('queries[]', JSON.stringify(q));
    const res = await fetch(url, { headers });
    if (!res.ok) throw new Error(`Appwrite ${path} -> HTTP ${res.status}: ${(await res.text()).slice(0, 200)}`);
    return res.json();
  }
  async function* paginate(path, field) {
    let cursor = null;
    for (;;) {
      const queries = [{ method: 'limit', values: [PAGE_SIZE] }];
      if (cursor) queries.push({ method: 'cursorAfter', values: [cursor] });
      const page = await getJson(path, queries);
      const items = page[field] || [];
      for (const item of items) yield item;
      if (items.length < PAGE_SIZE) return;
      cursor = items[items.length - 1].$id;
    }
  }
  return {
    buckets: () => paginate('/storage/buckets', 'buckets'),
    files: (bucketId) => paginate(`/storage/buckets/${encodeURIComponent(bucketId)}/files`, 'files'),
    async download(bucketId, fileId) {
      const res = await fetch(
        `${opts.endpoint}/storage/buckets/${encodeURIComponent(bucketId)}/files/${encodeURIComponent(fileId)}/download`,
        { headers },
      );
      if (!res.ok) throw new Error(`download ${bucketId}/${fileId} -> HTTP ${res.status}`);
      return Buffer.from(await res.arrayBuffer());
    },
  };
}

// ---------------- R2 (S3 API, SigV4) ----------------

function s3Client(env, bucket) {
  const { R2_ACCOUNT_ID: account, R2_ACCESS_KEY_ID: accessKey, R2_SECRET_ACCESS_KEY: secret } = env;
  if (!account || !accessKey || !secret) return null;
  const host = `${account}.r2.cloudflarestorage.com`;
  const sha256 = (data) => createHash('sha256').update(data).digest('hex');
  const hmac = (k, data) => createHmac('sha256', k).update(data).digest();
  const encodeKey = (key) => key.split('/').map(encodeURIComponent).join('/');

  async function send(method, key, body, contentType) {
    const now = new Date();
    const amzDate = now.toISOString().replace(/[-:]/g, '').replace(/\.\d{3}/, '');
    const day = amzDate.slice(0, 8);
    const path = `/${bucket}/${encodeKey(key)}`;
    const payloadHash = body ? sha256(body) : sha256('');
    const headers = { host, 'x-amz-content-sha256': payloadHash, 'x-amz-date': amzDate };
    if (contentType) headers['content-type'] = contentType;
    const names = Object.keys(headers).sort();
    const canonical = [method, path, '', ...names.map((n) => `${n}:${headers[n]}`), '', names.join(';'), payloadHash].join('\n');
    const scope = `${day}/auto/s3/aws4_request`;
    const toSign = ['AWS4-HMAC-SHA256', amzDate, scope, sha256(canonical)].join('\n');
    const signingKey = hmac(hmac(hmac(hmac(`AWS4${secret}`, day), 'auto'), 's3'), 'aws4_request');
    const signature = createHmac('sha256', signingKey).update(toSign).digest('hex');
    headers.authorization = `AWS4-HMAC-SHA256 Credential=${accessKey}/${scope}, SignedHeaders=${names.join(';')}, Signature=${signature}`;
    delete headers.host;
    return fetch(`https://${host}${path}`, { method, headers, body });
  }

  return {
    async exists(key) {
      const res = await send('HEAD', key);
      if (res.status === 404) return false;
      if (res.ok) return true;
      throw new Error(`R2 HEAD ${key} -> HTTP ${res.status}`);
    },
    async put(key, body, contentType) {
      const res = await send('PUT', key, body, contentType);
      if (!res.ok) throw new Error(`R2 PUT ${key} -> HTTP ${res.status}: ${(await res.text()).slice(0, 200)}`);
    },
  };
}

function wranglerWriter(r2Bucket) {
  const dir = mkdtempSync(join(tmpdir(), 'olitun-r2-copy-'));
  let n = 0;
  return {
    async put(key, body, contentType) {
      const file = join(dir, `obj-${n++}`);
      writeFileSync(file, body);
      try {
        const run = spawnSync(
          'npx',
          ['wrangler', 'r2', 'object', 'put', `${r2Bucket}/${key}`, '--remote', '--file', file, '--content-type', contentType],
          { encoding: 'utf8' },
        );
        if (run.status !== 0) throw new Error(`wrangler put ${key} failed: ${(run.stderr || run.stdout || '').trim().slice(-300)}`);
      } finally {
        rmSync(file, { force: true });
      }
    },
    cleanup: () => rmSync(dir, { recursive: true, force: true }),
  };
}

async function workerHasAsset(workerUrl, key) {
  const res = await fetch(`${workerUrl}/api/v1/assets/${key}`, { method: 'HEAD', redirect: 'manual' });
  if (res.status === 200) return true;
  if (res.status === 302 || res.status === 404) return false;
  throw new Error(`Worker HEAD ${key} -> HTTP ${res.status}`);
}

// ---------------- main ----------------

async function main() {
  const opts = parseArgs(process.argv.slice(2));
  const keyPath = resolve(opts.keyFile.replace(/^~(?=\/)/, homedir()));
  const key = readFileSync(keyPath, 'utf8').trim();
  if (!key) throw new Error(`Empty key file: ${keyPath}`);

  const aw = appwrite(opts, key);
  const s3 = s3Client(process.env, opts.r2Bucket);
  const writer = s3 ?? (opts.dryRun ? null : wranglerWriter(opts.r2Bucket));
  const statePath = resolve(opts.state);
  const state = new Set(existsSync(statePath) ? JSON.parse(readFileSync(statePath, 'utf8')).copied || [] : []);
  const saveState = () => writeFileSync(statePath, JSON.stringify({ copied: [...state].sort() }, null, 2));

  const wanted = new Set(opts.buckets || KNOWN_BUCKETS);
  const summary = { buckets: 0, files: 0, copied: 0, wouldCopy: 0, skipped: 0, failed: 0, bytes: 0, ignoredBuckets: [] };
  const failures = [];

  console.log(`${opts.dryRun ? '[dry-run] ' : ''}Appwrite ${opts.endpoint} (project ${opts.project}) -> R2 ${opts.r2Bucket} via ${s3 ? 'S3 API' : 'wrangler'}`);

  for await (const bucket of aw.buckets()) {
    if (!wanted.has(bucket.$id)) {
      summary.ignoredBuckets.push(bucket.$id);
      continue;
    }
    summary.buckets++;
    const files = [];
    for await (const f of aw.files(bucket.$id)) files.push(f);
    console.log(`bucket ${bucket.$id}: ${files.length} file(s)`);

    let next = 0;
    const worker = async () => {
      while (next < files.length) {
        const file = files[next++];
        const objectKey = r2KeyFor(bucket.$id, file);
        const contentType = file.mimeType || 'application/octet-stream';
        summary.files++;
        try {
          let exists = state.has(objectKey);
          if (!exists && s3) exists = await s3.exists(objectKey);
          else if (!exists && !PRIVATE_BUCKETS.has(bucket.$id)) exists = await workerHasAsset(opts.workerUrl, objectKey);
          if (exists) {
            summary.skipped++;
            state.add(objectKey);
            continue;
          }
          if (opts.dryRun) {
            summary.wouldCopy++;
            summary.bytes += Number(file.sizeOriginal || 0);
            console.log(`  would copy ${objectKey} (${contentType}, ${file.sizeOriginal ?? '?'} bytes)`);
            continue;
          }
          const body = await aw.download(bucket.$id, file.$id);
          await writer.put(objectKey, body, contentType);
          state.add(objectKey);
          summary.copied++;
          summary.bytes += body.length;
          console.log(`  copied ${objectKey} (${contentType}, ${body.length} bytes)`);
          if (summary.copied % 25 === 0) saveState();
        } catch (e) {
          summary.failed++;
          failures.push(`${objectKey}: ${e.message}`);
          console.error(`  FAILED ${objectKey}: ${e.message}`);
        }
      }
    };
    await Promise.all(Array.from({ length: opts.concurrency }, worker));
  }

  if (!opts.dryRun) saveState();
  writer?.cleanup?.();
  console.log('\nSummary');
  console.log(JSON.stringify({ dryRun: opts.dryRun, ...summary, failures: failures.slice(0, 50) }, null, 2));
  if (summary.failed) process.exitCode = 1;
}

main().catch((e) => {
  console.error(`Error: ${e.message}`);
  process.exit(1);
});
