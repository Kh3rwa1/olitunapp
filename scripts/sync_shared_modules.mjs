#!/usr/bin/env node
/**
 * Syncs shared modules from functions/_shared into each consumer function's
 * src/shared/ directory, per functions/_shared/manifest.json.
 *
 * Appwrite function runtimes package only each function's own directory, so
 * cross-function imports fail at runtime — shared code must physically live
 * inside every consuming function. This script is the single source of truth
 * mechanism: edit functions/_shared/*, run this script, commit the result.
 *
 * Usage:
 *   node scripts/sync_shared_modules.mjs          copy canonical -> consumers
 *   node scripts/sync_shared_modules.mjs --check  exit 1 if any copy drifts
 */
import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import { fileURLToPath } from 'url';

const root = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
const sharedDir = path.join(root, 'functions', '_shared');
const manifest = JSON.parse(fs.readFileSync(path.join(sharedDir, 'manifest.json'), 'utf8'));
const checkOnly = process.argv.includes('--check');

function sha256(buf) {
  return crypto.createHash('sha256').update(buf).digest('hex');
}

let drifted = false;
for (const [functionId, modules] of Object.entries(manifest.consumers)) {
  const destDir = path.join(root, 'functions', functionId, 'src', 'shared');
  for (const mod of modules) {
    const canonical = path.join(sharedDir, mod);
    const dest = path.join(destDir, mod);
    if (!fs.existsSync(canonical)) {
      console.error(`✗ Canonical module missing: functions/_shared/${mod}`);
      process.exit(1);
    }
    const canonicalBuf = fs.readFileSync(canonical);
    const destBuf = fs.existsSync(dest) ? fs.readFileSync(dest) : null;

    if (checkOnly) {
      if (!destBuf || sha256(canonicalBuf) !== sha256(destBuf)) {
        console.error(
          `✗ Drift: functions/${functionId}/src/shared/${mod} does not match functions/_shared/${mod}. Run: node scripts/sync_shared_modules.mjs`,
        );
        drifted = true;
      }
      continue;
    }

    fs.mkdirSync(destDir, { recursive: true });
    fs.writeFileSync(dest, canonicalBuf);
    console.log(`✓ Synced ${mod} -> functions/${functionId}/src/shared/`);
  }
}

if (checkOnly) {
  if (drifted) process.exit(1);
  console.log('✅ Shared modules are in sync.');
} else {
  console.log('✅ Shared modules synced.');
}
