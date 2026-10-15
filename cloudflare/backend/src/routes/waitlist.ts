import { optionalUser, requireUser } from '../auth';
import { getRequestUserId, stableId, type App } from '../env';

// Binti / ceremony waitlist (replaces the Appwrite bintiWaitlist function and
// direct reads of the binti_guru_waitlist collection). Validation and dedupe
// rules mirror functions/bintiWaitlist/src/main.js.

const ALLOWED_CEREMONY_TYPES = new Set(['wedding', 'karam', 'sohrai', 'baha', 'naming', 'funeral', 'other']);
const PHONE_PATTERN = /^\+?[0-9][0-9\s-]{6,19}$/;
const MAX_EVENT_LEAD_MS = 366 * 24 * 60 * 60 * 1000;

const COLUMNS =
  'id, user_id, full_name, phone_number, ceremony_type, city, state, event_date, notes, submitted_at, status';

type WaitlistEntry = {
  fullName: string;
  phoneNumber: string;
  ceremonyType: string;
  city: string;
  state: string;
  eventDate: string | null;
  notes: string | null;
};

export function validateWaitlistInput(body: any): { ok: true; entry: WaitlistEntry } | { ok: false; errors: string[] } {
  const errors: string[] = [];

  const fullName = String(body?.fullName ?? '').trim();
  if (fullName.length < 2 || fullName.length > 100) {
    errors.push('fullName must be between 2 and 100 characters.');
  }

  const phoneNumber = String(body?.phoneNumber ?? '').trim();
  if (!PHONE_PATTERN.test(phoneNumber) || phoneNumber.length > 20) {
    errors.push('phoneNumber must be 7-20 digits (a leading + and spaces/dashes are allowed).');
  }

  const ceremonyType = String(body?.ceremonyType ?? '').trim().toLowerCase();
  if (!ALLOWED_CEREMONY_TYPES.has(ceremonyType)) {
    errors.push(`ceremonyType must be one of: ${[...ALLOWED_CEREMONY_TYPES].join(', ')}.`);
  }

  const city = String(body?.city ?? '').trim();
  if (city.length < 2 || city.length > 100) {
    errors.push('city must be between 2 and 100 characters.');
  }

  const state = String(body?.state ?? '').trim();
  if (state.length < 2 || state.length > 100) {
    errors.push('state must be between 2 and 100 characters.');
  }

  let eventDate: string | null = null;
  if (body?.eventDate != null && String(body.eventDate).trim() !== '') {
    const parsed = new Date(String(body.eventDate).trim());
    if (Number.isNaN(parsed.getTime()) || parsed.getTime() > Date.now() + MAX_EVENT_LEAD_MS) {
      errors.push('eventDate must be a valid date no further than one year out.');
    } else {
      eventDate = parsed.toISOString();
    }
  }

  let notes: string | null = null;
  if (body?.notes != null && String(body.notes).trim() !== '') {
    notes = String(body.notes).trim().slice(0, 1000);
  }

  if (errors.length > 0) return { ok: false, errors };
  return { ok: true, entry: { fullName, phoneNumber, ceremonyType, city, state, eventDate, notes } };
}

function toEntry(row: any) {
  return {
    id: row.id,
    userId: row.user_id || null,
    fullName: row.full_name,
    phoneNumber: row.phone_number,
    ceremonyType: row.ceremony_type,
    city: row.city,
    state: row.state,
    eventDate: row.event_date || null,
    notes: row.notes || null,
    submittedAt: row.submitted_at,
    status: row.status,
  };
}

const ADMIN_STATUSES = new Set(['new', 'contacted', 'converted', 'closed']);
const ADMIN_LIST_LIMIT = 1000;

