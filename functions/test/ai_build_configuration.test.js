import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';

for (const path of ['scripts/build_web.sh', 'scripts/vercel_build.sh', '.github/workflows/build-apk.yml']) {
  test(`${path} wires both AI function IDs into the Flutter build`, () => {
    const source = fs.readFileSync(path, 'utf8');
    assert.match(source, /--dart-define=SANTALI_VOICE_FUNCTION_ID=/);
    assert.match(source, /--dart-define=AI_STUDIO_FUNCTION_ID=/);
  });
}
