import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { execSync } from 'node:child_process';

console.log('🧪 Testing Gitleaks Rules against Dynamic Temp Fixtures...');

// Create temporary directory outside Git workspace to avoid scanner false positives
const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'gitleaks-fixtures-'));

try {
  // Dynamically assemble positive secret strings in memory without static literals in source
  const secretPrefix = ['APPWRITE', 'SESSION', 'SECRET'].join('_');
  const sessionCookieName = ['a', 'session'].join('_') + '_67890123456789012345';
  const secretValue = 'mocksecretkey1234567890abcdef';

  const pos1 = `${secretPrefix}=${secretValue}`;
  const pos2 = `${secretPrefix.toLowerCase().replace(/_/g, '-')}: "${secretValue}"`;
  const pos3 = `Set-Cookie: ${sessionCookieName}=${secretValue}`;
  const pos4 = `.example.com\tTRUE\t/\tFALSE\t1750000000\t${sessionCookieName}\t${secretValue}`;

  const positiveFixtures = [pos1, pos2, pos3, pos4];

  const negativeFixtures = [
    "const String webSessionKey = 'olitun_appwrite_session_key';",
    '// Session configuration constant',
    'final pckToken = "pck_test1234567890";',
    'final idempotency = "idempotency_key_12345";',
  ];

  const posFilePath = path.join(tempDir, 'positive_fixtures.txt');
  const negFilePath = path.join(tempDir, 'negative_fixtures.txt');

  fs.writeFileSync(posFilePath, positiveFixtures.join('\n'));
  fs.writeFileSync(negFilePath, negativeFixtures.join('\n'));

  let gitleaksAvailable = false;
  try {
    execSync('gitleaks version', { stdio: 'pipe' });
    gitleaksAvailable = true;
  } catch {
    gitleaksAvailable = false;
  }

  const tomlPath = path.resolve('.gitleaks.toml');
  const tomlContent = fs.readFileSync(tomlPath, 'utf8');

  if (gitleaksAvailable) {
    console.log('  Using installed Gitleaks binary to scan temp fixtures...');
    
    // Test positive fixtures file — MUST detect leaks
    let posDetected = false;
    try {
      execSync(`gitleaks detect --config="${tomlPath}" --no-git --source="${posFilePath}" --exit-code=1`, { stdio: 'pipe' });
    } catch (err) {
      if (err.status === 1) {
        posDetected = true;
      }
    }

    if (!posDetected) {
      console.error('❌ Gitleaks binary FAILED to detect positive secret fixtures!');
      process.exit(1);
    }
    console.log('  ✓ Gitleaks binary successfully detected positive fixtures.');

    // Test negative fixtures file — MUST pass without leaks
    try {
      execSync(`gitleaks detect --config="${tomlPath}" --no-git --source="${negFilePath}" --exit-code=1`, { stdio: 'pipe' });
      console.log('  ✓ Gitleaks binary correctly allowed negative fixtures.');
    } catch (err) {
      console.error('❌ Gitleaks binary incorrectly flagged negative fixtures as secrets!');
      process.exit(1);
    }
  } else {
    console.log('  (Gitleaks binary not present in environment; evaluating parsed .gitleaks.toml rule regex)...');
    
    // Extract regex directly from .gitleaks.toml
    const regexMatch = tomlContent.match(/regex\s*=\s*'''([\s\S]+?)'''/);
    if (!regexMatch) {
      console.error('❌ Failed to extract rule regex from .gitleaks.toml!');
      process.exit(1);
    }

    const rawPattern = regexMatch[1].trim();
    // Remove (?i) inline flag and convert to JS RegExp with 'i' flag
    const cleanPattern = rawPattern.replace(/^\(\?i\)/, '');
    const ruleRegex = new RegExp(cleanPattern, 'i');

    let failures = 0;
    for (const fixture of positiveFixtures) {
      if (!ruleRegex.test(fixture)) {
        console.error(`❌ .gitleaks.toml rule regex failed to match positive fixture: "${fixture.substring(0, 40)}..."`);
        failures++;
      } else {
        console.log(`  ✓ Rule regex matched positive fixture.`);
      }
    }

    for (const fixture of negativeFixtures) {
      if (ruleRegex.test(fixture)) {
        console.error(`❌ .gitleaks.toml rule regex incorrectly matched negative fixture: "${fixture}"`);
        failures++;
      } else {
        console.log(`  ✓ Rule regex correctly allowed negative fixture.`);
      }
    }

    if (failures > 0) {
      console.error(`❌ Rule evaluation failed with ${failures} error(s)!`);
      process.exit(1);
    }
  }

  console.log('✅ Gitleaks rule fixture verification passed successfully!');
} finally {
  try {
    fs.rmSync(tempDir, { recursive: true, force: true });
  } catch {
    // ignore temp dir cleanup errors
  }
}
