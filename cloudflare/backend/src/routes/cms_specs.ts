// Field specs and validation for the gamification / Bakhed CMS collections
// stored in D1 `cms_rows`. The specs mirror the retired Appwrite collection
// attributes (test/fixtures/schema/*.json) so admin writes keep the same
// guardrails Appwrite enforced.

type FieldSpec =
  | { type: 'string'; required?: boolean; size: number }
  | { type: 'integer'; required?: boolean; min?: number; max?: number }
  | { type: 'boolean'; required?: boolean };

export type CollectionSpec = {
  // Attribute that mirrors the row id (badgeId, messageId, ...). Rows keyed
  // only by `id` (lyrics, vocabulary) leave it undefined.
  idField?: string;
  // Child collections of a Bakhed (rhyme); `bakhedId` is the parent key.
  bakhedChild?: boolean;
  // Field that drives order_index.
  orderField?: string;
  fields: Record<string, FieldSpec>;
};

const str = (size: number, required = false): FieldSpec => ({ type: 'string', size, required });
const int = (min?: number, max?: number, required = false): FieldSpec => ({ type: 'integer', min, max, required });
const bool = (): FieldSpec => ({ type: 'boolean' });

const AUDIT_FIELDS: Record<string, FieldSpec> = {
  version: int(),
  updatedBy: str(100),
  createdAt: str(30),
  updatedAt: str(30),
};

export const CMS_COLLECTIONS: Record<string, CollectionSpec> = {
  badges: {
    idField: 'badgeId',
    orderField: 'sortOrder',
    fields: {
      badgeId: str(100, true),
      name: str(255, true),
      description: str(2048, true),
      category: str(40),
      icon: str(20),
      target: int(1, 10000),
      rewardStars: int(0, 100),
      unlockRule: str(4096),
      status: str(20),
      isActive: bool(),
      sortOrder: int(),
      ...AUDIT_FIELDS,
    },
  },
  bravo_messages: {
    idField: 'messageId',
    orderField: 'weight',
    fields: {
      messageId: str(100, true),
      trigger: str(80, true),
      title: str(255, true),
      body: str(2048, true),
      language: str(20),
      scriptMode: str(20),
      learnerLevel: str(20),
      weight: int(0, 100),
      status: str(20),
      isActive: bool(),
      startsAt: str(30),
      endsAt: str(30),
      ...AUDIT_FIELDS,
    },
  },
  mission_templates: {
    idField: 'missionId',
    orderField: 'sortOrder',
    fields: {
      missionId: str(100, true),
      title: str(255, true),
      description: str(2048, true),
      type: str(60, true),
      targetCount: int(1, 10),
      rewardStars: int(0, 100),
      circlePoints: int(0, 100),
      learnerLevel: str(20),
      isQuickWin: bool(),
      status: str(20),
      isActive: bool(),
      sortOrder: int(),
      ...AUDIT_FIELDS,
    },
  },
  reward_messages: {
    idField: 'messageId',
    fields: {
      messageId: str(100, true),
      trigger: str(80, true),
      title: str(255, true),
      body: str(2048, true),
      rewardLabel: str(255),
      icon: str(20),
      status: str(20),
      isActive: bool(),
      ...AUDIT_FIELDS,
    },
  },
  quiz_feedback_messages: {
    idField: 'messageId',
    fields: {
      messageId: str(100, true),
      type: str(50, true),
      title: str(255, true),
      body: str(2048, true),
      status: str(20),
      isActive: bool(),
      ...AUDIT_FIELDS,
    },
  },
  gamification_config: {
    idField: 'configId',
    fields: {
      configId: str(40, true),
      weeklyCircleMaxMembers: int(1, 50),
      weeklyCircleMinActiveMembers: int(1, 50),
      bakhedCompletionThreshold: int(50, 95),
      streakShieldMax: int(0, 5),
      quickWinEnabled: bool(),
      weeklyCircleEnabled: bool(),
      badgesEnabled: bool(),
      mistakeReviewEnabled: bool(),
      ...AUDIT_FIELDS,
    },
  },
  bakhed_lyrics: {
    bakhedChild: true,
    orderField: 'lineIndex',
    fields: {
      bakhedId: str(100, true),
      lineIndex: int(0, undefined, true),
      startMs: int(0),
      endMs: int(0),
      olChiki: str(2048),
      latin: str(2048),
      meaning: str(2048),
      ...AUDIT_FIELDS,
    },
  },
  bakhed_vocabulary: {
    bakhedChild: true,
    orderField: 'sortOrder',
    fields: {
      bakhedId: str(100, true),
      olChiki: str(255),
      latin: str(255),
      meaning: str(2048),
      audioFileId: str(100),
      sortOrder: int(),
      ...AUDIT_FIELDS,
    },
  },
  bakhed_cultural_notes: {
    idField: 'noteId',
    bakhedChild: true,
    fields: {
      noteId: str(100, true),
      bakhedId: str(100, true),
      title: str(255, true),
      body: str(10000, true),
      source: str(2048),
      isPublished: bool(),
      ...AUDIT_FIELDS,
    },
  },
};

