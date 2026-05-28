import assert from 'assert';
import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';

const testDir = path.resolve('scripts/test_temp');
if (!fs.existsSync(testDir)) {
  fs.mkdirSync(testDir, { recursive: true });
}

const mockSwContent = `
'use strict';
const MANIFEST = 'flutter-app-manifest';
const RESOURCES = {
"flutter_bootstrap.js": "770201dc295f75c0a6657459ab87ba79",
"version.json": "70ced078848d510143568958a5ec642e",
"index.html": "f07fec4c85224f70b1472d277779c983"
};
`;

const mockSwNoBootstrap = `
'use strict';
const MANIFEST = 'flutter-app-manifest';
const RESOURCES = {
"version.json": "70ced078848d510143568958a5ec642e",
"index.html": "f07fec4c85224f70b1472d277779c983"
};
`;

function runTest() {
  console.log('🧪 Starting Service Worker Patch Test Suite...');

  // Setup temporary dir mimicking build/web
  const buildWebDir = path.resolve('build/web');
  if (!fs.existsSync(buildWebDir)) {
    fs.mkdirSync(buildWebDir, { recursive: true });
  }

  const tempSwPath = path.resolve('build/web/flutter_service_worker.js');
  const backupSwExists = fs.existsSync(tempSwPath);
  let backupSwContent = '';
  if (backupSwExists) {
    backupSwContent = fs.readFileSync(tempSwPath, 'utf8');
  }

  try {
    // -------------------------------------------------------------
    // Test A: Typical SW output gets patched
    // -------------------------------------------------------------
    console.log('  - Test A: Typical SW output gets patched...');
    fs.writeFileSync(tempSwPath, mockSwContent, 'utf8');

    // Run patch script
    execSync('node scripts/patch_service_worker.mjs');
    const patchedContent = fs.readFileSync(tempSwPath, 'utf8');

    assert.ok(!patchedContent.includes('flutter_bootstrap.js'), 'bootstrap should be removed');
    assert.ok(patchedContent.includes('version.json'), 'other resources should be preserved');

    // Run verify script -> should exit 0 (success)
    let verifyExitCode = 0;
    try {
      execSync('node scripts/verify_service_worker_patch.mjs');
    } catch (e) {
      verifyExitCode = e.status || 1;
    }
    assert.strictEqual(verifyExitCode, 0, 'verify script should pass on patched file');

    // -------------------------------------------------------------
    // Test B: Idempotency (run twice = same result)
    // -------------------------------------------------------------
    console.log('  - Test B: Idempotency...');
    let secondPatchExitCode = 0;
    try {
      execSync('node scripts/patch_service_worker.mjs');
    } catch (e) {
      secondPatchExitCode = e.status || 1;
    }
    assert.strictEqual(secondPatchExitCode, 0, 'second patch run should exit zero');
    const doublePatchedContent = fs.readFileSync(tempSwPath, 'utf8');
    assert.strictEqual(doublePatchedContent, patchedContent, 'double patch should produce identical contents');

    // -------------------------------------------------------------
    // Test C: Missing bootstrap entry on first run causes patch to exit non-zero
    // -------------------------------------------------------------
    console.log('  - Test C: Missing bootstrap causes non-zero exit on unpatched file...');
    fs.writeFileSync(tempSwPath, mockSwNoBootstrap, 'utf8');

    let missingExitCode = 0;
    try {
      execSync('node scripts/patch_service_worker.mjs', { stdio: 'ignore' });
    } catch (e) {
      missingExitCode = e.status || 1;
    }
    assert.ok(missingExitCode !== 0, 'patch should exit non-zero if bootstrap is missing from unpatched file');

    // -------------------------------------------------------------
    // Test D: Verify step correctly detects unpatched file
    // -------------------------------------------------------------
    console.log('  - Test D: Verify correctly detects unpatched file...');
    fs.writeFileSync(tempSwPath, mockSwContent, 'utf8');

    let verifyFailCode = 0;
    try {
      execSync('node scripts/verify_service_worker_patch.mjs', { stdio: 'ignore' });
    } catch (e) {
      verifyFailCode = e.status || 1;
    }
    assert.ok(verifyFailCode !== 0, 'verify should exit non-zero on unpatched file');

    console.log('🎉 Service Worker Patch Test Suite passed successfully!');
  } finally {
    // Restore original sw file if it existed
    if (backupSwExists) {
      fs.writeFileSync(tempSwPath, backupSwContent, 'utf8');
    } else if (fs.existsSync(tempSwPath)) {
      fs.unlinkSync(tempSwPath);
    }
    if (fs.existsSync(testDir)) {
      fs.rmSync(testDir, { recursive: true });
    }
  }
}

runTest();
