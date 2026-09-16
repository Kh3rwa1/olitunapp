#!/usr/bin/env node
/**
 * Audit and stage the premium lesson permission cutover.
 *
 * Safe defaults:
 *   node scripts/check_premium_content_permissions.mjs
 *   node scripts/check_premium_content_permissions.mjs --phase=rows
 *
 * Mutations require an exact project binding:
 *   --apply --confirm-project=<project-id>
 *
 * The final boundary also requires the exact protected-main release commit:
 *   --phase=boundary --expected-release-commit=<sha>
 *   --apply --confirm-project=<project-id> --confirm-release-commit=<sha>
 */

import assert from 'node:assert/strict';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const SCRIPT_PATH = fileURLToPath(import.meta.url);
const ROOT = resolve(dirname(SCRIPT_PATH), '..');
const SHA_PATTERN = /^[0-9a-f]{40}$/i;
const PAID_UNLOCK_MODES = new Set(['paid_only', 'review_or_paid', 'review_only']);
const REQUIRED_VARIABLES = Object.freeze({
  APPWRITE_DATABASE_ID: 'olitun_db',
  LESSONS_COLLECTION_ID: 'lessons',
  COURSE_PURCHASES_COLLECTION_ID: 'course_purchases',
  PAID_MEDIA_BUCKET_ID: 'paid_media',
});

function permissionsOf(resource) {
  return Array.isArray(resource?.$permissions)
    ? resource.$permissions
    : Array.isArray(resource?.permissions)
      ? resource.permissions
      : [];
}

function rowId(row) {
  return typeof row?.$id === 'string'
    ? row.$id
    : typeof row?.id === 'string'
      ? row.id
      : '';
}

function normalizeRuntime(value) {
  return String(value || '').replace(/\.0$/, '');
}

function sorted(values) {
  return [...(values || [])].sort();
}

function isReadPermission(permission) {
  return typeof permission === 'string' && permission.startsWith('read(');
}

export function classifyLesson(category, lesson) {
  if (!category) return { public: false, reason: 'category-unresolved' };
  if (lesson?.isPremium === true) {
    return { public: false, reason: 'item-marked-premium' };
  }

  const mode = typeof category.unlockMode === 'string'
    ? category.unlockMode.trim().toLowerCase()
    : '';
  if (!mode) return { public: false, reason: 'unlock-mode-missing' };
  if (mode === 'free') return { public: true, reason: 'free-category' };
  if (!PAID_UNLOCK_MODES.has(mode)) {
    return { public: false, reason: `unknown-unlock-mode-${mode}` };
  }
  if (lesson?.isPreview === true) {
    return { public: true, reason: 'explicit-preview' };
  }

  const order = Number(lesson?.order);
  const previewLessonCount = Number(category.previewLessonCount || 0);
  if (
    Number.isInteger(order) &&
    order > 0 &&
    Number.isInteger(previewLessonCount) &&
    previewLessonCount > 0 &&
    order <= previewLessonCount
  ) {
    return { public: true, reason: 'legacy-order-window-preview' };
  }
  return { public: false, reason: `category-${mode}` };
}

export function desiredPermissions(currentPermissions, allowAnonymousRead) {
  const retained = (currentPermissions || []).filter((permission) => !isReadPermission(permission));
  if (allowAnonymousRead) retained.push('read("any")');
  return [...new Set(retained)];
}

export function desiredTablePermissions(currentPermissions, adminTeamId = 'admins') {
  const retained = (currentPermissions || []).filter((permission) => !isReadPermission(permission));
  retained.push(`read("team:${adminTeamId}")`);
  return [...new Set(retained)];
}

export function assertCollectionBoundary(table, adminTeamId = 'admins') {
  assert.equal(table?.rowSecurity, true, 'lesson table rowSecurity must be enabled');
  const reads = permissionsOf(table).filter(isReadPermission);
  const expectedAdminRead = `read("team:${adminTeamId}")`;
  assert.ok(reads.includes(expectedAdminRead), 'lesson table must retain admin-team read access');
  assert.equal(
    reads.some((permission) => permission !== expectedAdminRead),
    false,
    'lesson table contains a non-admin table-level read grant',
  );
}

