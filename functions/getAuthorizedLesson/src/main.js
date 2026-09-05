import { Client, Databases, Query, Storage } from 'node-appwrite';

const PAID_UNLOCK_MODES = new Set([
  'paid_only',
  'review_or_paid',
  'review_only',
]);

function parseBody(req) {
  if (typeof req.body === 'object' && req.body !== null) {
    return req.body;
  }
  try {
    return JSON.parse(req.body || '{}');
  } catch (_) {
    return {};
  }
}

function text(value, max = 64) {
  return String(value || '').trim().slice(0, max);
}

function parseJsonField(field, defaultValue) {
  if (field === null || field === undefined) return defaultValue;
  if (typeof field === 'object') return field;
  if (typeof field === 'string' && field.trim().length > 0) {
    try {
      return JSON.parse(field);
    } catch (_) {
      return defaultValue;
    }
  }
  return defaultValue;
}

export function evaluateLessonAccess({ category, lesson, callerUserId, purchases = [] }) {
  if (!category) {
    return { granted: false, reason: 'category_unresolved' };
  }

  const mode = typeof category.unlockMode === 'string'
    ? category.unlockMode.trim().toLowerCase()
    : '';

  if (mode === 'free') {
    return { granted: true, reason: 'free_category' };
  }

  // Explicit deterministic preview takes precedence over order number heuristics
  if (lesson.isPreview === true) {
    return { granted: true, reason: 'explicit_preview' };
  }

  // Legacy order-window preview check for backward compatibility
  const order = Number(lesson.order);
  const previews = Number(category.previewLessonCount || 0);
  if (Number.isInteger(order) && order > 0 && previews > 0 && order <= previews) {
    if (PAID_UNLOCK_MODES.has(mode)) {
      return { granted: true, reason: 'legacy_order_window_preview' };
    }
    return { granted: false, reason: `unknown_unlock_mode_${mode}` };
  }

  // If unlockMode is not recognized, fail closed
  if (!PAID_UNLOCK_MODES.has(mode)) {
    return { granted: false, reason: mode ? `unknown_unlock_mode_${mode}` : 'unlock_mode_missing' };
  }

  // Requires purchase: check authenticated caller identity
  if (!callerUserId || typeof callerUserId !== 'string' || callerUserId.trim().length === 0) {
    return { granted: false, reason: 'unauthenticated' };
  }

  // Check verified entitlement in course_purchases ledger
  const validPurchase = purchases.find((doc) => {
    if (doc.status !== 'verified') return false;
    if (doc.status === 'revoked' || doc.status === 'disputed' || doc.status === 'refunded') return false;
    if (doc.refundStatus === 'fully_refunded') return false;
    const expectedPaise = Math.round(Number(doc.expectedAmount || 0) * 100);
    if (expectedPaise > 0 && Number(doc.refundedAmountPaise || 0) >= expectedPaise) return false;
    return true;
  });

  if (validPurchase) {
    return { granted: true, reason: 'entitled' };
  }

  return { granted: false, reason: 'purchase_required' };
}

