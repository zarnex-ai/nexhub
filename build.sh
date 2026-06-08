#!/bin/bash
set -e

FLUTTER_VERSION="stable"
FLUTTER_HOME="/opt/flutter"

echo "==> Installing Flutter ($FLUTTER_VERSION)..."
if [ ! -d "$FLUTTER_HOME" ]; then
  git clone https://github.com/flutter/flutter.git \
    --depth 1 \
    -b "$FLUTTER_VERSION" \
    "$FLUTTER_HOME"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"
export FLUTTER_ALLOW_ROOT=true  # Vercel runs as root — this suppresses the warning

echo "==> Configuring Flutter for web..."
flutter config --enable-web
flutter precache --web

echo "==> Getting dependencies..."
flutter pub get

echo "==> Building Flutter web (release)..."
flutter build web --release --no-tree-shake-icons

echo "==> Build complete. Output in build/web"
