import test from 'node:test';
import assert from 'node:assert/strict';
import { Sarvam } from '../aiStudio/src/sarvam.js';

// Opt-in live smoke test: never runs implicitly. Requires BOTH
//   AI_STUDIO_LIVE=true  and  SARVAM_API_KEY=<key>
// so CI and default `npm test` never spend credits.
const apiKey = process.env.SARVAM_API_KEY;
const runLive = process.env.AI_STUDIO_LIVE === 'true' && Boolean(apiKey);

test(
  'live Sarvam translate returns Ol Chiki Santali for short Hindi text',
  { skip: runLive ? false : 'opt in with AI_STUDIO_LIVE=true and SARVAM_API_KEY' },
  async () => {
    const provider = new Sarvam(apiKey);
    try {
      const text = await provider.translate('नमस्ते, आप कैसे हैं?', 'hi-IN');
      assert.ok(text.length > 0, 'provider returned empty text');
      // Santali in Ol Chiki script occupies U+1C50..U+1C7F.
      const hasOlChiki = [...text].some((ch) => {
        const code = ch.codePointAt(0);
        return code >= 0x1c50 && code <= 0x1c7f;
      });
      assert.ok(hasOlChiki, `expected Ol Chiki output, got: ${text}`);
    } catch (e) {
      if (e.code === 'PROVIDER_UNAVAILABLE') {
        assert.fail(
          'live call failed — check key validity, credits and plan rate limits',
        );
      }
      throw e;
    }
  },
);
