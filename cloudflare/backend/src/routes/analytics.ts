import { optionalUser } from '../auth';
import { getRequestUserId, stableId, type App } from '../env';

// Learner analytics ingest (replaces direct client writes to the Appwrite
// learning_analytics_events collection). Guests may log; the user id comes
// only from the verified JWT, never from the payload.

const MAX_BODY_BYTES = 64 * 1024;
const MAX_BATCH = 50;
const MAX_METADATA_CHARS = 4096;
const RETENTION_DAYS = 90;
const FUTURE_SKEW_MS = 24 * 60 * 60 * 1000;

const EVENT_NAME = /^[a-z][a-z0-9_]{1,63}$/;
const EVENT_ID = /^[A-Za-z0-9][A-Za-z0-9._-]{0,35}$/;

type IngestEvent = {
  eventId: string;
  eventName: string;
  sourceId: string | null;
  source: string | null;
  sessionId: string | null;
  learnerLevel: string | null;
  scriptMode: string | null;
  platform: string | null;
  eventVersion: number;
  occurredAt: string;
  dateKey: string;
  metadata: string | null;
};

function optionalText(value: unknown, max: number, field: string): string | null {
  if (value === undefined || value === null) return null;
  if (typeof value !== 'string') throw new Error(`${field} must be a string`);
  const trimmed = value.trim();
  if (trimmed.length > max) throw new Error(`${field} exceeds ${max} characters`);
  return trimmed === '' ? null : trimmed;
}

// Clients queue events offline, so occurredAt can be days old. Anything
// outside the retention window (or in the future) is stamped with server time
// rather than rejected, so it cannot poison the client's retry queue.
function resolveTimestamp(value: unknown, now: number): string {
  if (typeof value === 'string' && value.length <= 40) {
    const parsed = Date.parse(value);
    if (
      !Number.isNaN(parsed) &&
      parsed <= now + FUTURE_SKEW_MS &&
      parsed >= now - RETENTION_DAYS * 86400 * 1000
    ) {
      return new Date(parsed).toISOString();
    }
  }
  return new Date(now).toISOString();
}

export function validateEvent(raw: unknown, now: number): IngestEvent {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) throw new Error('event must be an object');
  const e = raw as Record<string, unknown>;

  const eventId = typeof e.eventId === 'string' ? e.eventId.trim() : '';
  if (!EVENT_ID.test(eventId)) throw new Error('eventId is invalid');

  const eventName = typeof e.eventName === 'string' ? e.eventName.trim() : '';
  if (!EVENT_NAME.test(eventName)) throw new Error('eventName is invalid');

  let metadata: string | null = null;
  if (typeof e.metadata === 'string') {
    metadata = e.metadata;
  } else if (e.metadata && typeof e.metadata === 'object') {
    metadata = JSON.stringify(e.metadata);
  } else if (e.metadata !== undefined && e.metadata !== null) {
    throw new Error('metadata must be an object or JSON string');
  }
  if (metadata !== null && metadata.length > MAX_METADATA_CHARS) {
    throw new Error(`metadata exceeds ${MAX_METADATA_CHARS} characters`);
  }

  const version = e.eventVersion === undefined ? 1 : e.eventVersion;
  if (typeof version !== 'number' || !Number.isInteger(version) || version < 1 || version > 1000) {
    throw new Error('eventVersion is invalid');
  }

  const occurredAt = resolveTimestamp(e.occurredAt, now);
  return {
    eventId,
    eventName,
    sourceId: optionalText(e.sourceId, 120, 'sourceId'),
    source: optionalText(e.source, 80, 'source'),
    sessionId: optionalText(e.sessionId, 64, 'sessionId'),
    learnerLevel: optionalText(e.learnerLevel, 40, 'learnerLevel'),
    scriptMode: optionalText(e.scriptMode, 40, 'scriptMode'),
    platform: optionalText(e.platform, 20, 'platform'),
    eventVersion: version,
    occurredAt,
    dateKey: occurredAt.slice(0, 10),
    metadata,
  };
}

export function registerAnalyticsRoutes(app: App): void {
  app.post('/api/v1/analytics/events', optionalUser, async (c) => {
    const limiter = c.env.ANALYTICS_LIMITER;
    if (!limiter) {
      return c.json({ ok: false, error: 'UNAVAILABLE', message: 'Analytics ingest is not configured' }, 503);
    }

    const userId = getRequestUserId(c);
    const ip = c.req.header('cf-connecting-ip') || 'unknown';
    const { success } = await limiter.limit({ key: userId ? `user:${userId}` : `ip:${ip}` });
    if (!success) {
      return c.json({ ok: false, error: 'RATE_LIMITED', message: 'Too many analytics events' }, 429);
    }

    const declared = Number(c.req.header('content-length') || '0');
    if (declared > MAX_BODY_BYTES) {
      return c.json({ ok: false, error: 'PAYLOAD_TOO_LARGE', message: 'Batch too large' }, 413);
    }
    const text = await c.req.text();
    if (text.length > MAX_BODY_BYTES) {
      return c.json({ ok: false, error: 'PAYLOAD_TOO_LARGE', message: 'Batch too large' }, 413);
    }

    let body: any;
    try {
      body = JSON.parse(text);
    } catch (_) {
      return c.json({ ok: false, error: 'INVALID_BATCH', message: 'Body must be JSON' }, 400);
    }
    const rawEvents = body?.events;
    if (!Array.isArray(rawEvents) || rawEvents.length === 0 || rawEvents.length > MAX_BATCH) {
      return c.json({ ok: false, error: 'INVALID_BATCH', message: `events must be an array of 1-${MAX_BATCH} items` }, 400);
    }

    const now = Date.now();
    const events: IngestEvent[] = [];
    const errors: Array<{ index: number; message: string }> = [];
    rawEvents.forEach((raw: unknown, index: number) => {
      try {
        events.push(validateEvent(raw, now));
      } catch (err: any) {
        errors.push({ index, message: err.message });
      }
    });
    if (errors.length > 0) {
      return c.json({ ok: false, error: 'INVALID_BATCH', message: 'Invalid events', errors }, 400);
    }

    // Row ids are scoped to the caller, so client retries are idempotent and
    // one caller cannot pre-claim another's event ids.
    const createdAt = new Date(now).toISOString();
    const statements: D1PreparedStatement[] = [];
    for (const event of events) {
      const rowId = await stableId(`analytics:${userId}:${event.eventId}`);
      statements.push(
        c.env.DB.prepare(
          'INSERT OR IGNORE INTO learning_analytics_events (id, user_id, event_name, date_key, source_id, occurred_at, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)'
        ).bind(rowId, userId, event.eventName, event.dateKey, event.sourceId, event.occurredAt, createdAt),
        c.env.DB.prepare(
          'INSERT OR IGNORE INTO learning_analytics_event_details (event_id, user_id, date_key, session_id, source, learner_level, script_mode, platform, event_version, metadata_json) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
        ).bind(rowId, userId, event.dateKey, event.sessionId, event.source, event.learnerLevel, event.scriptMode, event.platform, event.eventVersion, event.metadata),
      );
    }

    try {
      await c.env.DB.batch(statements);
    } catch (err: any) {
      console.error(`analytics ingest failed: ${err?.message || err}`);
      return c.json({ ok: false, error: 'WRITE_FAILED', message: 'Could not record events' }, 500);
    }
    return c.json({ ok: true, accepted: events.length });
  });
}
