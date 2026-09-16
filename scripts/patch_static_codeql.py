from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def replace(path, old, new):
    target = ROOT / path
    value = target.read_text(encoding='utf-8')
    count = value.count(old)
    if count != 1:
        raise RuntimeError(f'{path}: expected one anchor, found {count}')
    target.write_text(value.replace(old, new, 1), encoding='utf-8')


def splice(path, start_anchor, end_anchor, replacement):
    target = ROOT / path
    value = target.read_text(encoding='utf-8')
    start = value.find(start_anchor)
    end = value.find(end_anchor, start)
    if start < 0 or end < 0 or value.find(start_anchor, start + 1) >= 0:
        raise RuntimeError(f'{path}: splice anchor drift')
    target.write_text(value[:start] + replacement + value[end:], encoding='utf-8')


replace(
    'lib/shared/repositories/content_repository.dart',
    """    if (item.kind == ContentKind.lesson) {
      // Remove the pre-cutover body cache. Learner reads never consult either
      // item cache, but deleting the legacy key prevents accidental reuse.
      await CacheService.delete(_cacheItemKey(item.kind, item.id));
""",
    """    if (item.kind == ContentKind.lesson) {
      await CacheService.delete(_cacheItemKey(item.kind, item.id));
""",
)
replace(
    'lib/shared/repositories/content_repository.dart',
    """        // Authorized lesson metadata intentionally overrides bundled lesson
        // bodies with body-free, server-authoritative lock state.
        final mergedItems = _mergeContentItems(bundledItems, remoteItems);
""",
    """        final mergedItems = _mergeContentItems(bundledItems, remoteItems);
""",
)

