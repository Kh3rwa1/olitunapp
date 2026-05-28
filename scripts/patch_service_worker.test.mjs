import assert from 'assert';
import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';

// --- Mock SW content variants ---

// Format A: Older Flutter SDK — bootstrap in RESOURCES only.
const mockSwResourcesOnly = `
'use strict';
const MANIFEST = 'flutter-app-manifest';
const RESOURCES = {
"flutter_bootstrap.js": "770201dc295f75c0a6657459ab87ba79",
"version.json": "70ced078848d510143568958a5ec642e",
"index.html": "f07fec4c85224f70b1472d277779c983"
};
const CORE = ["main.dart.js",
"index.html",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];
`;

// Format B: Current Flutter SDK — bootstrap in CORE only.
const mockSwCoreOnly = `
'use strict';
const MANIFEST = 'flutter-app-manifest';
const RESOURCES = {
"version.json": "70ced078848d510143568958a5ec642e",
"index.html": "f07fec4c85224f70b1472d277779c983",
"main.dart.js": "fb17f04cf2aadbba8cc9d2750106fdc2"
};
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];
`;

// Format C: Both locations (hypothetical, defensive).
const mockSwBoth = `
'use strict';
const MANIFEST = 'flutter-app-manifest';
const RESOURCES = {
"flutter_bootstrap.js": "770201dc295f75c0a6657459ab87ba79",
"version.json": "70ced078848d510143568958a5ec642e",
"index.html": "f07fec4c85224f70b1472d277779c983"
};
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];
`;

// Format D: No bootstrap anywhere (SDK drift / already clean).
const mockSwNoBootstrap = `
'use strict';
const MANIFEST = 'flutter-app-manifest';
const RESOURCES = {
"version.json": "70ced078848d510143568958a5ec642e",
"index.html": "f07fec4c85224f70b1472d277779c983"
};
const CORE = ["main.dart.js",
"index.html",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];
`;

function run(script, opts = {}) {
  try {
    execSync(`node scripts/${script}`, { stdio: opts.silent ? 'ignore' : 'pipe' });
    return 0;
  } catch (e) {
    return e.status || 1;
  }
}

