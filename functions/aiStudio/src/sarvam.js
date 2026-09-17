import { fail } from './validation.js';
const ORIGIN = 'https://api.sarvam.ai';
export const TERMINAL = ['completed', 'partially_completed', 'failed', 'rejected'];
export function plainText(value) {
  if (typeof value !== 'string' || value.length > 100000) fail('INVALID_PROVIDER_RESPONSE', 'The extracted result is unavailable.', 502);
  // Treat provider content as inert text; never return a URL or a rich rendering instruction.
  return value.replace(/<[^>]*>/g, '').replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F]/g, '').trim();
}
export class Sarvam {
  constructor(apiKey, fetchImpl = fetch) { this.apiKey = apiKey; this.fetch = fetchImpl; }
  async call(path, body) {
    try {
      const json = body && !(body instanceof FormData);
      const response = await this.fetch(`${ORIGIN}${path}`, {
        method: body ? 'POST' : 'GET', redirect: 'error', signal: AbortSignal.timeout(45000),
        headers: { 'api-subscription-key': this.apiKey, ...(json ? { 'Content-Type': 'application/json' } : {}) },
        ...(body ? { body: json ? JSON.stringify(body) : body } : {}),
      });
      if (!response.ok) fail('PROVIDER_UNAVAILABLE', 'AI provider could not complete the request.', 502);
      // Bound responses while streaming, rather than trusting Content-Length.
      const reader = response.body.getReader(); let size = 0; const chunks = [];
      try {
        while (true) {
          const { done, value } = await reader.read(); if (done) break;
          size += value.length;
          if (size > 2 * 1024 * 1024) { await reader.cancel(); fail('INVALID_PROVIDER_RESPONSE', 'The result is too large.', 502); }
          chunks.push(Buffer.from(value));
        }
      } finally { reader.releaseLock(); }
      return JSON.parse(Buffer.concat(chunks).toString('utf8'));
    } catch (e) {
      if (e.code && e.status) throw e;
      fail('PROVIDER_UNAVAILABLE', 'AI provider could not complete the request. Automatic resubmission is disabled.', 502);
    }
  }
  async translate(text, language) {
    const data = await this.call('/translate', { input: text, source_language_code: language, target_language_code: 'sat-IN', model: 'sarvam-translate:v1', mode: 'formal' });
    return plainText(data.translated_text);
  }
  async transcribe(bytes, language) {
    const form = new FormData(); form.set('file', new Blob([bytes], { type: 'audio/wav' }), 'input.wav');
    form.set('language_code', language); form.set('model', 'saaras:v3'); form.set('mode', 'transcribe');
    const data = await this.call('/speech-to-text', form);
    return plainText(data.transcript);
  }
  async ocrStart(bytes, language, file) {
    const form = new FormData(); form.set('file', new Blob([bytes], { type: file.mime }), file.name);
    form.set('language', language); form.set('output_format', 'md');
    const data = await this.call('/doc-ai/v1/job/digitise', form);
    if (typeof data.job_id !== 'string' || !/^[a-zA-Z0-9_-]{1,128}$/.test(data.job_id)) fail('INVALID_PROVIDER_RESPONSE', 'The OCR job could not be confirmed.', 502);
    return data.job_id;
  }
  async ocrStatus(jobId) {
    const path = `/doc-ai/v1/job/${encodeURIComponent(jobId)}`;
    const data = await this.call(`${path}/status`);
    if (data.job_id !== jobId || typeof data.status !== 'string') fail('INVALID_PROVIDER_RESPONSE', 'The OCR status is unavailable.', 502);
    const status = TERMINAL.includes(data.status) ? data.status : 'processing';
    if (!['completed', 'partially_completed'].includes(status)) return { status };
    const result = await this.call(`${path}/results?format=json`);
    if (result.job_id !== jobId) fail('INVALID_PROVIDER_RESPONSE', 'The OCR result is unavailable.', 502);
    return { status, text: resultText(result) };
  }
}

export function resultText(result) {
  if (!result || typeof result !== 'object' || !Array.isArray(result.documents)) {
    fail('INVALID_PROVIDER_RESPONSE', 'The OCR result is unavailable.', 502);
  }
  const pages = result.documents.flatMap((doc) => {
    if (Array.isArray(doc.pages)) {
      return [...doc.pages].sort(
        (a, b) =>
          (a.page_number ?? a.page_num ?? 0) -
          (b.page_number ?? b.page_num ?? 0),
      );
    }
    if (Array.isArray(doc.blocks)) return [{ blocks: doc.blocks }];
    return [];
  });
  return plainText(
    pages
      .map((page) => {
        if (
          typeof page.content === 'string' &&
          page.content.replace(/<[^>]*>/g, '').trim()
        ) {
          return page.content.replace(/<[^>]*>/g, '').trim();
        }
        const blocks = Array.isArray(page.blocks) ? page.blocks : [];
        return blocks
          .filter((block) => block && typeof block === 'object')
          .sort(
            (a, b) =>
              (a.reading_order ?? Number.MAX_SAFE_INTEGER) -
              (b.reading_order ?? Number.MAX_SAFE_INTEGER),
          )
          .map((block) =>
            typeof block.text === 'string'
              ? block.text.replace(/<[^>]*>/g, '').trim()
              : '',
          )
          .filter((text) => text)
          .join('\n');
      })
      .filter((text) => text)
      .join('\n\n'),
  );
}
