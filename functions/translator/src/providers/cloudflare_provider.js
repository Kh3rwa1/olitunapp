import { BaseTranslationProvider } from './base_provider.js';

export const INDICTRANS2_TARGET_LANGUAGES = Object.freeze({
  sat: 'sat_Olck',
  santali: 'sat_Olck',
  'sat-in': 'sat_Olck',
  'sat_olck': 'sat_Olck',
  hin: 'hin_Deva',
  hi: 'hin_Deva',
  hindi: 'hin_Deva',
  'hin_deva': 'hin_Deva',
  ben: 'ben_Beng',
  bn: 'ben_Beng',
  bengali: 'ben_Beng',
  'ben_beng': 'ben_Beng',
  ory: 'ory_Orya',
  or: 'ory_Orya',
  odia: 'ory_Orya',
  'ory_orya': 'ory_Orya',
  asm: 'asm_Beng',
  as: 'asm_Beng',
  assamese: 'asm_Beng',
  guj: 'guj_Gujr',
  gu: 'guj_Gujr',
  gujarati: 'guj_Gujr',
  mar: 'mar_Deva',
  mr: 'mar_Deva',
  marathi: 'mar_Deva',
  pan: 'pan_Guru',
  pa: 'pan_Guru',
  punjabi: 'pan_Guru',
  tam: 'tam_Taml',
  ta: 'tam_Taml',
  tamil: 'tam_Taml',
  tel: 'tel_Telu',
  te: 'tel_Telu',
  telugu: 'tel_Telu',
  urd: 'urd_Arab',
  ur: 'urd_Arab',
  urdu: 'urd_Arab',
  san: 'san_Deva',
  sa: 'san_Deva',
  sanskrit: 'san_Deva',
  mai: 'mai_Deva',
  bho: 'bho_Deva',
  brx: 'brx_Deva',
  doi: 'doi_Deva',
  kas: 'kas_Deva',
  gom: 'gom_Deva',
  kok: 'gom_Deva',
  mni: 'mni_Beng',
  npi: 'npi_Deva',
  ne: 'npi_Deva',
  snd: 'snd_Arab',
  sd: 'snd_Arab',
  lus: 'lus_Latn',
});

/**
 * Resolves a language code to an IndicTrans2 target language tag.
 */
export function resolveIndicTrans2Target(code) {
  if (!code || typeof code !== 'string') return null;
  const normalized = code.trim().toLowerCase();
  return INDICTRANS2_TARGET_LANGUAGES[normalized] || null;
}

/**
 * Translation provider using Cloudflare Workers AI with the
 * AI4Bharat IndicTrans2 English-to-Indic 1B model:
 * `@cf/ai4bharat/indictrans2-en-indic-1B`
 */
export class CloudflareIndicTrans2Provider extends BaseTranslationProvider {
  constructor({ accountId, apiToken, fallbackProvider = null, fetchFn = null } = {}) {
    super();
    this.accountId = accountId;
    this.apiToken = apiToken;
    this.fallbackProvider = fallbackProvider;
    this._fetch = fetchFn || (typeof fetch !== 'undefined' ? fetch : null);
  }

  get name() {
    return 'cloudflare_indictrans2';
  }

  async translate({ text, from = 'auto', to = 'sat', timeoutMs = 8000 }) {
    const targetTag = resolveIndicTrans2Target(to);
    const source = String(from || 'auto').trim().toLowerCase();

    // @cf/ai4bharat/indictrans2-en-indic-1B requires English source and Indic target
    const isEnglishOrAuto = source === 'auto' || source === 'en' || source === 'eng';
    const canHandleWithIndicTrans2 = isEnglishOrAuto && targetTag != null && this.accountId && this.apiToken;

    if (!canHandleWithIndicTrans2) {
      if (this.fallbackProvider) {
        return this.fallbackProvider.translate({ text, from, to, timeoutMs });
      }
      if (!this.accountId || !this.apiToken) {
        throw new Error('Cloudflare Workers AI credentials (CLOUDFLARE_ACCOUNT_ID and CLOUDFLARE_API_TOKEN) not configured');
      }
      if (!targetTag) {
        throw new Error(`Target language '${to}' is not supported by IndicTrans2 en-indic model`);
      }
      throw new Error(`Source language '${from}' is not supported by IndicTrans2 en-indic model (requires English)`);
    }

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);

    try {
      const url = `https://api.cloudflare.com/client/v4/accounts/${encodeURIComponent(this.accountId)}/ai/run/@cf/ai4bharat/indictrans2-en-indic-1B`;
      const res = await this._fetch(url, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.apiToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          text,
          target_language: targetTag,
        }),
        signal: controller.signal,
      });

      clearTimeout(timer);

      if (!res.ok) {
        const errorBody = await res.text().catch(() => '');
        if (this.fallbackProvider) {
          return this.fallbackProvider.translate({ text, from, to, timeoutMs });
        }
        throw new Error(`Cloudflare Workers AI HTTP error ${res.status}: ${errorBody.slice(0, 150)}`);
      }

      const data = await res.json();
      const translation = data?.result?.translations?.[0];

      if (!translation || typeof translation !== 'string') {
        if (this.fallbackProvider) {
          return this.fallbackProvider.translate({ text, from, to, timeoutMs });
        }
        throw new Error('Cloudflare Workers AI returned an invalid or empty translation response');
      }

      return {
        text: translation.trim(),
        from: 'en',
        provider: 'cloudflare-indictrans2-1b',
      };
    } catch (err) {
      clearTimeout(timer);
      if (this.fallbackProvider) {
        return this.fallbackProvider.translate({ text, from, to, timeoutMs });
      }
      throw err;
    }
  }
}
