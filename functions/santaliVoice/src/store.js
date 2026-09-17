import { createHmac } from 'node:crypto';

export const VOICE_CLAIMS = 'voice_claims';
export const VOICE_QUOTAS = 'voice_quotas';

export class VoiceError extends Error {
  constructor(code, message, status = 500) {
    super(message);
    this.code = code;
    this.status = status;
  }
}

export function fail(code, message, status = 500) {
  throw new VoiceError(code, message, status);
}

export const digest = (secret, value) =>
  createHmac('sha256', secret)
    .update(JSON.stringify(value))
    .digest('hex')
    .slice(0, 36);

export function limits(env = process.env) {
  const read = (key, fallback) => {
    const value = env[key] ?? String(fallback);
    if (
      !/^\d+$/.test(String(value)) ||
      !Number.isSafeInteger(Number(value)) ||
      Number(value) < 1 ||
      Number(value) > 100000000
    ) {
      fail('CONFIGURATION_ERROR', 'Voice service is unavailable.', 503);
    }
    return Number(value);
  };

  return {
    monthlyChars: read('SANTALI_VOICE_MONTHLY_CHARS', 500000),
    dailyChars: read('SANTALI_VOICE_DAILY_CHARS', 50000),
    userDailyChars: read('SANTALI_VOICE_USER_DAILY_CHARS', 3000),
    userMinuteRequests: read('SANTALI_VOICE_USER_MINUTE_LIMIT', 10),
    globalMinuteRequests: read('SANTALI_VOICE_GLOBAL_MINUTE_LIMIT', 60),
  };
}

export class VoiceStore {
  constructor(db, databaseId, secret, now = () => new Date()) {
    this.db = db;
    this.databaseId = databaseId;
    this.secret = secret;
    this.now = now;
  }

  async get(id) {
    try {
      if (typeof this.db.getDocument === 'function') {
        try {
          return await this.db.getDocument({
            databaseId: this.databaseId,
            collectionId: VOICE_CLAIMS,
            documentId: id,
          });
        } catch (err) {
          if (err.code === 404) return null;
          return await this.db.getDocument(this.databaseId, VOICE_CLAIMS, id);
        }
      }
      return null;
    } catch (e) {
      if (e.code === 404) return null;
      throw e;
    }
  }

  async claim(id, userId, cacheKey, chars) {
    const docData = {
      userId,
      cacheKey,
      status: 'submitting',
      chars,
      checkedAt: this.now().getTime(),
    };
    try {
      if (typeof this.db.createDocument === 'function') {
        try {
          return await this.db.createDocument({
            databaseId: this.databaseId,
            collectionId: VOICE_CLAIMS,
            documentId: id,
            data: docData,
            permissions: [],
          });
        } catch (err) {
          if (err.code === 409) return null;
          return await this.db.createDocument(
            this.databaseId,
            VOICE_CLAIMS,
            id,
            docData,
            []
          );
        }
      }
    } catch (e) {
      if (e.code === 409) return null;
      // If collection does not exist yet (prior to setup), fail closed safely.
      fail('STORE_UNAVAILABLE', 'Voice service storage is unavailable.', 503);
    }
  }

  async update(id, data) {
    try {
      if (typeof this.db.updateDocument === 'function') {
        try {
          return await this.db.updateDocument({
            databaseId: this.databaseId,
            collectionId: VOICE_CLAIMS,
            documentId: id,
            data,
          });
        } catch (_) {
          return await this.db.updateDocument(this.databaseId, VOICE_CLAIMS, id, data);
        }
      }
    } catch (_) {
      // Best-effort update
    }
  }

