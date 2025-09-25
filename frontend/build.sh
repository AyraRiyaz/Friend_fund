#!/bin/bash

# Netlify build script for Flutter web app
echo "Starting Flutter web build for production..."

# Ensure Flutter is available
flutter doctor

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build for web with proper base href and optimization
flutter build web --release --web-renderer html --base-href="/"

echo "Build completed successfully!"