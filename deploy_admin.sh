#!/bin/bash

echo "🚀 Building Admin Panel for Web..."

# Build the Flutter web app with the admin entry point
flutter build web -t lib/main_admin.dart --release

if [ $? -eq 0 ]; then
  echo "✅ Build successful!"
  echo ""
  echo "To deploy to Vercel:"
  echo "---------------------------------------------------"
  echo "Option 1: Using Vercel CLI (Recommended)"
  echo "1. Run: vercel deploy --prod"
  echo "2. When asked 'Which directory contains your code?', select the current directory."
  echo "3. When asked for 'Output Directory', enter: build/web"
  echo "---------------------------------------------------"
  echo "Option 2: Using GitHub"
  echo "1. Push your code to GitHub."
  echo "2. Import the project in Vercel."
  echo "3. Configure 'Build Command' to: flutter build web -t lib/main_admin.dart --release"
  echo "4. Configure 'Output Directory' to: build/web"
  echo "---------------------------------------------------"
else
  echo "❌ Build failed. Please check the errors above."
  exit 1
fi
