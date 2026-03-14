#!/usr/bin/env bash
# Fast local macOS dev build: native arch only (no lipo), then flutter run.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR/.."
BACKEND="$ROOT/backend"
FRONTEND="$ROOT/frontend"
ARCH=$(uname -m)  # x86_64 or arm64
TARGET="${ARCH}-apple-darwin"
DEBUG_BUNDLE="$FRONTEND/build/macos/Build/Products/Debug/youtube_stemmer.app/Contents/Frameworks"

RUSTUP_RUSTC=$(rustup which rustc 2>/dev/null || echo rustc)
RUSTUP_CARGO=$(rustup which cargo 2>/dev/null || echo cargo)

echo "► Building backend ($TARGET)..."
cd "$BACKEND"
RUSTC="$RUSTUP_RUSTC" MACOSX_DEPLOYMENT_TARGET=11.0 \
    "$RUSTUP_CARGO" build --release --target "$TARGET"

echo "► Deploying libbackend.dylib..."
cp "target/$TARGET/release/libbackend.dylib" "$FRONTEND/macos/libbackend.dylib"

# Also copy directly into the existing debug bundle (if present) to bypass
# Xcode's incremental build cache — avoids needing flutter clean every time.
if [ -d "$DEBUG_BUNDLE" ]; then
    cp "$FRONTEND/macos/libbackend.dylib" "$DEBUG_BUNDLE/libbackend.dylib"
    echo "   → also hot-patched debug bundle"
fi

echo "► Running flutter..."
cd "$FRONTEND"
flutter run -d macos
