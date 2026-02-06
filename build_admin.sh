#!/bin/bash
set -e

# Olitun Admin Build Script for Vercel
echo "Starting Olitun Admin Web Build..."

# 1. Install Flutter if not present
if [ ! -d "flutter" ]; then
  echo "Installing Flutter SDK (stable branch)..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

export PATH="$PATH:`pwd`/flutter/bin"

# 2. Configure Flutter
echo "Configuring Flutter..."
flutter config --enable-web

# 3. Build the application
echo "Fetching dependencies..."
flutter pub get

echo "Building web application targeting Admin Panel..."
# Removed --web-renderer for compatibility with newer Flutter versions
flutter build web \
  -t lib/main_admin.dart \
  --release

echo "Build complete!"
