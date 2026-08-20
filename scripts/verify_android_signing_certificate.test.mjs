import assert from 'node:assert/strict';
import test from 'node:test';

/**
 * Certificate fingerprint normalizer and comparator logic mirroring
 * scripts/verify_android_signing_certificate.sh.
 */
export function normalizeFingerprint(input) {
  if (!input || typeof input !== 'string') {
    throw new Error('Certificate fingerprint must be a non-empty string');
  }
  const normalized = input.replace(/[\s:\r\n\t-]/g, '').toUpperCase();
  if (!/^[0-9A-F]{64}$/.test(normalized)) {
    throw new Error(`Malformed fingerprint: expected 64 hexadecimal characters, got ${normalized.length}`);
  }
  return normalized;
}

export function parseApkSignerCertOutput(output) {
  const lines = output.split('\n');
  const digests = [];
  for (const line of lines) {
    const match = line.match(/certificate\s+SHA-256\s+digest:\s*([0-9a-fA-F:\s-]+)/i);
    if (match) {
      digests.push(match[1].trim());
    }
  }
  if (digests.length === 0) {
    throw new Error('No SHA-256 certificate digest found in apksigner output');
  }
  if (digests.length > 1) {
    throw new Error(`Expected exactly 1 signer certificate, found ${digests.length}`);
  }
  return normalizeFingerprint(digests[0]);
}

export function verifyCertificateMatch(actualOutput, expectedFingerprint) {
  const normalizedExpected = normalizeFingerprint(expectedFingerprint);
  const normalizedActual = parseApkSignerCertOutput(actualOutput);
  if (normalizedActual !== normalizedExpected) {
    throw new Error(
      `Certificate mismatch: expected ${normalizedExpected.slice(0, 8)}...${normalizedExpected.slice(-8)}, got ${normalizedActual.slice(0, 8)}...${normalizedActual.slice(-8)}`
    );
  }
  return true;
}

// ==========================================
// UNIT TESTS FOR CERTIFICATE PARSER
// ==========================================

test('Cert Normalization: Colon-delimited uppercase fingerprint is normalized correctly', () => {
  const colonHex = 'AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99';
  const norm = normalizeFingerprint(colonHex);
  assert.equal(norm.length, 64);
  assert.equal(norm, 'AABBCCDDEEFF00112233445566778899AABBCCDDEEFF00112233445566778899');
});

test('Cert Normalization: Lowercase dashed/spaced fingerprint is normalized to uppercase 64 chars', () => {
  const raw = 'aa-bb-cc-dd-ee-ff-00-11-22-33-44-55-66-77-88-99 aa bb cc dd ee ff 00 11 22 33 44 55 66 77 88 99';
  const norm = normalizeFingerprint(raw);
  assert.equal(norm.length, 64);
  assert.equal(norm, 'AABBCCDDEEFF00112233445566778899AABBCCDDEEFF00112233445566778899');
});

test('Cert Normalization: Malformed non-hex or invalid length throws error', () => {
  assert.throws(() => normalizeFingerprint('short_hash'), /Malformed fingerprint/);
  assert.throws(() => normalizeFingerprint('ZZ:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99'), /Malformed fingerprint/);
  assert.throws(() => normalizeFingerprint(''), /Certificate fingerprint must be a non-empty string/);
  assert.throws(() => normalizeFingerprint(null), /Certificate fingerprint must be a non-empty string/);
});

test('Cert Verification: Matches valid apksigner standard output', () => {
  const apksignerOutput = `
Signer #1 certificate DN: CN=Olitun Release, OU=Mobile, O=Olitun, L=Ranchi, ST=Jharkhand, C=IN
Signer #1 certificate SHA-256 digest: A1:B2:C3:D4:E5:F6:07:18:29:3A:4B:5C:6D:7E:8F:90:A1:B2:C3:D4:E5:F6:07:18:29:3A:4B:5C:6D:7E:8F:90
Signer #1 certificate SHA-1 digest: 12:34:56:78:90:ab:cd:ef:12:34:56:78:90:ab:cd:ef:12:34:56:78
`;
  const expected = 'a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90';
  assert.equal(verifyCertificateMatch(apksignerOutput, expected), true);
});

test('Cert Verification: Fails on certificate digest mismatch', () => {
  const apksignerOutput = `
Signer #1 certificate SHA-256 digest: 11:11:11:11:11:11:11:11:11:11:11:11:11:11:11:11:11:11:11:11:11:11:11:11:11:11:11:11:11:11:11:11
`;
  const expected = '22:22:22:22:22:22:22:22:22:22:22:22:22:22:22:22:22:22:22:22:22:22:22:22:22:22:22:22:22:22:22:22';
  assert.throws(() => verifyCertificateMatch(apksignerOutput, expected), /Certificate mismatch/);
});

test('Cert Verification: Fails on missing certificate or multiple signers', () => {
  assert.throws(() => parseApkSignerCertOutput('No certificates found'), /No SHA-256 certificate digest found/);

  const multipleSigners = `
Signer #1 certificate SHA-256 digest: AABBCCDDEEFF00112233445566778899AABBCCDDEEFF00112233445566778899
Signer #2 certificate SHA-256 digest: 11223344556677889900AABBCCDDEEFF11223344556677889900AABBCCDDEEFF
`;
  assert.throws(() => parseApkSignerCertOutput(multipleSigners), /Expected exactly 1 signer certificate, found 2/);
});