export function auditLessonOrders(lessons) {
  const anomalies = [];
  const byCategory = new Map();
  for (const lesson of lessons || []) {
    const categoryId = typeof lesson?.categoryId === 'string' ? lesson.categoryId : '';
    const id = rowId(lesson);
    const order = Number(lesson?.order);
    if (!categoryId || !Number.isInteger(order) || order <= 0) {
      anomalies.push({ type: 'invalid_or_zero', lessonId: id, categoryId, order });
      continue;
    }
    if (!byCategory.has(categoryId)) byCategory.set(categoryId, []);
    byCategory.get(categoryId).push({ id, order });
  }

  for (const [categoryId, values] of byCategory.entries()) {
    values.sort((a, b) => a.order - b.order || a.id.localeCompare(b.id));
    let expected = 1;
    let previous = null;
    for (const value of values) {
      if (value.order === previous) {
        anomalies.push({ type: 'duplicate', categoryId, lessonId: value.id, order: value.order });
        continue;
      }
      if (value.order !== expected) {
        anomalies.push({
          type: 'gap',
          categoryId,
          lessonId: value.id,
          expected,
          actual: value.order,
        });
      }
      previous = value.order;
      expected = value.order + 1;
    }
  }
  return anomalies;
}

export function cursorQueries(cursor, limit = 100) {
  const queries = [{ method: 'limit', values: [limit] }];
  if (cursor) queries.push({ method: 'cursorAfter', values: [cursor] });
  return queries.map((query) => JSON.stringify(query));
}

export function parseArgs(argv, projectId) {
  const parsed = {
    phase: 'audit',
    apply: false,
    expectedReleaseCommit: null,
    rollbackOutput: null,
  };
  let confirmProject = null;
  let confirmReleaseCommit = null;

  for (const argument of argv) {
    if (argument === '--apply') parsed.apply = true;
    else if (argument.startsWith('--phase=')) parsed.phase = argument.slice('--phase='.length);
    else if (argument.startsWith('--confirm-project=')) {
      confirmProject = argument.slice('--confirm-project='.length);
    } else if (argument.startsWith('--expected-release-commit=')) {
      parsed.expectedReleaseCommit = argument.slice('--expected-release-commit='.length).toLowerCase();
    } else if (argument.startsWith('--confirm-release-commit=')) {
      confirmReleaseCommit = argument.slice('--confirm-release-commit='.length).toLowerCase();
    } else if (argument.startsWith('--rollback-output=')) {
      parsed.rollbackOutput = argument.slice('--rollback-output='.length);
    } else {
      throw new Error(`Unknown argument: ${argument}`);
    }
  }

  if (!['audit', 'rows', 'boundary'].includes(parsed.phase)) {
    throw new Error('--phase must be audit, rows, or boundary');
  }
  if (parsed.apply && parsed.phase === 'audit') {
    throw new Error('--apply requires --phase=rows or --phase=boundary');
  }
  if (parsed.apply && confirmProject !== projectId) {
    throw new Error(`Writes require --confirm-project=${projectId}`);
  }
  if (parsed.phase === 'boundary') {
    if (!SHA_PATTERN.test(parsed.expectedReleaseCommit || '')) {
      throw new Error('--phase=boundary requires --expected-release-commit=<40-char-sha>');
    }
    if (parsed.apply && confirmReleaseCommit !== parsed.expectedReleaseCommit) {
      throw new Error(
        `Boundary writes require --confirm-release-commit=${parsed.expectedReleaseCommit}`,
      );
    }
  }
  return parsed;
}

export function assertFunctionMatchesManifest(actual, declared) {
  assert.equal(actual?.$id, declared?.$id, 'authorization function ID drift');
  assert.equal(normalizeRuntime(actual?.runtime), normalizeRuntime(declared?.runtime), 'runtime drift');
  assert.deepEqual(sorted(actual?.execute), sorted(declared?.execute), 'execute-role drift');
  assert.deepEqual(sorted(actual?.scopes), sorted(declared?.scopes), 'scope drift');
  assert.equal(actual?.timeout, declared?.timeout, 'function timeout drift');
  assert.equal(actual?.entrypoint, declared?.entrypoint, 'function entrypoint drift');
  if (actual?.providerRootDirectory) {
    assert.equal(actual.providerRootDirectory, declared?.path, 'function VCS root drift');
  }
  if (actual?.providerBranch) {
    assert.equal(actual.providerBranch, 'main', 'authorization function must deploy from main');
  }
}

