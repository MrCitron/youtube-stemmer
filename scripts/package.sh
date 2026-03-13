#!/bin/bash

# Exit on error
set -e

PROJECT_ROOT=$(pwd)
PACKAGE_DIR=$PROJECT_ROOT/dist/linux
BUNDLE_DIR=$PACKAGE_DIR/youtube_stemmer

echo "Building YouTube Stemmer for Linux..."

# 1. Build Go Backend
echo "Building Go backend..."
cd $PROJECT_ROOT/backend
make clean
make linux

# 2. Build Flutter Frontend
echo "Building Flutter frontend..."
cd $PROJECT_ROOT/frontend
flutter build linux --release

# 3. Prepare Package Directory
echo "Preparing package directory..."
mkdir -p $BUNDLE_DIR/lib

# Copy Flutter bundle
cp -r $PROJECT_ROOT/frontend/build/linux/x64/release/bundle/* $BUNDLE_DIR/

# Copy installation scripts
cp $PROJECT_ROOT/scripts/install.sh $BUNDLE_DIR/
cp $PROJECT_ROOT/scripts/youtube_stemmer.desktop.template $BUNDLE_DIR/
chmod +x $BUNDLE_DIR/install.sh

# Copy Go backend shared library
cp $PROJECT_ROOT/backend/build/linux/libbackend.so $BUNDLE_DIR/lib/

# Copy ONNX runtime shared library
if [ -f "$PROJECT_ROOT/backend/libonnxruntime.so" ]; then
    cp $PROJECT_ROOT/backend/libonnxruntime.so $BUNDLE_DIR/lib/
else
    echo "Warning: libonnxruntime.so not found in backend/. It might need to be downloaded or already present in system."
fi

# 4. Create Tarball
echo "Creating archive..."
cd $PACKAGE_DIR
tar -cvzf youtube_stemmer_linux.tar.gz youtube_stemmer/

echo "Package created at: $PACKAGE_DIR/youtube_stemmer_linux.tar.gz"
