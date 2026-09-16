from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def replace(path, old, new):
    target = ROOT / path
    value = target.read_text(encoding='utf-8')
    if value.count(old) != 1:
        raise RuntimeError(f'{path}: anchor drift')
    target.write_text(value.replace(old, new, 1), encoding='utf-8')


script = 'scripts/check_premium_content_permissions.mjs'
replace(
    script,
    "const PERMISSION_PATTERN = /^(?:read|create|update|delete)\\(\"[A-Za-z0-9:._+\\/-]{1,128}\"\\)$/;",
    "const PERMISSION_PATTERN = /^(?:read|create|update|delete|write)\\(\"[A-Za-z0-9:._+\\/-]{1,128}\"\\)$/;",
)
replace(
    script,
    """const AUTHORIZATION_FUNCTION_ID = 'getAuthorizedLesson';
const FLUTTER_SITE_ID = '69b2342a00065864275b';
""",
    """const AUTHORIZATION_FUNCTION_ID = 'getAuthorizedLesson';
const FLUTTER_SITE_ID = '69b2342a00065864275b';
const EXPECTED_PROJECT_ID = '699495910038e39622c5';
const EXPECTED_ENDPOINT = 'https://sgp.cloud.appwrite.io/v1';
""",
)
replace(
    script,
    """  const projectId = safeResourceId(
    String(process.env.APPWRITE_PROJECT_ID || '').trim(),
    'APPWRITE_PROJECT_ID',
  );
  const args = parseArgs(process.argv.slice(2), projectId);
  const rawEndpoint = process.env.APPWRITE_ENDPOINT || 'https://sgp.cloud.appwrite.io/v1';
  const endpointUrl = new URL(rawEndpoint);
  if (
    endpointUrl.protocol !== 'https:' ||
    !endpointUrl.hostname.endsWith('.appwrite.io') ||
    endpointUrl.pathname.replace(/\\/+$/, '') !== '/v1'
  ) {
    throw new Error('APPWRITE_ENDPOINT must be an Appwrite Cloud HTTPS v1 endpoint');
  }
  const endpoint = endpointUrl.toString().replace(/\\/$/, '');
""",
    """  const projectId = safeResourceId(
    String(process.env.APPWRITE_PROJECT_ID || EXPECTED_PROJECT_ID).trim(),
    'APPWRITE_PROJECT_ID',
  );
  if (projectId !== EXPECTED_PROJECT_ID) {
    throw new Error(`This migration is bound to Appwrite project ${EXPECTED_PROJECT_ID}`);
  }
  const args = parseArgs(process.argv.slice(2), projectId);
  const endpoint = String(process.env.APPWRITE_ENDPOINT || EXPECTED_ENDPOINT).replace(/\\/$/, '');
  if (endpoint !== EXPECTED_ENDPOINT) {
    throw new Error(`This migration is bound to ${EXPECTED_ENDPOINT}`);
  }
""",
)
replace(
    script,
    "  const adminTeamId = process.env.ADMIN_TEAM_ID || 'admins';\n",
    """  const adminTeamId = safeResourceId(
    String(process.env.ADMIN_TEAM_ID || 'admins').trim(),
    'ADMIN_TEAM_ID',
  );
""",
)
replace(
    'scripts/check_premium_content_permissions.test.mjs',
    """      $permissions: ['read(\"users\")'],
""",
    """      $permissions: ['read(\"users\")', 'write(\"team:admins\")'],
""",
)
replace(
    'scripts/check_premium_content_permissions.test.mjs',
    """  assert.equal(record.rows[0].id, 'lesson-1');
""",
    """  assert.equal(record.rows[0].id, 'lesson-1');
  assert.deepEqual(record.table.permissions, [
    'read(\"users\")',
    'write(\"team:admins\")',
  ]);
""",
)
replace(
    'scripts/README.md',
    """`check_premium_content_permissions.mjs` is dry-run only unless `--apply` is
provided with an exact project confirmation. Run the phases in order:
""",
    """`check_premium_content_permissions.mjs` is hard-bound to the production
Appwrite project and endpoint. It is dry-run only unless `--apply` is provided
with an exact project confirmation. Run the phases in order:
""",
)

print('migration binding cleanup applied')
