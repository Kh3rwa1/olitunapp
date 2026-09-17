import { createHmac } from 'node:crypto';
import { fail } from './validation.js';
export const JOBS = 'ai_studio_jobs';
export const QUOTAS = 'ai_studio_quotas';
export const digest = (secret, value) => createHmac('sha256', secret).update(JSON.stringify(value)).digest('hex').slice(0, 36);
export function limits(env) {
  const read = (key, fallback) => {
    const value = env[key] ?? String(fallback);
    if (!/^\d+$/.test(String(value)) || !Number.isSafeInteger(Number(value)) || Number(value) < 1 || Number(value) > 100000000) fail('CONFIGURATION_ERROR', 'AI Studio is unavailable.', 503);
    return Number(value);
  };
  return {
    monthly: read('AI_STUDIO_MONTHLY_PAISE', 2000000),
    daily: read('AI_STUDIO_DAILY_PAISE', 65000),
    userDaily: read('AI_STUDIO_USER_DAILY_PAISE', 10000),
    translate: read('AI_STUDIO_TRANSLATE_RESERVE_PAISE', 200),
    transcribe: read('AI_STUDIO_TRANSCRIBE_RESERVE_PAISE', 200),
    ocrStart: read('AI_STUDIO_OCR_RESERVE_PAISE', 5000),
  };
}
export class Store {
  constructor(db, databaseId, secret, now = () => new Date()) { Object.assign(this, { db, databaseId, secret, now }); }
  async get(id) {
    try { return await this.db.getDocument({ databaseId: this.databaseId, collectionId: JOBS, documentId: id }); }
    catch (e) { if (e.code === 404) return null; throw e; }
  }
  async claim(id, userId, action, language, extra = {}) {
    try {
      return await this.db.createDocument({ databaseId: this.databaseId, collectionId: JOBS, documentId: id,
        data: { userId, action, language, status: 'submitting', providerJobId: '', text: '', checkedAt: 0, ...extra }, permissions: [] });
    } catch (e) { if (e.code === 409) return null; throw e; }
  }
  async update(id, data) {
    return this.db.updateDocument({ databaseId: this.databaseId, collectionId: JOBS, documentId: id, data });
  }
  async take(scope, amount, max) {
    const documentId = digest(this.secret, ['quota', scope]);
    const params = { databaseId: this.databaseId, collectionId: QUOTAS, documentId };
    try { await this.db.createDocument({ ...params, data: { used: 0, period: scope.split(':')[0] }, permissions: [] }); }
    catch (e) { if (e.code !== 409) fail('QUOTA_UNAVAILABLE', 'Usage limits are unavailable.', 503); }
    // Appwrite's database-side max check and increment are atomic. Never use read/modify/write.
    // Partial reservations are deliberately NOT refunded (safe over-accounting on any failure).
    try { await this.db.incrementDocumentAttribute({ ...params, attribute: 'used', value: amount, max }); }
    catch (e) {
      if ([400, 409].includes(e.code)) fail('QUOTA_EXCEEDED', 'AI Studio usage limit reached. Please try later.', 429);
      fail('QUOTA_UNAVAILABLE', 'Usage limits are unavailable.', 503);
    }
  }
  async requestLimit(userId) {
    const minute = this.now().toISOString().slice(0, 16);
    await this.take(`${minute}:user:${userId}`, 1, 20);
    await this.take(`${minute}:global`, 1, 120);
  }
  async ocrLimit() { await this.take(`${this.now().toISOString().slice(0, 16)}:ocr`, 2, 10); }
  async reserve(userId, amount, policy) {
    const date = this.now().toISOString();
    await this.take(`${date.slice(0, 7)}:global`, amount, policy.monthly);
    await this.take(`${date.slice(0, 10)}:global`, amount, policy.daily);
    await this.take(`${date.slice(0, 10)}:user:${userId}`, amount, policy.userDaily);
  }
}
