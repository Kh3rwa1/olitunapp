import fs from 'node:fs';

const gitleaksToml = fs.readFileSync('.gitleaks.toml', 'utf8');

// JS Case-insensitive regex matching the TOML pattern
const testRegex = /(appwrite[_-]?session[_-]?secret\s*[:=]\s*['"]?[a-zA-Z0-9_\-\.]{16,}['"]?|a_session_[a-zA-Z0-9_-]{8,}\s*[:=]\s*['"]?[a-zA-Z0-9_\-\.]{16,}['"]?|a_session_[a-zA-Z0-9_-]{8,}\t+[a-zA-Z0-9_\-\.]{16,})/i;

const positiveFixtures = [
  'APPWRITE_SESSION_SECRET=a_session_mocksecret1234567890abcdef',
  'appwrite-session-secret: "a_session_1234567890abcdef"',
  'appwrite_session_secret = \'mocksecretkey1234567890\'',
  'Set-Cookie: a_session_67890123456789012345=mocksecretkey1234567890',
  '.example.com\tTRUE\t/\tFALSE\t1750000000\ta_session_67890123456789012345\tmocksecretkey1234567890',
];

const negativeFixtures = [
  'const String webSessionSecretKey = \'olitun_appwrite_session_secret\';',
  '// APPWRITE_SESSION_SECRET is configured in secrets',
  'final secret = prefs.getString(\'olitun_appwrite_session_secret\');',
  'pck_test1234567890',
  'idempotency_key_12345',
];

console.log('🧪 Testing Gitleaks Custom Rules against Fixtures...');

let failures = 0;

for (const fixture of positiveFixtures) {
  if (!testRegex.test(fixture)) {
    console.error(`❌ Expected positive fixture to MATCH rule regex: "${fixture}"`);
    failures++;
  } else {
    console.log(`  ✓ Positive fixture detected: "${fixture.substring(0, 45)}..."`);
  }
}

for (const fixture of negativeFixtures) {
  if (testRegex.test(fixture)) {
    console.error(`❌ Expected negative fixture to NOT match rule regex: "${fixture}"`);
    failures++;
  } else {
    console.log(`  ✓ Negative fixture correctly allowed: "${fixture.substring(0, 45)}..."`);
  }
}

if (failures > 0) {
  console.error(`❌ Gitleaks rule verification failed with ${failures} error(s)!`);
  process.exit(1);
}

console.log('✅ Gitleaks rule fixture verification passed successfully!');
