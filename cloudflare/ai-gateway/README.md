# Olitun Cloudflare AI Gateway Worker

Provides edge-accelerated, zero-database-read routing for:
1. **Santali AI Voice**: Bodhan AI TTS (`https://api.bodhan.ai/v1/audio/speech`) key rotation across all available accounts.
2. **AI Studio**: Sarvam AI Document OCR, Speech-to-Text (transcribe), and Translation.
3. **IndicTrans2**: Cloudflare Workers AI (`@cf/ai4bharat/indictrans2-en-indic-1B`).

## Deployment Instructions

To deploy to Cloudflare:
1. Ensure you have a Cloudflare API Token with `Account -> Workers Scripts: Edit` and `Account -> Workers KV Storage: Edit` permissions.
2. Set the environment variable:
   ```bash
   export CLOUDFLARE_API_TOKEN="your-token-with-workers-permission"
   ```
3. Run:
   ```bash
   cd cloudflare/ai-gateway
   npx wrangler deploy
   ```
