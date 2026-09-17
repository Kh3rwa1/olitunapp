/**
 * Shared Review States Table & Schema Contract
 *
 * Single source of truth for:
 * - Table specifications, permissions, and row security
 * - Column types, sizes, and constraints
 * - Index definitions
 * - Function request validation limits and semantics
 */

export const REVIEW_TABLE_SPEC = {
  id: 'review_states',
  name: 'Review States',
  permissions: [],
  rowSecurity: true,
};

export const REVIEW_COLUMNS_SPEC = [
  { key: 'userId', type: 'string', size: 80, required: true },
  { key: 'itemId', type: 'string', size: 120, required: true },
  { key: 'itemType', type: 'enum', elements: ['word', 'sentence'], required: true },
  { key: 'stateJson', type: 'string', size: 8192, required: true },
  { key: 'nextReviewAt', type: 'datetime', required: true },
  { key: 'lastReviewedAt', type: 'datetime', required: false },
  { key: 'schemaVersion', type: 'integer', required: false, default: 3 },
];

export const REVIEW_INDEXES_SPEC = [
  {
    key: 'idx_user_nextReview',
    type: 'key',
    columns: ['userId', 'nextReviewAt'],
    orders: ['ASC', 'ASC'],
  },
  {
    key: 'idx_user_lastReviewed',
    type: 'key',
    columns: ['userId', 'lastReviewedAt'],
    orders: ['ASC', 'DESC'],
  },
];

export const REVIEW_SCHEMA_LIMITS = {
  USER_ID_MAX_LENGTH: 80,
  ITEM_ID_MAX_LENGTH: 120,
  /**
   * Conservative UTF-8 byte length semantics matching the Appwrite string column size limit of 8192.
   * Evaluated via Buffer.byteLength(stateJsonStr, 'utf8') <= 8192.
   * Guaranteed to never accept a payload exceeding backend string byte constraints.
   */
  STATE_JSON_MAX_BYTES: 8192,
  STATE_JSON_MAX_LENGTH: 8192,
  ITEM_TYPES: Object.freeze(['word', 'sentence']),
  EXERCISE_TYPES: Object.freeze(['recognition', 'typing', 'listening', 'sentence']),
  SUPPORTED_SCHEMA_VERSIONS: Object.freeze([1, 2, 3]),
  DEFAULT_SCHEMA_VERSION: 3,
  OPERATION_ID_MAX_LENGTH: 128,
  DEVICE_ID_MAX_LENGTH: 128,
  RESPONSE_TIME_MAX_MS: 3600000,
};

/**
 * Idempotent recall-operation ledger. One row per (user, operationId):
 * duplicate deliveries return `{ok:true, duplicate:true}` without
 * re-applying the recall. Rows are user-owned (same deletion/retention
 * policy as `review_states`) and never store learning text — only
 * counters, timestamps and opaque ids.
 */
export const REVIEW_OPERATIONS_TABLE_SPEC = {
  id: 'review_operations',
  name: 'Review Operations',
  permissions: [],
  rowSecurity: true,
};

export const REVIEW_OPERATIONS_COLUMNS_SPEC = [
  { key: 'userId', type: 'string', size: 80, required: true },
  { key: 'operationId', type: 'string', size: 128, required: true },
  { key: 'itemId', type: 'string', size: 120, required: true },
  { key: 'occurredAt', type: 'datetime', required: true },
  { key: 'appliedAt', type: 'datetime', required: true },
];

export const REVIEW_OPERATIONS_INDEXES_SPEC = [
  {
    key: 'idx_ops_user_item',
    type: 'key',
    columns: ['userId', 'itemId'],
    orders: ['ASC', 'ASC'],
  },
  {
    key: 'idx_ops_user_occurred',
    type: 'key',
    columns: ['userId', 'occurredAt'],
    orders: ['ASC', 'ASC'],
  },
];