export function createGetAuthorizedLessonHandler({
  databases: customDatabases,
  storage: customStorage,
} = {}) {
  return async ({ req, res, error = console.error, log = () => {} }) => {
    if (req.method !== 'POST') {
      return res.json({ ok: false, message: 'Method not allowed' }, 405);
    }

    const callerUserId = req.headers['x-appwrite-user-id'] || null;

    const endpoint = process.env.APPWRITE_FUNCTION_API_ENDPOINT || process.env.APPWRITE_ENDPOINT;
    const projectId = process.env.APPWRITE_FUNCTION_PROJECT_ID || process.env.APPWRITE_PROJECT_ID;
    const apiKey = process.env.APPWRITE_FUNCTION_API_KEY || process.env.APPWRITE_API_KEY;
    const databaseId = process.env.APPWRITE_DATABASE_ID || 'olitun_db';
    const paidMediaBucketId = process.env.PAID_MEDIA_BUCKET_ID || 'paid_media';

    let databases = customDatabases;
    let storage = customStorage;

    if (!databases) {
      if (!endpoint || !projectId || !apiKey) {
        error('Missing Appwrite server configuration for getAuthorizedLesson');
        return res.json({ ok: false, message: 'Server misconfiguration' }, 500);
      }
      const client = new Client().setEndpoint(endpoint).setProject(projectId).setKey(apiKey);
      databases = new Databases(client);
      storage = new Storage(client);
    }

    const body = parseBody(req);
    const lessonId = text(body.lessonId, 64);
    const action = text(body.action, 32) || 'get_lesson';

    if (!lessonId) {
      return res.json({ ok: false, message: 'Missing or invalid lessonId' }, 400);
    }

    let lessonDoc;
    try {
      lessonDoc = await databases.getDocument(databaseId, 'lessons', lessonId);
    } catch (err) {
      if (err.code === 404) {
        return res.json({ ok: false, error: 'lesson_not_found', message: 'Lesson not found' }, 404);
      }
      error(`Failed to retrieve lesson ${lessonId}: ${err.message || err}`);
      return res.json({ ok: false, error: 'lesson_retrieval_failed', message: 'Failed to retrieve lesson' }, 500);
    }

    if (!lessonDoc.categoryId) {
      return res.json({
        ok: false,
        locked: true,
        error: 'category_missing',
        message: 'Lesson has no assigned category',
      }, 403);
    }

    let categoryDoc;
    try {
      categoryDoc = await databases.getDocument(databaseId, 'categories', lessonDoc.categoryId);
    } catch (err) {
      log(`Category lookup failed for lesson ${lessonId}: ${err.message || err}`);
      return res.json({
        ok: false,
        locked: true,
        error: 'category_unresolved',
        message: 'Category lookup failed',
      }, 403);
    }

    let purchases = [];
    if (callerUserId) {
      try {
        const purchaseResult = await databases.listDocuments(databaseId, 'course_purchases', [
          Query.equal('userId', callerUserId),
          Query.equal('categoryId', lessonDoc.categoryId),
          Query.limit(10),
        ]);
        purchases = purchaseResult.documents || [];
      } catch (err) {
        error(`Failed to query entitlements for user ${callerUserId}: ${err.message || err}`);
        // Fail closed on database errors reading entitlement ledger
        purchases = [];
      }
    }

    const accessDecision = evaluateLessonAccess({
      category: categoryDoc,
      lesson: lessonDoc,
      callerUserId,
      purchases,
    });

    // Handle media access action
    if (action === 'get_media') {
      if (!accessDecision.granted) {
        return res.json({
          ok: false,
          locked: true,
          error: 'access_denied',
          reason: accessDecision.reason,
        }, 403);
      }

      const fileId = text(body.fileId, 64);
      if (!fileId) {
        return res.json({ ok: false, message: 'Missing or invalid fileId' }, 400);
      }

      try {
        if (!storage) {
          return res.json({ ok: false, message: 'Storage not configured' }, 500);
        }
        const fileBuffer = await storage.getFileDownload(paidMediaBucketId, fileId);
        const base64Data = Buffer.isBuffer(fileBuffer)
          ? fileBuffer.toString('base64')
          : Buffer.from(fileBuffer).toString('base64');
        return res.json({
          ok: true,
          fileId,
          base64: base64Data,
        });
      } catch (err) {
        error(`Failed to fetch media file ${fileId}: ${err.message || err}`);
        return res.json({ ok: false, error: 'media_not_found', message: 'Media file unavailable' }, 404);
      }
    }

    // Default action: lesson payload retrieval
    const parsedData = parseJsonField(lessonDoc.data, null);
    const parsedBlocks = parseJsonField(lessonDoc.blocks, []);

    if (!accessDecision.granted) {
      return res.json({
        ok: true,
        locked: true,
        reason: accessDecision.reason,
        lesson: {
          id: lessonDoc.$id || lessonId,
          categoryId: lessonDoc.categoryId,
          titleOlChiki: lessonDoc.titleOlChiki || '',
          titleLatin: lessonDoc.titleLatin || '',
          level: lessonDoc.level || 'beginner',
          description: lessonDoc.description || '',
          order: Number(lessonDoc.order || 0),
          estimatedMinutes: Number(lessonDoc.estimatedMinutes || 5),
          isActive: lessonDoc.isActive !== false,
          isPreview: lessonDoc.isPreview === true,
          isLocked: true,
          blocks: [], // Content body stripped for locked lessons
        },
      });
    }

    return res.json({
      ok: true,
      locked: false,
      accessReason: accessDecision.reason,
      lesson: {
        id: lessonDoc.$id || lessonId,
        categoryId: lessonDoc.categoryId,
        titleOlChiki: lessonDoc.titleOlChiki || '',
        titleLatin: lessonDoc.titleLatin || '',
        level: lessonDoc.level || 'beginner',
        description: lessonDoc.description || '',
        order: Number(lessonDoc.order || 0),
        estimatedMinutes: Number(lessonDoc.estimatedMinutes || 5),
        isActive: lessonDoc.isActive !== false,
        isPreview: lessonDoc.isPreview === true,
        isLocked: false,
        data: parsedData,
        blocks: Array.isArray(parsedBlocks) ? parsedBlocks : [],
      },
    });
  };
}

export default async (context) => createGetAuthorizedLessonHandler()(context);
