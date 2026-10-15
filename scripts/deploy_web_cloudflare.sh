#!/usr/bin/env bash
set -euo pipefail

# Olitun Web Cloudflare Pages Deployment Script
# Builds Flutter Web with production flags and deploys build/web to Cloudflare Pages.

echo "=================================================="
echo "  Deploying Olitun Web to Cloudflare Pages"
echo "=================================================="

export APPWRITE_ENDPOINT="${APPWRITE_ENDPOINT:-https://sgp.cloud.appwrite.io/v1}"
export APPWRITE_PROJECT_ID="${APPWRITE_PROJECT_ID:-699495910038e39622c5}"

PROJECT_NAME="${CLOUDFLARE_PAGES_PROJECT:-olitunapp}"

# 1. Run production build
bash scripts/build_web.sh

# 2. Ensure Cloudflare SPA routing and header files exist
if [ ! -f "build/web/_redirects" ]; then
  echo "Error: build/web/_redirects is missing!"
  exit 1
fi

if [ ! -f "build/web/_headers" ]; then
  echo "Error: build/web/_headers is missing!"
  exit 1
fi

echo "Deploying build/web to Cloudflare Pages project: $PROJECT_NAME"
npx wrangler pages deploy build/web --project-name="$PROJECT_NAME"

echo "=================================================="
echo "  Cloudflare Pages Deployment Complete!"
echo "=================================================="
