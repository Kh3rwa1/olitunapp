#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "🚀 Starting Vercel Build for Flutter Web..."

# 1. Install Flutter
echo "⬇️  Downloading Flutter..."
if [ -d "flutter" ]; then
    echo "   Flutter already exists, skipping download."
else
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# 2. Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Securely/Environment Variable handling (Optional: create .env from Vercel envs if needed)
# echo "SUPABASE_URL=$SUPABASE_URL" > .env
# echo "SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" >> .env

# 4. Run Flutter Doctor (Optional, for debugging)
# flutter doctor -v

# 5. Build the Admin Panel
echo "🔨 Building Admin App..."
# Enable web support just in case
flutter config --enable-web

# Get dependencies
flutter pub get

# Build
flutter build web -t lib/main_admin.dart --release

echo "✅ Build Complete!"
