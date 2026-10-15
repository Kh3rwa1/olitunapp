import { CMS_COLLECTIONS, ID_PATTERN, rowColumns } from './cms_specs';

// One-time carry-over of the legacy D1 blobs (gamification_content 'default'
// and bakhed_content) into cms_rows. Learner routes only fall back to a blob
// while cms_rows has nothing for that collection, so the first admin save
// would otherwise hide every legacy entry. Admin list reads call this before
// listing an empty collection, so admins edit the content learners see.

const GAMIFICATION_BLOB_KEYS: Record<string, string> = {
  bravo_messages: 'bravoMessages',
  badges: 'badges',
  mission_templates: 'missionTemplates',
  reward_messages: 'rewardMessages',
  quiz_feedback_messages: 'quizFeedbackMessages',
};

const BAKHED_BLOB_KEYS: Record<string, string> = {
  bakhed_lyrics: 'lyrics',
  bakhed_vocabulary: 'vocabulary',
  bakhed_cultural_notes: 'culturalNotes',
};

function parse(text: unknown): any {
  if (typeof text !== 'string' || !text) return null;
  try {
    return JSON.parse(text);
  } catch {
    return null;
  }
}

function legacyItems(collection: string, blob: any, bakhedId: string): Record<string, any>[] {
  if (!blob || typeof blob !== 'object') return [];
  if (collection === 'gamification_config') {
    return blob.config && typeof blob.config === 'object' && Object.keys(blob.config).length > 0
      ? [{ configId: 'default', ...blob.config }]
      : [];
  }
  const key = GAMIFICATION_BLOB_KEYS[collection] || BAKHED_BLOB_KEYS[collection];
  const list = key ? blob[key] : null;
  if (!Array.isArray(list)) return [];
  return list
    .filter((item) => item && typeof item === 'object' && !Array.isArray(item))
    .map((item) => (bakhedId ? { ...item, bakhedId } : { ...item }));
}

/// Seeds cms_rows for [collection] (scoped to [bakhedId] for Bakhed
/// children) from the legacy blob when it has no rows yet. Idempotent:
/// INSERT OR IGNORE, and a no-op once any row exists. Returns rows added.
export async function importLegacyIfEmpty(
  db: D1Database,
  collection: string,
  bakhedId: string,
  adminId: string,
): Promise<number> {
  const spec = CMS_COLLECTIONS[collection];
  if (!spec) return 0;
  const isChild = Boolean(spec.bakhedChild);
  if (isChild && !bakhedId) return 0;

  const existing = isChild
    ? await db.prepare('SELECT 1 FROM cms_rows WHERE collection = ? AND parent_id = ? LIMIT 1').bind(collection, bakhedId).first()
    : await db.prepare('SELECT 1 FROM cms_rows WHERE collection = ? LIMIT 1').bind(collection).first();
  if (existing) return 0;

  const blobRow: any = isChild
    ? await db.prepare('SELECT raw_json FROM bakhed_content WHERE bakhed_id = ?').bind(bakhedId).first()
    : await db.prepare('SELECT raw_json FROM gamification_content WHERE id = ?').bind('default').first();
  const items = legacyItems(collection, parse(blobRow?.raw_json), isChild ? bakhedId : '');
  if (items.length === 0) return 0;

  const now = new Date().toISOString();
  const statements: D1PreparedStatement[] = [];
  items.forEach((item, index) => {
    const candidate = String((spec.idField && item[spec.idField]) || item.id || item.$id || '');
    const id = ID_PATTERN.test(candidate) ? candidate : `${isChild ? bakhedId : collection}_legacy_${index}`;
    const doc: Record<string, any> = { ...item };
    delete doc.id;
    for (const key of Object.keys(doc)) if (key.startsWith('$')) delete doc[key];
    if (spec.idField) doc[spec.idField] = id;
    const cols = rowColumns(collection, spec, doc);
    statements.push(db.prepare(
      `INSERT OR IGNORE INTO cms_rows (collection, id, parent_id, order_index, status, is_active, raw_json, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
    ).bind(collection, id, cols.parentId, cols.orderIndex, cols.status, cols.isActive, JSON.stringify(doc), now));
  });
  statements.push(db.prepare(
    'INSERT INTO admin_audit_logs (id, admin_user_id, action, target_id, details_json, timestamp) VALUES (?, ?, ?, ?, ?, ?)'
  ).bind(
    crypto.randomUUID(), adminId, `${collection}_legacy_import`, isChild ? bakhedId : collection,
    JSON.stringify({ collection, rows: items.length }), now,
  ));
  await db.batch(statements);
  return items.length;
}