export function registerWaitlistRoutes(app: App): void {
  // Admin view of the same D1 records learners submit to. Admin-team
  // membership is enforced by the /api/v1/admin/* middleware in index.ts.
  app.get('/api/v1/admin/waitlist', async (c) => {
    try {
      const rows: any = await c.env.DB.prepare(
        'SELECT * FROM binti_waitlist ORDER BY submitted_at DESC LIMIT ?'
      ).bind(ADMIN_LIST_LIMIT).all();
      return c.json({ ok: true, entries: (rows.results || []).map(toEntry) });
    } catch (err: any) {
      console.error(`admin waitlist list failed: ${err?.message || err}`);
      return c.json({ ok: false, message: 'Failed to load waitlist' }, 500);
    }
  });

  app.post('/api/v1/admin/waitlist/:id/status', async (c) => {
    const id = c.req.param('id').trim();
    const body: any = await c.req.json().catch(() => ({}));
    const status = String(body?.status || '').trim();
    if (!id || !ADMIN_STATUSES.has(status)) {
      return c.json({ ok: false, message: 'Invalid waitlist id or status' }, 400);
    }
    try {
      const result = await c.env.DB.prepare('UPDATE binti_waitlist SET status = ? WHERE id = ?')
        .bind(status, id).run();
      if (!result.meta?.changes) return c.json({ ok: false, message: 'Waitlist entry not found' }, 404);
      return c.json({ ok: true, id, status });
    } catch (err: any) {
      console.error(`admin waitlist update failed: ${err?.message || err}`);
      return c.json({ ok: false, message: 'Failed to update waitlist' }, 500);
    }
  });

  app.post('/api/v1/waitlist/join', optionalUser, async (c) => {
    const limiter = c.env.WAITLIST_LIMITER;
    if (!limiter) {
      return c.json({ ok: false, message: 'Waitlist is temporarily unavailable.' }, 503);
    }

    const userId = getRequestUserId(c);
    const ip = c.req.header('cf-connecting-ip') || 'unknown';
    // Keys are hashed so raw ids / IPs never reach the limiter.
    const callerKey = await stableId(userId ? `waitlist:user:${userId}` : `waitlist:ip:${ip}`);
    if (!(await limiter.limit({ key: callerKey })).success) {
      return c.json({ ok: false, message: 'Too many waitlist requests. Please try again later.' }, 429);
    }

    const body = await c.req.json().catch(() => null);
    if (!body || typeof body !== 'object') {
      return c.json({ ok: false, message: 'Invalid request body.' }, 400);
    }
    const validation = validateWaitlistInput(body);
    if (!validation.ok) {
      return c.json({ ok: false, message: 'Invalid submission.', errors: validation.errors }, 400);
    }
    const entry = validation.entry;

    const phoneKey = await stableId(`waitlist:phone:${entry.phoneNumber}`);
    if (!(await limiter.limit({ key: phoneKey })).success) {
      return c.json({ ok: false, message: 'This number has too many pending requests. Please try again later.' }, 429);
    }

    try {
      const existing: any = await c.env.DB.prepare(
        `SELECT ${COLUMNS} FROM binti_waitlist WHERE phone_number = ? AND ceremony_type = ? AND status = 'new' LIMIT 1`
      ).bind(entry.phoneNumber, entry.ceremonyType).first();

      if (existing) {
        // Only the owner sees the stored entry; anyone else who knows the
        // phone number gets back what they submitted, never stored PII.
        const mine = Boolean(userId) && existing.user_id === userId;
        return c.json({
          ok: true,
          duplicate: true,
          entry: mine
            ? toEntry(existing)
            : { ...entry, id: existing.id, userId: userId || null, submittedAt: existing.submitted_at, status: existing.status },
        });
      }

      const now = new Date().toISOString();
      const id = crypto.randomUUID();
      await c.env.DB.prepare(
        `INSERT INTO binti_waitlist (${COLUMNS}) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
      ).bind(
        id, userId || null, entry.fullName, entry.phoneNumber, entry.ceremonyType,
        entry.city, entry.state, entry.eventDate, entry.notes, now, 'new',
      ).run();

      return c.json({
        ok: true,
        duplicate: false,
        entry: { id, userId: userId || null, ...entry, submittedAt: now, status: 'new' },
      });
    } catch (err: any) {
      console.error(`waitlist join failed: ${err?.message || err}`);
      return c.json({ ok: false, message: 'Waitlist submission failed. Please try again later.' }, 500);
    }
  });

  // The signed-in user's own entries, newest first.
  app.get('/api/v1/waitlist/mine', requireUser, async (c) => {
    const userId = getRequestUserId(c);
    try {
      const rows = await c.env.DB.prepare(
        `SELECT ${COLUMNS} FROM binti_waitlist WHERE user_id = ? ORDER BY submitted_at DESC LIMIT 100`
      ).bind(userId).all();
      return c.json({ ok: true, entries: (rows.results || []).map(toEntry) });
    } catch (err: any) {
      console.error(`waitlist mine failed: ${err?.message || err}`);
      return c.json({ ok: false, message: 'Could not load waitlist entries.' }, 500);
    }
  });
}
