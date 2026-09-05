import { pathToFileURL } from 'node:url';

const DATABASE_ID = process.env.APPWRITE_DATABASE_ID || 'olitun_db';
const ENDPOINT = process.env.APPWRITE_ENDPOINT || 'https://sgp.cloud.appwrite.io/v1';
const REQUEST_TIMEOUT_MS = 10_000;
const PAGE_SIZE = 100;
const MAX_PAGES = 100;
const PAID_UNLOCK_MODES = new Set([
  'paid_only',
  'review_or_paid',
  'review_only',
]);

export function classifyLesson(category, lesson) {
  if (!category) return { public: false, reason: 'category-unresolved' };
  if (lesson.isPremium === true) return { public: false, reason: 'item-marked-premium' };
  const mode = typeof category.unlockMode === 'string'
    ? category.unlockMode.trim().toLowerCase()
    : '';
  if (mode === 'free') return { public: true, reason: 'free-category' };
  if (!mode) return { public: false, reason: 'unlock-mode-missing' };
  if (!PAID_UNLOCK_MODES.has(mode)) {
    return { public: false, reason: `unknown-unlock-mode-${mode}` };
  }
  const order = Number(lesson.order);
  const previews = Number(category.previewLessonCount || 0);
  if (Number.isInteger(order) && order > 0 && order <= previews) {
    return { public: true, reason: 'legacy-order-window-preview' };
  }
  return { public: false, reason: `category-${mode}` };
}

export function desiredPermissions(current, allowAnonymousRead) {
  const retained = current.filter((permission) => !permission.startsWith('read('));
  return allowAnonymousRead ? [...retained, 'read("any")'] : retained;
}

export function collectionReadGrants(collection) {
  return (collection.$permissions || []).filter((permission) =>
    permission.startsWith('read('));
}

export function assertCollectionBoundary(collection) {
  if (collection.documentSecurity !== true) {
    throw new Error(
      'lessons.documentSecurity must be enabled before document permissions can enforce this boundary',
    );
  }
  const bypasses = collectionReadGrants(collection);
  if (bypasses.length > 0) {
    throw new Error(
      `lessons has collection-level read grants that bypass protected document permissions: ${bypasses.join(', ')}. Remove every collection read grant in a reviewed Appwrite configuration change before applying this migration.`,
    );
  }
}

export function parseArgs(argv, projectId) {
  const apply = argv.includes('--apply');
  const confirmedProject = argv
    .find((arg) => arg.startsWith('--confirm-project='))
    ?.slice('--confirm-project='.length);
  if (apply && confirmedProject !== projectId) {
    throw new Error(
      `Apply requires --confirm-project=${projectId} to bind approval to the explicit target project`,
    );
  }
  return { apply };
}

function runtimeConfig() {
  const projectId = process.env.APPWRITE_PROJECT_ID;
  const apiKey = process.env.APPWRITE_API_KEY;
  if (!projectId || !apiKey) {
    throw new Error(
      'Explicit APPWRITE_PROJECT_ID and APPWRITE_API_KEY environment variables are required; repository config is never used as a write target fallback',
    );
  }
  return { projectId, apiKey };
}

async function api(config, method, path, body) {
  const response = await fetch(`${ENDPOINT}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      'X-Appwrite-Project': config.projectId,
      'X-Appwrite-Key': config.apiKey,
    },
    body: body ? JSON.stringify(body) : undefined,
    signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
  });
  const text = await response.text();
  if (!response.ok) throw new Error(`${response.status} ${method} ${path}: ${text}`);
  return text ? JSON.parse(text) : null;
}

async function listDocuments(config, collectionId) {
  const documents = [];
  for (let pageNumber = 0; pageNumber < MAX_PAGES; pageNumber += 1) {
    const offset = pageNumber * PAGE_SIZE;
    const queries = encodeURIComponent(JSON.stringify({ method: 'limit', values: [PAGE_SIZE] }));
    const offsetQuery = encodeURIComponent(JSON.stringify({ method: 'offset', values: [offset] }));
    const page = await api(
      config,
      'GET',
      `/databases/${DATABASE_ID}/collections/${collectionId}/documents?queries[]=${queries}&queries[]=${offsetQuery}`,
    );
    documents.push(...page.documents);
    if (page.documents.length < PAGE_SIZE) return documents;
  }
  throw new Error(
    `${collectionId} exceeded the bounded ${MAX_PAGES * PAGE_SIZE}-document scan; no permissions were applied beyond the bound`,
  );
}

async function main() {
  const config = runtimeConfig();
  const { apply } = parseArgs(process.argv.slice(2), config.projectId);
  const collection = await api(
    config,
    'GET',
    `/databases/${DATABASE_ID}/collections/lessons`,
  );
  assertCollectionBoundary(collection);

  const [categories, lessons] = await Promise.all([
    listDocuments(config, 'categories'),
    listDocuments(config, 'lessons'),
  ]);
  const byId = new Map(categories.map((category) => [category.$id, category]));
  let drift = 0;
  const protectedMedia = new Set();

  for (const lesson of lessons) {
    const categoryId = typeof lesson.categoryId === 'string'
      ? lesson.categoryId
      : lesson.categoryId?.$id;
    const decision = classifyLesson(byId.get(categoryId), lesson);
    const desired = desiredPermissions(lesson.$permissions || [], decision.public);
    if (JSON.stringify(desired.slice().sort()) !== JSON.stringify((lesson.$permissions || []).slice().sort())) {
      drift += 1;
      console.log(`${apply ? 'APPLY' : 'DRY-RUN'} ${lesson.$id}: ${decision.reason} -> ${JSON.stringify(desired)}`);
      if (apply) {
        await api(
          config,
          'PATCH',
          `/databases/${DATABASE_ID}/collections/lessons/documents/${lesson.$id}`,
          { permissions: desired },
        );
      }
    }
    if (!decision.public) {
      for (const value of [lesson.thumbnailUrl, lesson.heroMediaUrl, lesson.heroPosterUrl, lesson.blocks]) {
        if (typeof value === 'string' && value.includes('/storage/buckets/')) protectedMedia.add(value);
      }
    }
  }

  console.log(`Mode: ${apply ? 'APPLY' : 'DRY-RUN'}; permission drift: ${drift}`);
  console.log(`Protected lessons reference ${protectedMedia.size} Appwrite media values requiring a private-bucket migration.`);
  if (protectedMedia.size > 0) {
    console.log('No media permissions were changed. Move/copy these assets only after signed retrieval is deployed.');
  }
  if (!apply && drift > 0) process.exitCode = 2;
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch((error) => {
    console.error(error.message);
    process.exit(1);
  });
}
