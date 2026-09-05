import { readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

const DATABASE_ID = process.env.APPWRITE_DATABASE_ID || 'olitun_db';
const ENDPOINT = process.env.APPWRITE_ENDPOINT || 'https://sgp.cloud.appwrite.io/v1';

function projectIdFromConfig() {
  try {
    return JSON.parse(readFileSync(new URL('../appwrite.config.json', import.meta.url), 'utf8')).projectId || '';
  } catch (_) {
    return '';
  }
}

export function classifyLesson(category, lesson) {
  if (!category) return { public: false, reason: 'category-unresolved' };
  if (lesson.isPremium === true) return { public: false, reason: 'item-marked-premium' };
  const mode = typeof category.unlockMode === 'string'
    ? category.unlockMode.trim().toLowerCase()
    : '';
  if (mode === 'free') return { public: true, reason: 'free-category' };
  if (!mode) return { public: false, reason: 'unlock-mode-missing' };
  const order = Number(lesson.order);
  const previews = Number(category.previewLessonCount || 0);
  if (Number.isInteger(order) && order > 0 && order <= previews) {
    return { public: true, reason: 'configured-preview' };
  }
  return { public: false, reason: `category-${mode}` };
}

export function desiredPermissions(current, allowAnonymousRead) {
  const retained = current.filter((permission) =>
    permission !== 'read("any")' && permission !== 'read("users")');
  return allowAnonymousRead ? [...retained, 'read("any")'] : retained;
}

function parseArgs(argv) {
  const apply = argv.includes('--apply');
  const confirmation = argv.find((arg) => arg.startsWith('--confirm='))?.split('=')[1];
  if (apply && confirmation !== 'premium-content-permissions') {
    throw new Error('Apply requires --confirm=premium-content-permissions');
  }
  return { apply };
}

async function api(method, path, body) {
  const projectId = process.env.APPWRITE_PROJECT_ID || projectIdFromConfig();
  const apiKey = process.env.APPWRITE_API_KEY;
  if (!projectId || !apiKey) throw new Error('APPWRITE_PROJECT_ID and APPWRITE_API_KEY are required');
  const response = await fetch(`${ENDPOINT}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      'X-Appwrite-Project': projectId,
      'X-Appwrite-Key': apiKey,
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await response.text();
  if (!response.ok) throw new Error(`${response.status} ${method} ${path}: ${text}`);
  return text ? JSON.parse(text) : null;
}

async function listDocuments(collectionId) {
  const documents = [];
  let offset = 0;
  while (true) {
    const queries = encodeURIComponent(JSON.stringify({ method: 'limit', values: [100] }));
    const offsetQuery = encodeURIComponent(JSON.stringify({ method: 'offset', values: [offset] }));
    const page = await api('GET', `/databases/${DATABASE_ID}/collections/${collectionId}/documents?queries[]=${queries}&queries[]=${offsetQuery}`);
    documents.push(...page.documents);
    if (page.documents.length < 100) return documents;
    offset += page.documents.length;
  }
}

async function main() {
  const { apply } = parseArgs(process.argv.slice(2));
  const collection = await api('GET', `/databases/${DATABASE_ID}/collections/lessons`);
  if (collection.documentSecurity !== true) {
    throw new Error('lessons.documentSecurity must be enabled before document permissions can enforce this boundary');
  }

  const [categories, lessons] = await Promise.all([
    listDocuments('categories'),
    listDocuments('lessons'),
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
        await api('PATCH', `/databases/${DATABASE_ID}/collections/lessons/documents/${lesson.$id}`, { permissions: desired });
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