export function assertActiveDeployment(resource, deployment, expectedCommit, label) {
  assert.ok(resource?.deploymentId, `${label} has no active deployment`);
  assert.equal(deployment?.$id, resource.deploymentId, `${label} verifier did not load deploymentId`);
  assert.equal(deployment?.status, 'ready', `${label} active deployment is not ready`);
  const commit = deployment?.providerCommitHash || deployment?.commitHash || deployment?.commit;
  assert.equal(commit, expectedCommit, `${label} active deployment commit does not match release`);
  if (deployment?.providerBranch) {
    assert.equal(deployment.providerBranch, 'main', `${label} active deployment is not from main`);
  }
}

export function assertRequiredVariables(variables) {
  const byKey = new Map((variables || []).map((variable) => [variable.key, variable.value]));
  assert.equal(byKey.has('PAYMENT_COLLECTION_ID'), false, 'stale PAYMENT_COLLECTION_ID must be removed');
  for (const [key, expectedValue] of Object.entries(REQUIRED_VARIABLES)) {
    assert.equal(byKey.get(key), expectedValue, `missing or stale authorization variable ${key}`);
  }
  const mediaEndpoint = byKey.get('MEDIA_PUBLIC_ENDPOINT');
  assert.match(String(mediaEndpoint || ''), /^https:\/\/[a-z0-9.-]+\/v1\/?$/i, 'MEDIA_PUBLIC_ENDPOINT is invalid');
}

export function assertEntitlementBoundary(table) {
  assert.equal(table?.rowSecurity, true, 'course_purchases rowSecurity must be enabled');
  assert.deepEqual(
    permissionsOf(table).filter(isReadPermission),
    [],
    'course_purchases must not have table-level reads',
  );
}

export function assertReleasePreflight(preflight, manifest, expectedCommit) {
  assert.match(expectedCommit || '', SHA_PATTERN, 'expected release commit must be a full SHA');
  const declaredFunction = manifest.functions.find((item) => item.$id === 'getAuthorizedLesson');
  const declaredSite = manifest.sites.find((item) => item.$id === preflight.site.$id);
  assert.ok(declaredFunction, 'getAuthorizedLesson is missing from appwrite.json');
  assert.ok(declaredSite, 'active site is missing from appwrite.json');
  assertFunctionMatchesManifest(preflight.function, declaredFunction);
  assertActiveDeployment(
    preflight.function,
    preflight.functionDeployment,
    expectedCommit,
    'getAuthorizedLesson',
  );
  assertActiveDeployment(preflight.site, preflight.siteDeployment, expectedCommit, 'Flutter site');
  assertRequiredVariables(preflight.variables);
  assertEntitlementBoundary(preflight.entitlementTable);
  const previewColumn = (preflight.lessonTable?.columns || []).find((column) => column.key === 'isPreview');
  assert.ok(previewColumn, 'lessons.isPreview column is missing');
  assert.equal(previewColumn.type, 'boolean', 'lessons.isPreview must be boolean');
  assert.equal(previewColumn.required, false, 'lessons.isPreview must be optional');
  assert.equal(previewColumn.default, false, 'lessons.isPreview must default to false');
  assert.equal(previewColumn.status, 'available', 'lessons.isPreview is not available');
}

