import { Query } from 'node-appwrite';

const DEFAULT_PAGE_SIZE = 100;
const MAX_PAGE_SIZE = 100;
const MAX_SUPPORTING_PAGES = 20;
const APPWRITE_ID_PATTERN = /^[A-Za-z0-9][A-Za-z0-9._-]{0,35}$/;

export class ListLessonsRequestError extends Error {
  constructor(message, { code = 'invalid_list_request', statusCode = 400 } = {}) {
    super(message);
    this.name = 'ListLessonsRequestError';
    this.code = code;
    this.statusCode = statusCode;
  }
}

function optionalAppwriteId(value, fieldName) {
  if (value === null || value === undefined || value === '') return null;
  if (typeof value !== 'string' || !APPWRITE_ID_PATTERN.test(value)) {
    throw new ListLessonsRequestError(`Invalid ${fieldName}`, {
      code: `invalid_${fieldName.replace(/[A-Z]/g, (letter) => `_${letter.toLowerCase()}`)}`,
    });
  }
  return value;
}

export function parseListLessonsRequest(body = {}) {
  const rawLimit = body.limit ?? DEFAULT_PAGE_SIZE;
  const limit = Number(rawLimit);
  if (!Number.isInteger(limit) || limit < 1 || limit > MAX_PAGE_SIZE) {
    throw new ListLessonsRequestError(`limit must be an integer from 1 to ${MAX_PAGE_SIZE}`, {
      code: 'invalid_limit',
    });
  }

  return {
    categoryId: optionalAppwriteId(body.categoryId, 'categoryId'),
    cursor: optionalAppwriteId(body.cursor, 'cursor'),
    limit,
  };
}

function documentId(value) {
  if (typeof value === 'string') return value;
  if (value && typeof value === 'object') {
    const id = value.$id || value.id;
    return typeof id === 'string' ? id : '';
  }
  return '';
}

async function listAllByCursor({
  databases,
  databaseId,
  collectionId,
  baseQueries = [],
}) {
  const documents = [];
  let cursor = null;

  for (let page = 0; page < MAX_SUPPORTING_PAGES; page += 1) {
    const queries = [...baseQueries, Query.limit(MAX_PAGE_SIZE)];
    if (cursor) queries.push(Query.cursorAfter(cursor));
    const result = await databases.listDocuments(databaseId, collectionId, queries);
    const pageDocuments = Array.isArray(result.documents) ? result.documents : [];
    documents.push(...pageDocuments);

    if (pageDocuments.length < MAX_PAGE_SIZE) return documents;
    const nextCursor = documentId(pageDocuments.at(-1));
    if (!nextCursor || nextCursor === cursor) {
      throw new Error(`Invalid cursor while reading ${collectionId}`);
    }
    cursor = nextCursor;
  }

  throw new Error(`${collectionId} exceeded the bounded supporting-document scan`);
}

async function loadCategoryMap({ databases, databaseId, categoryId }) {
  if (categoryId) {
    try {
      const category = await databases.getDocument(databaseId, 'categories', categoryId);
      return new Map([[categoryId, category]]);
    } catch (error) {
      if (error?.code === 404) return new Map();
      throw error;
    }
  }

  const categories = await listAllByCursor({
    databases,
    databaseId,
    collectionId: 'categories',
  });
  return new Map(
    categories
      .map((category) => [documentId(category), category])
      .filter(([id]) => id),
  );
}

async function loadPurchasesByCategory({ databases, databaseId, callerUserId }) {
  if (!callerUserId) return new Map();

  const purchases = await listAllByCursor({
    databases,
    databaseId,
    collectionId: 'course_purchases',
    baseQueries: [Query.equal('userId', callerUserId)],
  });
  const byCategory = new Map();
  for (const purchase of purchases) {
    const categoryId = documentId(purchase.categoryId);
    if (!categoryId) continue;
    if (!byCategory.has(categoryId)) byCategory.set(categoryId, []);
    byCategory.get(categoryId).push(purchase);
  }
  return byCategory;
}

export function toLessonListMetadata(lesson, accessDecision) {
  const id = documentId(lesson);
  const categoryId = documentId(lesson.categoryId);
  return {
    id,
    categoryId,
    titleOlChiki: typeof lesson.titleOlChiki === 'string' ? lesson.titleOlChiki : '',
    titleLatin: typeof lesson.titleLatin === 'string' ? lesson.titleLatin : '',
    level: typeof lesson.level === 'string' ? lesson.level : 'beginner',
    description: typeof lesson.description === 'string' ? lesson.description : '',
    order: Number.isFinite(Number(lesson.order)) ? Number(lesson.order) : 0,
    estimatedMinutes: Number.isFinite(Number(lesson.estimatedMinutes))
      ? Number(lesson.estimatedMinutes)
      : 5,
    isActive: lesson.isActive !== false,
    isPreview: lesson.isPreview === true,
    isLocked: accessDecision.granted !== true,
    accessReason: accessDecision.reason || 'access_unresolved',
  };
}

export async function listAuthorizedLessons({
  databases,
  databaseId,
  callerUserId,
  body,
  evaluateAccess,
  onEntitlementError = () => {},
}) {
  if (!databases || typeof evaluateAccess !== 'function') {
    throw new Error('Lesson listing dependencies are unavailable');
  }

  const { categoryId, cursor, limit } = parseListLessonsRequest(body);
  const queries = [Query.orderAsc('order'), Query.limit(limit)];
  if (categoryId) queries.unshift(Query.equal('categoryId', categoryId));
  if (cursor) queries.push(Query.cursorAfter(cursor));

  const [lessonResult, categories] = await Promise.all([
    databases.listDocuments(databaseId, 'lessons', queries),
    loadCategoryMap({ databases, databaseId, categoryId }),
  ]);
  const lessonDocuments = Array.isArray(lessonResult.documents)
    ? lessonResult.documents
    : [];

  let purchasesByCategory = new Map();
  if (callerUserId) {
    try {
      purchasesByCategory = await loadPurchasesByCategory({
        databases,
        databaseId,
        callerUserId,
      });
    } catch (_) {
      onEntitlementError();
      purchasesByCategory = new Map();
    }
  }

  const lessons = lessonDocuments.map((lesson) => {
    const lessonCategoryId = documentId(lesson.categoryId);
    const accessDecision = evaluateAccess({
      category: categories.get(lessonCategoryId) || null,
      lesson,
      callerUserId,
      purchases: purchasesByCategory.get(lessonCategoryId) || [],
    });
    return toLessonListMetadata(lesson, accessDecision);
  });

  const hasMore = lessonDocuments.length === limit;
  const nextCursor = hasMore ? documentId(lessonDocuments.at(-1)) || null : null;
  return {
    lessons,
    hasMore: Boolean(hasMore && nextCursor),
    nextCursor,
  };
}
