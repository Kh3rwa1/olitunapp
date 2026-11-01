#!/usr/bin/env bash
# Turns on Worker-owned sign-in for the production Worker (olitun-api).
#
#   cd cloudflare/backend && bash scripts/enable_worker_auth.sh
#
# Safe to re-run. Steps:
#   1. Creates the auth tables in D1 (CREATE TABLE IF NOT EXISTS only).
#   2. Sets AUTH_SECRET once (random, never printed). Re-running keeps the
#      existing secret, because replacing it would sign every device out.
#   3. Deploys the Worker. Appwrite JWTs keep working, so app builds that
#      still sign in with Appwrite are unaffected.
#   4. Prints which sign-in methods are live.
#
# Optional, any time afterwards:
#   npx wrangler email sending enable olitun.in        # email codes
#   npx wrangler secret put GOOGLE_CLIENT_ID           # Google sign-in
#   npx wrangler secret put GOOGLE_CLIENT_SECRET
#   npx wrangler secret put ADMIN_EMAILS               # extra admins (comma-separated)
set -euo pipefail
cd "$(dirname "$0")/.."

echo "1/4 D1 auth tables"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
python3 - "$tmp" <<'PY'
import sys
s = open('schema.sql').read()
open(sys.argv[1], 'w').write(s[s.index('-- Worker-owned sign-in'):])
PY
npx wrangler d1 execute olitun-db --remote --file="$tmp"

echo "2/4 AUTH_SECRET"
if npx wrangler secret list 2>/dev/null | grep -q '"AUTH_SECRET"'; then
  echo "  already set; keeping it"
else
  openssl rand -base64 48 | tr -d '\n' | npx wrangler secret put AUTH_SECRET
fi

echo "3/4 deploy"
npx wrangler deploy

echo "4/4 live sign-in methods"
sleep 3
curl -fsS https://olitun-api.dulalkisku0.workers.dev/api/v1/auth/config
echo