export function createApiClient({ endpoint, projectId, apiKey, fetchImpl = fetch }) {
  return async function api(method, path, body = undefined) {
    const response = await fetchImpl(`${endpoint}${path}`, {
      method,
      headers: {
        'content-type': 'application/json',
        'x-appwrite-project': projectId,
        'x-appwrite-key': apiKey,
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
    const text = await response.text();
    const payload = text ? JSON.parse(text) : null;
    if (!response.ok) {
      throw new Error(`${method} ${path} failed with ${response.status}: ${payload?.message || 'request failed'}`);
    }
    return payload;
  };
}

function queryPath(path, queries) {
  const params = new URLSearchParams();
  for (const query of queries) params.append('queries[]', query);
  return `${path}?${params}`;
}

export async function listAllRows(api, databaseId, tableId, limit = 100) {
  const rows = [];
  const seen = new Set();
  let cursor = null;
  for (let page = 0; page < 100; page += 1) {
    const payload = await api(
      'GET',
      queryPath(`/tablesdb/${databaseId}/tables/${tableId}/rows`, cursorQueries(cursor, limit)),
    );
    const pageRows = Array.isArray(payload?.rows) ? payload.rows : [];
    for (const row of pageRows) {
      const id = rowId(row);
      if (!id || seen.has(id)) throw new Error(`Malformed or duplicate row while listing ${tableId}`);
      seen.add(id);
      rows.push(row);
    }
    if (pageRows.length < limit) return rows;
    const nextCursor = rowId(pageRows.at(-1));
    if (!nextCursor || nextCursor === cursor) throw new Error(`Invalid cursor while listing ${tableId}`);
    cursor = nextCursor;
  }
  throw new Error(`${tableId} exceeded the 10,000-row safety bound`);
}

export async function loadReleasePreflight(api, manifest, lessonTable = null) {
  const functionId = 'getAuthorizedLesson';
  const siteId = manifest.sites?.[0]?.$id;
  if (!siteId) throw new Error('No Appwrite site is declared');
  const authorizationFunction = await api('GET', `/functions/${functionId}`);
  if (!authorizationFunction?.deploymentId) throw new Error('Authorization function has no active deployment');
  const site = await api('GET', `/sites/${siteId}`);
  if (!site?.deploymentId) throw new Error('Flutter site has no active deployment');
  const [functionDeployment, variableResponse, entitlementTable, resolvedLessonTable, siteDeployment] =
    await Promise.all([
      api('GET', `/functions/${functionId}/deployments/${authorizationFunction.deploymentId}`),
      api('GET', `/functions/${functionId}/variables`),
      api('GET', '/tablesdb/olitun_db/tables/course_purchases'),
      lessonTable || api('GET', '/tablesdb/olitun_db/tables/lessons'),
      api('GET', `/sites/${siteId}/deployments/${site.deploymentId}`),
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

function samePermissions(left, right) {
  return JSON.stringify(sorted(left)) === JSON.stringify(sorted(right));
}

function buildPlans(categories, lessons) {
  const categoriesById = new Map(categories.map((category) => [rowId(category), category]));
  return lessons.map((lesson) => {
    const decision = classifyLesson(categoriesById.get(lesson.categoryId), lesson);
    const current = permissionsOf(lesson);
    const desired = desiredPermissions(current, decision.public);
    return {
      lesson,
      decision,
      current,
      desired,
      changed: !samePermissions(current, desired),
    };
  });
}

export function createRollbackRecord({ projectId, databaseId, table, plans, expectedCommit, generatedAt }) {
  return {
    version: 1,
    generatedAt,
    projectId,
    databaseId,
    tableId: rowId(table),
    expectedCommit,
    table: {
      name: table.name,
      rowSecurity: table.rowSecurity,
      enabled: table.enabled,
      permissions: permissionsOf(table),
    },
    rows: plans.map((plan) => ({
      id: rowId(plan.lesson),
      permissions: plan.current,
    })),
  };
}

function readManifest() {
  return JSON.parse(readFileSync(resolve(ROOT, 'appwrite.json'), 'utf8'));
}

async function main() {
  const manifest = readManifest();
  const projectId = process.env.APPWRITE_PROJECT_ID || manifest.projectId;
  const args = parseArgs(process.argv.slice(2), projectId);
  const endpoint = process.env.APPWRITE_ENDPOINT || 'https://sgp.cloud.appwrite.io/v1';
  const apiKey = String(process.env.APPWRITE_API_KEY || '').trim();
  const databaseId = process.env.APPWRITE_DATABASE_ID || 'olitun_db';
  const adminTeamId = process.env.ADMIN_TEAM_ID || 'admins';
  if (!apiKey) throw new Error('APPWRITE_API_KEY is required');
  if (databaseId !== 'olitun_db') throw new Error('This migration is bound to database olitun_db');

  const api = createApiClient({ endpoint, projectId, apiKey });
  const [lessonTable, lessons, categories] = await Promise.all([
    api('GET', `/tablesdb/${databaseId}/tables/lessons`),
    listAllRows(api, databaseId, 'lessons'),
    listAllRows(api, databaseId, 'categories'),
  ]);
  const orderAnomalies = auditLessonOrders(lessons);
  const plans = buildPlans(categories, lessons);
  const changedPlans = plans.filter((plan) => plan.changed);
  const publicCount = plans.filter((plan) => plan.decision.public).length;

  console.log(`Phase: ${args.phase}${args.apply ? ' (apply)' : ' (dry-run)'}`);
  console.log(`Lessons audited: ${lessons.length}`);
  console.log(`Public/free-or-preview rows: ${publicCount}`);
  console.log(`Protected rows: ${lessons.length - publicCount}`);
  console.log(`Rows needing permission updates: ${changedPlans.length}`);
  if (orderAnomalies.length > 0) {
    throw new Error(`Refusing migration: ${orderAnomalies.length} lesson-order anomalies detected`);
  }

  if (args.phase === 'audit') {
    console.log('Audit complete; no mutations were requested.');
    return;
  }

  if (args.phase === 'rows') {
    if (!args.apply) {
      console.log('Dry-run complete. Re-run with exact project confirmation to stage row permissions.');
      return;
    }
    for (const plan of changedPlans) {
      await api(
        'PATCH',
        `/tablesdb/${databaseId}/tables/lessons/rows/${encodeURIComponent(rowId(plan.lesson))}`,
        { permissions: plan.desired },
      );
    }
    const verifiedRows = await listAllRows(api, databaseId, 'lessons');
    const verifiedPlans = buildPlans(categories, verifiedRows);
    assert.equal(
      verifiedPlans.filter((plan) => plan.changed).length,
      0,
      'row permission verification failed',
    );
    console.log(`Staged and verified ${changedPlans.length} lesson row permission updates.`);
    return;
  }

  assert.equal(changedPlans.length, 0, 'stage and verify row permissions before the boundary phase');
  const preflight = await loadReleasePreflight(api, manifest, lessonTable);
  assertReleasePreflight(preflight, manifest, args.expectedReleaseCommit);
  if (!args.apply) {
    console.log('Boundary preflight passed. No table permissions were changed.');
    return;
  }

  const rollbackPath = resolve(
    ROOT,
    args.rollbackOutput ||
      `.premium-content-rollback/lessons-${new Date().toISOString().replace(/[:.]/g, '-')}.json`,
  );
  const rollback = createRollbackRecord({
    projectId,
    databaseId,
    table: lessonTable,
    plans,
    expectedCommit: args.expectedReleaseCommit,
    generatedAt: new Date().toISOString(),
  });
  mkdirSync(dirname(rollbackPath), { recursive: true });
  writeFileSync(rollbackPath, `${JSON.stringify(rollback, null, 2)}\n`, { flag: 'wx', mode: 0o600 });
  console.log(`Rollback record written before boundary mutation: ${rollbackPath}`);

  await api('PUT', `/tablesdb/${databaseId}/tables/lessons`, {
    name: lessonTable.name,
    permissions: desiredTablePermissions(permissionsOf(lessonTable), adminTeamId),
    rowSecurity: true,
    enabled: lessonTable.enabled !== false,
    purge: true,
  });
  const verifiedTable = await api('GET', `/tablesdb/${databaseId}/tables/lessons`);
  assertCollectionBoundary(verifiedTable, adminTeamId);
  console.log('Lesson table boundary enabled and verified.');
}

if (process.argv[1] && resolve(process.argv[1]) === resolve(SCRIPT_PATH)) {
  main().catch((error) => {
    console.error(`Premium content permission check failed: ${error.message}`);
    process.exitCode = 1;
  });
}