  async take(scope, amount, max) {
    const documentId = digest(this.secret, ['quota', scope]);
    const period = scope.split(':')[0];

    try {
      if (typeof this.db.createDocument === 'function') {
        try {
          await this.db.createDocument({
            databaseId: this.databaseId,
            collectionId: VOICE_QUOTAS,
            documentId,
            data: { used: 0, period },
            permissions: [],
          });
        } catch (err) {
          if (err.code !== 409) {
            try {
              await this.db.createDocument(
                this.databaseId,
                VOICE_QUOTAS,
                documentId,
                { used: 0, period },
                []
              );
            } catch (posErr) {
              if (posErr.code !== 409) {
                fail('QUOTA_UNAVAILABLE', 'Voice limits are unavailable.', 503);
              }
            }
          }
        }
      }
    } catch (e) {
      if (e.code !== 409) {
        fail('QUOTA_UNAVAILABLE', 'Voice limits are unavailable.', 503);
      }
    }

    try {
      if (typeof this.db.incrementDocumentAttribute === 'function') {
        try {
          await this.db.incrementDocumentAttribute({
            databaseId: this.databaseId,
            collectionId: VOICE_QUOTAS,
            documentId,
            attribute: 'used',
            value: amount,
            max,
          });
        } catch (incErr) {
          if ([400, 409].includes(incErr.code) || incErr.code === 'QUOTA_EXCEEDED') {
            fail('QUOTA_EXCEEDED', 'Voice generation quota reached. Please try later.', 429);
          }
          try {
            await this.db.incrementDocumentAttribute(
              this.databaseId,
              VOICE_QUOTAS,
              documentId,
              'used',
              amount,
              max
            );
          } catch (posIncErr) {
            if ([400, 409].includes(posIncErr.code) || posIncErr.code === 'QUOTA_EXCEEDED') {
              fail('QUOTA_EXCEEDED', 'Voice generation quota reached. Please try later.', 429);
            }
            if (posIncErr instanceof VoiceError) throw posIncErr;
            fail('QUOTA_UNAVAILABLE', 'Voice limits are unavailable.', 503);
          }
        }
      } else {
        // Fallback for mocks / environments without incrementDocumentAttribute
        let doc;
        try {
          doc = await this.db.getDocument({
            databaseId: this.databaseId,
            collectionId: VOICE_QUOTAS,
            documentId,
          });
        } catch (_) {
          doc = await this.db.getDocument(this.databaseId, VOICE_QUOTAS, documentId);
        }
        const current = (doc?.used || 0) + amount;
        if (current > max) {
          fail('QUOTA_EXCEEDED', 'Voice generation quota exceeded. Please try later.', 429);
        }
        try {
          await this.db.updateDocument({
            databaseId: this.databaseId,
            collectionId: VOICE_QUOTAS,
            documentId,
            data: { used: current },
          });
        } catch (_) {
          await this.db.updateDocument(this.databaseId, VOICE_QUOTAS, documentId, { used: current });
        }
      }
    } catch (e) {
      if ([400, 409].includes(e.code) || e.code === 'QUOTA_EXCEEDED') {
        fail('QUOTA_EXCEEDED', 'Voice generation quota reached. Please try later.', 429);
      }
      if (e instanceof VoiceError) throw e;
      fail('QUOTA_UNAVAILABLE', 'Voice limits are unavailable.', 503);
    }
  }

  async requestLimit(userId, policy) {
    const minute = this.now().toISOString().slice(0, 16);
    await this.take(`voice:${minute}:user:${userId}`, 1, policy.userMinuteRequests);
    await this.take(`voice:${minute}:global`, 1, policy.globalMinuteRequests);
  }

  /**
   * Reserves quota across the monthly/daily/user scopes. Returns the exact
   * scope keys taken so a later refund targets the same period documents
   * (never the caller's wall-clock period, which may have rolled over).
   */
  async reserve(userId, chars, policy) {
    const date = this.now().toISOString();
    const scopes = [
      [`voice:${date.slice(0, 7)}:global`, chars, policy.monthlyChars],
      [`voice:${date.slice(0, 10)}:global`, chars, policy.dailyChars],
      [`voice:${date.slice(0, 10)}:user:${userId}`, chars, policy.userDailyChars],
    ];
    // Sequential takes with compensation: if a later take throws, the
    // earlier ones are released so partial reservations never leak.
    const taken = [];
    try {
      for (const [scope, amount, max] of scopes) {
        await this.take(scope, amount, max);
        taken.push(scope);
      }
    } catch (e) {
      for (const scope of taken) {
        try {
          await this.take(scope, -chars, Number.MAX_SAFE_INTEGER);
        } catch (_) {
          // Compensation is best-effort; surfaced via error log by caller.
        }
      }
      throw e;
    }
    return taken;
  }

  /**
   * Idempotent-by-construction refund against the exact scopes returned by
   * [reserve]. Safe to call exactly once per failed claim (failed claims
   * are permanently non-replayable, so no double-spend vector exists).
   * Best-effort: failures are logged by the caller for reconciliation,
   * never thrown into the request path.
   */
  async release(takenScopes, chars) {
    for (const scope of takenScopes || []) {
      try {
        await this.take(scope, -chars, Number.MAX_SAFE_INTEGER);
      } catch (_) {
        // Best-effort; caller logs for scheduled reconciliation.
      }
    }
  }

  /**
   * Reclaims a stale `submitting` claim (crash between claim and completion)
   * so one text is not locked out forever. Returns true when the caller may
   * proceed with a fresh claim lifecycle.
   */
  async reclaimIfStale(id, maxAgeMs) {
    const existing = await this.get(id);
    if (!existing) return true;
    if (existing.status !== 'submitting') return false;
    const age = this.now().getTime() - (existing.checkedAt || 0);
    if (age <= maxAgeMs) return false;
    // Without delete support the stale row cannot be removed: keep the
    // 409 (fail closed) rather than proceeding on a duplicate lifecycle.
    if (typeof this.db.deleteDocument !== 'function') return false;
    try {
      try {
        await this.db.deleteDocument({
          databaseId: this.databaseId,
          collectionId: VOICE_CLAIMS,
          documentId: id,
        });
      } catch (_) {
        await this.db.deleteDocument(this.databaseId, VOICE_CLAIMS, id);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
