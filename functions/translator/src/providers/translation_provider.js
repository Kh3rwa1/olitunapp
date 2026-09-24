import { translate as vitaletsTranslate } from '@vitalets/google-translate-api';

import { BaseTranslationProvider } from './base_provider.js';
export { BaseTranslationProvider };

export class VitaletsTranslationProvider extends BaseTranslationProvider {
  get name() {
    return 'vitalets';
  }

  async translate({ text, from, to, timeoutMs = 8000 }) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    try {
      const result = await Promise.race([
        vitaletsTranslate(text, { from, to }),
        new Promise((_, reject) => { controller.signal.addEventListener('abort', () => reject(new Error('Upstream translation timeout'))); })
      ]);
      clearTimeout(timer);
      return {
        text: result.text,
        from: result.from?.language?.iso || from,
        provider: 'vitalets-google-translate',
      };
    } catch (err) {
      clearTimeout(timer);
      throw err;
    }
  }
}

export class GoogleCloudTranslationProvider extends BaseTranslationProvider {
  constructor(apiKey) {
    super();
    this.apiKey = typeof apiKey === 'object' ? apiKey?.apiKey : apiKey;
  }

  get name() {
    return 'google_cloud';
  }

  async translate({ text, from, to, timeoutMs = 8000 }) {
    if (!this.apiKey) {
      throw new Error('Google Cloud Translation API key not configured');
    }
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    try {
      const url = 'https://translation.googleapis.com/language/translate/v2?key=' + encodeURIComponent(this.apiKey);
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          q: [text],
          source: from === 'auto' ? undefined : from,
          target: to,
          format: 'text',
        }),
        signal: controller.signal,
      });
      clearTimeout(timer);
      if (!res.ok) {
        const errorBody = await res.text().catch(() => '');
        throw new Error('Google Cloud Translation API HTTP error: ' + res.status);
      }
      const data = await res.json();
      const translated = data?.data?.translations?.[0]?.translatedText || '';
      const detectedSource = data?.data?.translations?.[0]?.detectedSourceLanguage || from;
      return {
        text: translated,
        from: detectedSource,
        provider: 'google-cloud-v2',
      };
    } catch (err) {
      clearTimeout(timer);
      throw err;
    }
  }
}

import {
  CloudflareIndicTrans2Provider,
  resolveIndicTrans2Target,
  INDICTRANS2_TARGET_LANGUAGES,
} from './cloudflare_provider.js';

export {
  CloudflareIndicTrans2Provider,
  resolveIndicTrans2Target,
  INDICTRANS2_TARGET_LANGUAGES,
};

export function getTranslationProvider(options = process.env) {
  let env = process.env;
  let engine = null;

  if (options && typeof options === 'object') {
    if ('engine' in options || 'env' in options) {
      engine = options.engine;
      env = options.env || process.env;
    } else {
      env = options;
    }
  }

  const providerType = (engine || env.TRANSLATION_PROVIDER || 'vitalets').toLowerCase().trim();

  if (providerType === 'google-cloud' || providerType === 'gcp') {
    return new GoogleCloudTranslationProvider(env.GOOGLE_TRANSLATE_API_KEY);
  }
  if (providerType === 'google' || providerType === 'vitalets') {
    if (env.GOOGLE_TRANSLATE_API_KEY) {
      return new GoogleCloudTranslationProvider(env.GOOGLE_TRANSLATE_API_KEY);
    }
    return new VitaletsTranslationProvider();
  }
  if (
    providerType === 'cloudflare' ||
    providerType === 'indictrans2' ||
    providerType === 'ai4bharat' ||
    providerType === 'hybrid'
  ) {
    const fallback = env.GOOGLE_TRANSLATE_API_KEY
      ? new GoogleCloudTranslationProvider(env.GOOGLE_TRANSLATE_API_KEY)
      : new VitaletsTranslationProvider();
    return new CloudflareIndicTrans2Provider({
      accountId: env.CLOUDFLARE_ACCOUNT_ID,
      apiToken: env.CLOUDFLARE_API_TOKEN,
      fallbackProvider: fallback,
    });
  }
  return new VitaletsTranslationProvider();
}