export const BAKHED_CHILD_COLLECTIONS = ['bakhed_lyrics', 'bakhed_vocabulary', 'bakhed_cultural_notes'] as const;

export const CMS_STATUSES = new Set(['draft', 'published', 'archived']);

// Row ids: Appwrite-style ids plus the readable ids the admin UI generates.
export const ID_PATTERN = /^[A-Za-z0-9][A-Za-z0-9_.:-]{0,127}$/;

export const MAX_ROW_BYTES = 32 * 1024;

function coerce(spec: FieldSpec, value: unknown): unknown {
  if (value === null || value === undefined) return null;
  if (spec.type === 'integer') {
    if (typeof value === 'string') {
      const trimmed = value.trim();
      if (trimmed === '') return null;
      return /^-?\d+$/.test(trimmed) ? Number(trimmed) : value;
    }
    return value;
  }
  if (spec.type === 'boolean' && typeof value === 'string') {
    const lowered = value.trim().toLowerCase();
    if (lowered === 'true') return true;
    if (lowered === 'false') return false;
    if (lowered === '') return null;
  }
  return value;
}

/// Merges [patch] into [existing] (Appwrite updateDocument semantics: absent
/// keys keep their value, null removes an optional one) and validates the
/// result against the collection spec. Returns the cleaned document.
export function mergeAndValidate(
  spec: CollectionSpec,
  id: string,
  existing: Record<string, unknown> | null,
  patch: Record<string, unknown>,
): { ok: true; doc: Record<string, unknown> } | { ok: false; errors: string[] } {
  const errors: string[] = [];
  const doc: Record<string, unknown> = { ...(existing || {}) };
  delete doc.id;

  for (const [key, raw] of Object.entries(patch)) {
    // Transport/meta keys are owned by the Worker.
    if (key === 'id' || key.startsWith('$')) continue;
    const fieldSpec = spec.fields[key];
    if (!fieldSpec) {
      errors.push(`Unknown field "${key}".`);
      continue;
    }
    const value = coerce(fieldSpec, raw);
    if (value === null) {
      delete doc[key];
    } else {
      doc[key] = value;
    }
  }

  if (spec.idField) {
    const given = doc[spec.idField];
    if (given !== undefined && given !== id) {
      errors.push(`${spec.idField} must match the row id.`);
    }
    doc[spec.idField] = id;
  }

  for (const [key, fieldSpec] of Object.entries(spec.fields)) {
    const value = doc[key];
    if (value === undefined) {
      if (fieldSpec.required) errors.push(`${key} is required.`);
      continue;
    }
    if (fieldSpec.type === 'string') {
      if (typeof value !== 'string') errors.push(`${key} must be a string.`);
      else if (value.length > fieldSpec.size) errors.push(`${key} must be at most ${fieldSpec.size} characters.`);
      else if (fieldSpec.required && value.trim() === '') errors.push(`${key} must not be empty.`);
    } else if (fieldSpec.type === 'integer') {
      if (typeof value !== 'number' || !Number.isSafeInteger(value)) errors.push(`${key} must be an integer.`);
      else if (fieldSpec.min !== undefined && value < fieldSpec.min) errors.push(`${key} must be >= ${fieldSpec.min}.`);
      else if (fieldSpec.max !== undefined && value > fieldSpec.max) errors.push(`${key} must be <= ${fieldSpec.max}.`);
    } else if (typeof value !== 'boolean') {
      errors.push(`${key} must be true or false.`);
    }
  }

  if (typeof doc.status === 'string' && !CMS_STATUSES.has(doc.status)) {
    errors.push(`status must be one of: ${[...CMS_STATUSES].join(', ')}.`);
  }
  if (spec.bakhedChild && typeof doc.bakhedId === 'string' && !ID_PATTERN.test(doc.bakhedId)) {
    errors.push('bakhedId is not a valid id.');
  }
  if (JSON.stringify(doc).length > MAX_ROW_BYTES) {
    errors.push(`Row must be smaller than ${MAX_ROW_BYTES} bytes.`);
  }

  return errors.length > 0 ? { ok: false, errors } : { ok: true, doc };
}

/// Derived columns stored next to raw_json so learner reads can filter and
/// order without parsing every row.
export function rowColumns(collection: string, spec: CollectionSpec, doc: Record<string, unknown>) {
  let status: string;
  let isActive: boolean;
  if (collection === 'bakhed_cultural_notes') {
    isActive = doc.isPublished === true;
    status = isActive ? 'published' : 'draft';
  } else if (typeof doc.status === 'string') {
    status = doc.status;
    isActive = doc.isActive !== false;
  } else {
    // Collections without an editorial status (lyrics, vocabulary, config)
    // are live as soon as they are saved.
    status = 'published';
    isActive = doc.isActive !== false;
  }
  const orderValue = spec.orderField ? doc[spec.orderField] : undefined;
  return {
    status,
    isActive: isActive ? 1 : 0,
    orderIndex: typeof orderValue === 'number' ? orderValue : 0,
    parentId: spec.bakhedChild && typeof doc.bakhedId === 'string' ? doc.bakhedId : null,
  };
}
