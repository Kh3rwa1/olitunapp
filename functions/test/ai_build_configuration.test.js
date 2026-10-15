import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';

// Appwrite is used only for sign-in. Production builds must not point any
// feature (translate, voice, AI Studio) at Appwrite Functions; release
// builds default to the Cloudflare Worker routes.
const buildFiles = [
  'scripts/build_web.sh',
  'scripts/vercel_build.sh',
  'scripts/build_playstore_bundle.sh',
  'scripts/deploy_web_cloudflare.sh',
  '.github/workflows/build-apk.yml',
  '.github/workflows/deploy-web.yml',
  '.github/workflows/release-checklist.yml',
];

for (const path of buildFiles) {
  test(`${path} does not route features to Appwrite Functions`, () => {
    const source = fs.readFileSync(path, 'utf8');
    assert.doesNotMatch(source, /SANTALI_VOICE_FUNCTION_ID|AI_STUDIO_FUNCTION_ID/);
    assert.doesNotMatch(source, /TRANSLATE_URL/);
    assert.doesNotMatch(source, /\/functions\/[^/\s]+\/executions/);
  });
}
