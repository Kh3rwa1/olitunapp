import { translate as vitaletsTranslate } from '@vitalets/google-translate-api';

export class BaseTranslationProvider {
  async translate({ text, from, to, timeoutMs = 8000 }) {
    throw new Error('translate() must be implemented');
  }
}

export class VitaletsTranslationProvider extends BaseTranslationProvider {
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
    this.apiKey = apiKey;
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

export function getTranslationProvider(env = process.env) {
  const providerType = (env.TRANSLATION_PROVIDER || 'vitalets').toLowerCase().trim();
  if (providerType === 'google-cloud' || providerType === 'gcp') {
    return new GoogleCloudTranslationProvider(env.GOOGLE_TRANSLATE_API_KEY);
  }
  return new VitaletsTranslationProvider();
}
