import test from 'node:test';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';

const require = createRequire(new URL('../getAuthorizedLesson/package.json', import.meta.url));
const { Client, Storage, Tokens } = require('node-appwrite');

test('deployed media SDK supports metadata and expiring resource-bound file tokens', async () => {
  const client = new Client().setEndpoint('https://example.invalid/v1').setProject('test');
  const requests = [];
  client.call = async (...args) => { requests.push(args); return {}; };
  await new Storage(client).getFile({ bucketId: 'paid_media', fileId: 'file' });
  await new Tokens(client).createFileToken({ bucketId: 'paid_media', fileId: 'file', expire: '2026-09-06T00:05:00Z' });
  assert.equal(requests.length, 2);
  assert.ok(requests[1].some(arg => arg && typeof arg === 'object' && arg.expire === '2026-09-06T00:05:00Z'));
  // The SDK binds bucket/file through the URL, not duplicated body fields.
  for (const request of requests) {
    assert.ok(request.some(arg => /\/buckets\/paid_media\/files\/file$/.test(String(arg))), 'Request must address exactly the authorized file');
  }
});
