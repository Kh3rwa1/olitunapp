import { createHmac } from 'crypto';
import { Client, Databases, ID, Query } from 'node-appwrite';
import { checkRateLimit } from './shared/rate_limiter.js';

export const DATABASE_ID =
  process.env.APPWRITE_DATABASE_ID ||
  process.env.OLITUN_APPWRITE_DATABASE_ID ||
  'olitun_db';
export const WAITLIST_COLLECTION = 'binti_guru_waitlist';

const ALLOWED_CEREMONY_TYPES = new Set([
  'wedding',
  'karam',
  'sohrai',
  'baha',
  'naming',
  'funeral',
  'other',
]);

const PHONE_PATTERN = /^\+?[0-9][0-9\s-]{6,19}$/;

/**
 * Validates and sanitizes a waitlist submission. Returns the server-owned
 * document payload, or a list of human-readable field errors.
 *
 * Client-supplied `id`, `userId`, `submittedAt`, `status`, and `contactedAt`
 * are always ignored: the server owns identity, ordering, and lifecycle.
 */
export function validateWaitlistInput(body) {
  const errors = [];

  const fullName = String(body.fullName || '').trim();
  if (fullName.length < 2 || fullName.length > 100) {
    errors.push('fullName must be between 2 and 100 characters.');
  }

  const phoneNumber = String(body.phoneNumber || '').trim();
  if (!PHONE_PATTERN.test(phoneNumber) || phoneNumber.length > 20) {
    errors.push('phoneNumber must be 7-20 digits (a leading + and spaces/dashes are allowed).');
  }

  const ceremonyType = String(body.ceremonyType || '')
    .trim()
    .toLowerCase();
  if (!ALLOWED_CEREMONY_TYPES.has(ceremonyType)) {
    errors.push(
      `ceremonyType must be one of: ${[...ALLOWED_CEREMONY_TYPES].join(', ')}.`,
    );
  }

  const city = String(body.city || '').trim();
  if (city.length < 2 || city.length > 100) {
    errors.push('city must be between 2 and 100 characters.');
  }

  const state = String(body.state || '').trim();
  if (state.length < 2 || state.length > 100) {
    errors.push('state must be between 2 and 100 characters.');
  }

  let eventDate = null;
  if (body.eventDate != null && String(body.eventDate).trim() !== '') {
    const parsed = new Date(String(body.eventDate).trim());
    if (Number.isNaN(parsed.getTime()) || parsed.getTime() > Date.now() + 366 * 24 * 60 * 60 * 1000) {
      errors.push('eventDate must be a valid date no further than one year out.');
    } else {
      eventDate = parsed.toISOString();
    }
  }

  let notes = null;
  if (body.notes != null && String(body.notes).trim() !== '') {
    notes = String(body.notes).trim().slice(0, 1000);
  }

  if (errors.length > 0) {
    return { ok: false, errors };
  }

  return {
    ok: true,
    entry: { fullName, phoneNumber, ceremonyType, city, state, eventDate, notes },
  };
}

function hmacIdentifier(domain, message, salt) {
  return createHmac('sha256', salt).update(`${domain}:${message}`).digest('hex').slice(0, 32);
}

/**
 * Rate-limit identifier for the caller: verified user id (server-injected by
 * the Appwrite runtime for authenticated executions) when available, otherwise
 * a privacy-hashed network identifier. Never stores raw IPs or user ids.
 */
export function deriveCallerIdentifier({ userId, clientIp, env = process.env }) {
  const salt = env.RATE_LIMIT_SALT || 'olitun-dev-salt-do-not-use-in-production';
  if (userId && typeof userId === 'string' && userId.trim() !== '') {
    return `wusr_${hmacIdentifier('waitlist:v1:user', userId.trim(), salt)}`;
  }
  const normalizedIp = String(clientIp || 'unknown').trim().split(',')[0].trim();
  return `wnet_${hmacIdentifier('waitlist:v1:network', normalizedIp, salt)}`;
}

/** Rate-limit identifier for the requested phone number (anti flood-across-IPs). */
export function derivePhoneIdentifier({ phoneNumber, env = process.env }) {
  const salt = env.RATE_LIMIT_SALT || 'olitun-dev-salt-do-not-use-in-production';
  return `wph_${hmacIdentifier('waitlist:v1:phone', String(phoneNumber || '').trim(), salt)}`;
}

