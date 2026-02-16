#!/bin/bash
set -e

# Olitun Website Build Script
echo "Starting Olitun Website Web Build..."

# 1. Install Flutter if not present
if [ ! -d "flutter" ]; then
  echo "Installing Flutter SDK (stable branch)..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

export PATH="$PATH:`pwd`/flutter/bin"

# 2. Configure Flutter
echo "Configuring Flutter..."
flutter config --enable-web

# Create dummy .env if it doesn't exist
if [ ! -f ".env" ]; then
  echo "Creating placeholder .env file..."
  touch .env
fi

# 3. Build the application
echo "Fetching dependencies..."
flutter pub get

echo "Building web application targeting Main Website..."
flutter build web \
  -t lib/main.dart \
  --release

echo "Build complete!"