permission = 'scripts/check_premium_content_permissions.mjs'
replace(
    permission,
    """const SHA_PATTERN = /^[0-9a-f]{40}$/i;
const PAID_UNLOCK_MODES = new Set(['paid_only', 'review_or_paid', 'review_only']);
""",
    """const SHA_PATTERN = /^[0-9a-f]{40}$/i;
const RESOURCE_ID_PATTERN = /^[A-Za-z0-9][A-Za-z0-9._-]{0,35}$/;
const PERMISSION_PATTERN = /^(?:read|create|update|delete)\\(\"[A-Za-z0-9:._+\\/-]{1,128}\"\\)$/;
const AUTHORIZATION_FUNCTION_ID = 'getAuthorizedLesson';
const FLUTTER_SITE_ID = '69b2342a00065864275b';
const PAID_UNLOCK_MODES = new Set(['paid_only', 'review_or_paid', 'review_only']);
""",
)
replace(
    permission,
    """function isReadPermission(permission) {
  return typeof permission === 'string' && permission.startsWith('read(');
}

""",
    """function isReadPermission(permission) {
  return typeof permission === 'string' && permission.startsWith('read(');
}

function safeResourceId(value, label) {
  if (typeof value !== 'string' || !RESOURCE_ID_PATTERN.test(value)) {
    throw new Error(`${label} is not a valid Appwrite resource ID`);
  }
  return value;
}

function apiPathId(value, label) {
  return encodeURIComponent(safeResourceId(value, label));
}

function safePermission(value) {
  if (typeof value !== 'string' || !PERMISSION_PATTERN.test(value)) {
    throw new Error('Rollback data contains a malformed permission');
  }
  return value;
}

""",
)
splice(
    permission,
    'export async function loadReleasePreflight(api, manifest, lessonTable = null) {\n',
    'function samePermissions(left, right) {\n',
    """export async function loadReleasePreflight(api, lessonTable = null) {
  const functionId = apiPathId(AUTHORIZATION_FUNCTION_ID, 'authorization function ID');
  const siteId = apiPathId(FLUTTER_SITE_ID, 'Flutter site ID');
  const authorizationFunction = await api('GET', `/functions/${functionId}`);
  if (!authorizationFunction?.deploymentId) throw new Error('Authorization function has no active deployment');
  const functionDeploymentId = apiPathId(
    authorizationFunction.deploymentId,
    'authorization deployment ID',
  );
  const site = await api('GET', `/sites/${siteId}`);
  if (!site?.deploymentId) throw new Error('Flutter site has no active deployment');
  const siteDeploymentId = apiPathId(site.deploymentId, 'site deployment ID');
  const [functionDeployment, variableResponse, entitlementTable, resolvedLessonTable, siteDeployment] =
    await Promise.all([
      api('GET', `/functions/${functionId}/deployments/${functionDeploymentId}`),
      api('GET', `/functions/${functionId}/variables`),
      api('GET', '/tablesdb/olitun_db/tables/course_purchases'),
      lessonTable || api('GET', '/tablesdb/olitun_db/tables/lessons'),
      api('GET', `/sites/${siteId}/deployments/${siteDeploymentId}`),
    ]);
  return {
    function: authorizationFunction,
    functionDeployment,
    variables: variableResponse?.variables || [],
    entitlementTable,
    lessonTable: resolvedLessonTable,
    site,
    siteDeployment,
  };
}

""",
)
splice(
    permission,
    'export function createRollbackRecord({ projectId, databaseId, table, plans, expectedCommit, generatedAt }) {\n',
    'function readManifest() {\n',
    """export function createRollbackRecord({ projectId, databaseId, table, plans, expectedCommit, generatedAt }) {
  return {
    version: 1,
    generatedAt,
    projectId: safeResourceId(projectId, 'rollback project ID'),
    databaseId: safeResourceId(databaseId, 'rollback database ID'),
    tableId: safeResourceId(rowId(table), 'rollback table ID'),
    expectedCommit,
    table: {
      rowSecurity: table.rowSecurity === true,
      enabled: table.enabled !== false,
      permissions: permissionsOf(table).map(safePermission),
    },
    rows: plans.map((plan) => ({
      id: safeResourceId(rowId(plan.lesson), 'rollback lesson ID'),
      permissions: plan.current.map(safePermission),
    })),
  };
}

""",
)
replace(
    permission,
    """  const manifest = readManifest();
  const projectId = process.env.APPWRITE_PROJECT_ID || manifest.projectId;
  const args = parseArgs(process.argv.slice(2), projectId);
  const endpoint = process.env.APPWRITE_ENDPOINT || 'https://sgp.cloud.appwrite.io/v1';
  const apiKey = String(process.env.APPWRITE_API_KEY || '').trim();
  const databaseId = process.env.APPWRITE_DATABASE_ID || 'olitun_db';
  const adminTeamId = process.env.ADMIN_TEAM_ID || 'admins';
  if (!apiKey) throw new Error('APPWRITE_API_KEY is required');
  if (databaseId !== 'olitun_db') throw new Error('This migration is bound to database olitun_db');
""",
    """  const manifest = readManifest();
  const projectId = safeResourceId(
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
  const apiKey = String(process.env.APPWRITE_API_KEY || '').trim();
  const databaseId = 'olitun_db';
  const adminTeamId = process.env.ADMIN_TEAM_ID || 'admins';
  if (!apiKey) throw new Error('APPWRITE_API_KEY is required');
""",
)
replace(
    permission,
    '  const preflight = await loadReleasePreflight(api, manifest, lessonTable);\n',
    '  const preflight = await loadReleasePreflight(api, lessonTable);\n',
)
replace(
    permission,
    """  writeFileSync(rollbackPath, `${JSON.stringify(rollback, null, 2)}\n`, { flag: 'wx', mode: 0o600 });
""",
    """  // This migration intentionally persists a bounded, permission-only copy
  // of validated live state so an operator can reverse the boundary mutation.
  // codeql[js/http-to-file-access]
  writeFileSync(rollbackPath, `${JSON.stringify(rollback, null, 2)}\n`, { flag: 'wx', mode: 0o600 });
""",
)
replace(
    'scripts/verify_live_appwrite_system.mjs',
    '      const preflight = await loadReleasePreflight(preflightApi, manifest);\n',
    '      const preflight = await loadReleasePreflight(preflightApi);\n',
)
replace(
    'scripts/check_premium_content_permissions.test.mjs',
    "test('rollback record contains permissions but no variables or secrets', () => {",
    """test('rollback records reject malformed resource IDs and permissions', () => {
  assert.throws(
    () => createRollbackRecord({
      projectId: 'p',
      databaseId: 'd',
      table: { $id: '../lessons', $permissions: [] },
      plans: [],
      expectedCommit: 'c'.repeat(40),
      generatedAt: '2026-09-16T00:00:00.000Z',
    }),
    /valid Appwrite resource ID/,
  );
  assert.throws(
    () => createRollbackRecord({
      projectId: 'p',
      databaseId: 'd',
      table: { $id: 'lessons', $permissions: ['read(\\\"any\\\")\\nsecret'] },
      plans: [],
      expectedCommit: 'c'.repeat(40),
      generatedAt: '2026-09-16T00:00:00.000Z',
    }),
    /malformed permission/,
  );
});

test('rollback record contains permissions but no variables or secrets', () => {""",
)

print('static and CodeQL corrections applied')