function runTest() {
  console.log('🧪 Starting Service Worker Patch Test Suite...\n');

  const swPath = path.resolve('build/web/flutter_service_worker.js');
  const buildWebDir = path.resolve('build/web');
  if (!fs.existsSync(buildWebDir)) {
    fs.mkdirSync(buildWebDir, { recursive: true });
  }

  // Backup existing SW file if present
  const backupExists = fs.existsSync(swPath);
  const backupContent = backupExists ? fs.readFileSync(swPath, 'utf8') : '';

  let passed = 0;
  let failed = 0;

  function test(name, fn) {
    try {
      fn();
      console.log(`  ✅ ${name}`);
      passed++;
    } catch (e) {
      console.error(`  ❌ ${name}: ${e.message}`);
      failed++;
    }
  }

  try {
    // ----------------------------------------------------------------
    // Test 1: RESOURCES-only format (older Flutter SDK)
    // ----------------------------------------------------------------
    test('Patches RESOURCES-only format', () => {
      fs.writeFileSync(swPath, mockSwResourcesOnly);
      assert.strictEqual(run('patch_service_worker.mjs'), 0, 'patch should succeed');

      const content = fs.readFileSync(swPath, 'utf8');
      assert.ok(!content.includes('flutter_bootstrap.js'), 'bootstrap removed from RESOURCES');
      assert.ok(content.includes('// ITUN_PATCHED_SW'), 'patch marker present');
      assert.ok(content.includes('version.json'), 'other resources preserved');
    });

    // ----------------------------------------------------------------
    // Test 2: CORE-only format (current Flutter SDK)
    // ----------------------------------------------------------------
    test('Patches CORE-only format', () => {
      fs.writeFileSync(swPath, mockSwCoreOnly);
      assert.strictEqual(run('patch_service_worker.mjs'), 0, 'patch should succeed');

      const content = fs.readFileSync(swPath, 'utf8');
      assert.ok(!content.includes('flutter_bootstrap.js'), 'bootstrap removed from CORE');
      assert.ok(content.includes('// ITUN_PATCHED_SW'), 'patch marker present');
      assert.ok(content.includes('main.dart.js'), 'other CORE entries preserved');
    });

    // ----------------------------------------------------------------
    // Test 3: Both locations patched
    // ----------------------------------------------------------------
    test('Patches both RESOURCES and CORE', () => {
      fs.writeFileSync(swPath, mockSwBoth);
      assert.strictEqual(run('patch_service_worker.mjs'), 0, 'patch should succeed');

      const content = fs.readFileSync(swPath, 'utf8');
      assert.ok(!content.includes('flutter_bootstrap.js'), 'bootstrap removed from both');
      assert.ok(content.includes('// ITUN_PATCHED_SW'), 'patch marker present');
    });

    // ----------------------------------------------------------------
    // Test 4: Idempotency — second run exits 0, produces identical output
    // ----------------------------------------------------------------
    test('Idempotency (double-patch)', () => {
      fs.writeFileSync(swPath, mockSwCoreOnly);
      run('patch_service_worker.mjs');
      const firstPatch = fs.readFileSync(swPath, 'utf8');

      assert.strictEqual(run('patch_service_worker.mjs'), 0, 'second run should exit 0');
      const secondPatch = fs.readFileSync(swPath, 'utf8');
      assert.strictEqual(firstPatch, secondPatch, 'content should be identical');
    });

    // ----------------------------------------------------------------
    // Test 5: No bootstrap + no marker → exit non-zero (SDK drift)
    // ----------------------------------------------------------------
    test('SDK drift detection (no bootstrap, no marker)', () => {
      fs.writeFileSync(swPath, mockSwNoBootstrap);
      const code = run('patch_service_worker.mjs', { silent: true });
      assert.ok(code !== 0, 'should exit non-zero on SDK drift');
    });

    // ----------------------------------------------------------------
    // Test 6: Verify script passes on patched CORE-only file
    // ----------------------------------------------------------------
    test('Verify passes on patched CORE-only', () => {
      fs.writeFileSync(swPath, mockSwCoreOnly);
      run('patch_service_worker.mjs');
      assert.strictEqual(run('verify_service_worker_patch.mjs'), 0, 'verify should pass');
    });

    // ----------------------------------------------------------------
    // Test 7: Verify script fails on unpatched CORE-only file
    // ----------------------------------------------------------------
    test('Verify fails on unpatched CORE-only', () => {
      fs.writeFileSync(swPath, mockSwCoreOnly);
      const code = run('verify_service_worker_patch.mjs', { silent: true });
      assert.ok(code !== 0, 'verify should fail on unpatched file');
    });

    // ----------------------------------------------------------------
    // Test 8: Verify script fails on unpatched RESOURCES-only file
    // ----------------------------------------------------------------
    test('Verify fails on unpatched RESOURCES-only', () => {
      fs.writeFileSync(swPath, mockSwResourcesOnly);
      const code = run('verify_service_worker_patch.mjs', { silent: true });
      assert.ok(code !== 0, 'verify should fail on unpatched file');
    });

    // ----------------------------------------------------------------
    // Test 9: Verify catches missing patch marker
    // ----------------------------------------------------------------
    test('Verify fails when patch marker missing', () => {
      // Write a file where bootstrap is manually removed but no marker
      const manualClean = mockSwNoBootstrap.trim() + '\n';
      fs.writeFileSync(swPath, manualClean);
      const code = run('verify_service_worker_patch.mjs', { silent: true });
      assert.ok(code !== 0, 'verify should fail without patch marker');
    });

    console.log(`\n🧪 Results: ${passed} passed, ${failed} failed out of ${passed + failed} tests.`);
    if (failed > 0) process.exit(1);
    console.log('🎉 All tests passed!');

  } finally {
    // Restore original SW file
    if (backupExists) {
      fs.writeFileSync(swPath, backupContent, 'utf8');
    } else if (fs.existsSync(swPath)) {
      fs.unlinkSync(swPath);
    }
  }
}

runTest();
