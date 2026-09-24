export class BaseTranslationProvider {
  async translate({ text, from, to, timeoutMs = 8000 }) {
    throw new Error('translate() must be implemented');
  }
}
