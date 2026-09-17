export class StudioError extends Error {
  constructor(code, message, status = 400) {
    super(message); this.code = code; this.status = status;
  }
}
export const fail = (code, message, status) => { throw new StudioError(code, message, status); };
export const INPUT_BUCKET = 'ai_studio_inputs';
export const MAX_BYTES = 10 * 1024 * 1024;
export const LANGUAGES = ['hi-IN', 'bn-IN', 'as-IN', 'od-IN', 'sat-IN'];
export const validId = value => typeof value === 'string' && /^[a-zA-Z0-9][a-zA-Z0-9._-]{0,35}$/.test(value);
export function validateBody(raw) {
  let b;
  try { b = typeof raw === 'string' ? JSON.parse(raw) : raw; } catch { fail('INVALID_INPUT', 'Invalid JSON.'); }
  if (!b || Array.isArray(b) || typeof b !== 'object' || JSON.stringify(b).length > 16000) fail('INVALID_INPUT', 'Invalid request.');
  const fields = { translate: ['text', 'language'], transcribe: ['fileId', 'language'], ocrStart: ['fileId', 'language'], ocrStatus: ['jobId'] };
  if (!Object.hasOwn(fields, b.action) || Object.keys(b).some(k => !['action', ...fields[b.action]].includes(k))) fail('INVALID_INPUT', 'Unsupported action or field.');
  if (b.action === 'ocrStatus') {
    if (!validId(b.jobId)) fail('INVALID_INPUT', 'Invalid job ID.');
  } else {
    if (!LANGUAGES.includes(b.language) || (b.action === 'translate' && b.language === 'sat-IN')) fail('UNSUPPORTED_LANGUAGE', 'Unsupported language.');
    if (b.action === 'translate') {
      if (typeof b.text !== 'string' || !b.text.trim() || [...b.text].length > 2000) fail('INVALID_INPUT', 'Enter 1–2000 characters.');
      b = { ...b, text: b.text.trim() };
    } else if (!validId(b.fileId)) fail('INVALID_INPUT', 'Invalid file ID.');
  }
  return b;
}

// Parse actual PCM frames, never caller-supplied duration or container metadata alone.
export function wavDuration(bytes) {
  const bad = () => fail('INVALID_AUDIO', 'Use a valid PCM WAV file, at most 30 seconds.');
  if (bytes.length < 44 || bytes.toString('ascii', 0, 4) !== 'RIFF' || bytes.toString('ascii', 8, 12) !== 'WAVE' || bytes.readUInt32LE(4) + 8 !== bytes.length) bad();
  let format; let data; let offset = 12;
  while (offset + 8 <= bytes.length) {
    const tag = bytes.toString('ascii', offset, offset + 4); const size = bytes.readUInt32LE(offset + 4); offset += 8;
    if (size > bytes.length - offset) bad();
    if (tag === 'fmt ') {
      if (format || size !== 16) bad();
      const codec = bytes.readUInt16LE(offset), channels = bytes.readUInt16LE(offset + 2), rate = bytes.readUInt32LE(offset + 4);
      const byteRate = bytes.readUInt32LE(offset + 8), align = bytes.readUInt16LE(offset + 12), bits = bytes.readUInt16LE(offset + 14);
      if (codec !== 1 || ![1, 2].includes(channels) || ![8000, 16000, 22050, 24000, 44100, 48000].includes(rate) || bits !== 16 || align !== channels * 2 || byteRate !== rate * align) bad();
      format = { byteRate, align };
    } else if (tag === 'data') { if (data !== undefined) bad(); data = size; }
    offset += size + (size % 2);
  }
  if (offset !== bytes.length || !format || !data || data % format.align !== 0) bad();
  const seconds = data / format.byteRate;
  if (seconds > 30) bad();
  return seconds;
}
export function identifyDocument(bytes) {
  if (bytes.subarray(0, 8).equals(Buffer.from([137,80,78,71,13,10,26,10]))) return { mime: 'image/png', name: 'input.png' };
  if (bytes[0] === 255 && bytes[1] === 216 && bytes[2] === 255) return { mime: 'image/jpeg', name: 'input.jpg' };
  if (bytes.toString('ascii', 0, 5) === '%PDF-') return { mime: 'application/pdf', name: 'input.pdf' };
  fail('INVALID_FILE', 'Use a PNG, JPEG or PDF document.');
}