export function appwriteClient(env = process.env) {
  const endpoint =
    env.APPWRITE_FUNCTION_API_ENDPOINT || env.APPWRITE_ENDPOINT;
  const projectId =
    env.APPWRITE_FUNCTION_PROJECT_ID || env.APPWRITE_PROJECT_ID;
  const apiKey =
    env.APPWRITE_FUNCTION_API_KEY || env.APPWRITE_API_KEY;

  if (!endpoint || !projectId || !apiKey) {
    throw new Error('Missing Appwrite endpoint, project ID, or API key.');
  }


  return new Client().setEndpoint(endpoint).setProject(projectId).setKey(apiKey);
}

/**
 * Creates a waitlist entry, or returns the existing pending entry for the same
 * phone number + ceremony type (idempotent submission / dedupe).
 */
export async function createWaitlistEntry({ databases, entry, userId }) {
  const now = new Date().toISOString();
  const adminTeamId = process.env.ADMIN_TEAM_ID || 'admins';

  const existing = await databases.listDocuments(DATABASE_ID, WAITLIST_COLLECTION, [
    Query.equal('phoneNumber', entry.phoneNumber),
    Query.equal('ceremonyType', entry.ceremonyType),
    Query.equal('status', 'new'),
    Query.limit(1),
  ]);

  if (existing.documents.length > 0) {
    return { duplicate: true, entry: existing.documents[0] };
  }

  const documentPermissions = [
    `read("team:${adminTeamId}")`,
    `update("team:${adminTeamId}")`,
    `delete("team:${adminTeamId}")`,
  ];

  const created = await databases.createDocument(
    DATABASE_ID,
    WAITLIST_COLLECTION,
    ID.unique(),
    {
      userId: userId || null,
      fullName: entry.fullName,
      phoneNumber: entry.phoneNumber,
      ceremonyType: entry.ceremonyType,
      eventDate: entry.eventDate,
      city: entry.city,
      state: entry.state,
      notes: entry.notes,
      submittedAt: now,
      status: 'new',
    },
    documentPermissions,
  );

  return { duplicate: false, entry: created };
}

export default async ({ req, res, log, error, databases: injectedDatabases }) => {
  try {
    if (req.method !== 'POST') {
      return res.json({ ok: false, message: 'Method not allowed' }, 405);
    }

    let body = {};
    try {
      body = typeof req.body === 'object' && req.body !== null
        ? req.body
        : JSON.parse(req.body || '{}');
    } catch (_) {
      return res.json({ ok: false, message: 'Invalid request body.' }, 400);
    }

    // Identity comes exclusively from the runtime-injected header; the body's
    // userId field is never trusted.
    const verifiedUserId = req.headers['x-appwrite-user-id'];
    const clientIp =
      req.headers['x-real-ip'] || req.headers['x-forwarded-for'] || '';

    const databases = injectedDatabases || new Databases(appwriteClient());

    // Fail-closed dual rate limiting: one bucket for the caller's identity or
    // network, one for the requested phone number.
    const callerLimit = await checkRateLimit({
      databases,
      identifier: deriveCallerIdentifier({ userId: verifiedUserId, clientIp }),
      isAuth: Boolean(verifiedUserId),
    });
    if (!callerLimit.allowed) {
      return res.json(
        { ok: false, message: 'Too many waitlist requests. Please try again later.' },
        429,
      );
    }

    const validation = validateWaitlistInput(body);
    if (!validation.ok) {
      return res.json(
        { ok: false, message: 'Invalid submission.', errors: validation.errors },
        400,
      );
    }

    const phoneLimit = await checkRateLimit({
      databases,
      identifier: derivePhoneIdentifier({ phoneNumber: validation.entry.phoneNumber }),
      isAuth: false,
    });
    if (!phoneLimit.allowed) {
      return res.json(
        { ok: false, message: 'This number has too many pending requests. Please try again later.' },
        429,
      );
    }

    const result = await createWaitlistEntry({
      databases,
      entry: validation.entry,
      userId: verifiedUserId,
    });

    if (result.duplicate) {
      log('Waitlist submission deduplicated (existing pending entry).');
    }

    return res.json({
      ok: true,
      duplicate: result.duplicate,
      entry: {
        id: result.entry.$id,
        userId: result.entry.userId || null,
        fullName: result.entry.fullName,
        phoneNumber: result.entry.phoneNumber,
        ceremonyType: result.entry.ceremonyType,
        eventDate: result.entry.eventDate || null,
        city: result.entry.city,
        state: result.entry.state,
        notes: result.entry.notes || null,
        submittedAt: result.entry.submittedAt,
        status: result.entry.status,
      },
    });
  } catch (err) {
    error(`bintiWaitlist error: ${err?.message || String(err)}`);
    return res.json(
      { ok: false, message: 'Waitlist submission failed. Please try again later.' },
      500,
    );
  }
};
