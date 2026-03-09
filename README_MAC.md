# Building YouTube Stemmer on macOS (Rust Backend)

Follow these steps to build and run the application locally on your MacBook (Big Sur 11.0+).

## 1. Prerequisites

Ensure you have the following installed:
- **Rust**: [https://rustup.rs/](https://rustup.rs/)
- **Flutter SDK**: [https://docs.flutter.dev/get-started/install/macos/desktop](https://docs.flutter.dev/get-started/install/macos/desktop)
- **Xcode**: Install from the Mac App Store.

## 2. Build the Backend Shared Library (Rust)

The Rust backend should be compiled as a **Universal Binary**:

```bash
cd backend

# Add macOS targets
rustup target add x86_64-apple-darwin
rustup target add aarch64-apple-darwin

# Build for Intel (AMD64)
MACOSX_DEPLOYMENT_TARGET=11.0 cargo build --release --target x86_64-apple-darwin

# Build for Apple Silicon (ARM64)
MACOSX_DEPLOYMENT_TARGET=11.0 cargo build --release --target aarch64-apple-darwin

# Merge into a Universal Binary
mkdir -p build/macos
lipo -create -output libbackend.dylib \
  target/aarch64-apple-darwin/release/libbackend.dylib \
  target/x86_64-apple-darwin/release/libbackend.dylib
```

## 3. Prepare the Flutter App

1. **Copy Backend Library**:
   ```bash
   cp backend/libbackend.dylib frontend/macos/
   ```

2. **Download ONNX Runtime (v1.19.2 recommended for Big Sur)**:
   - Download the Universal2 binary: [onnxruntime-osx-universal2-1.19.2.tgz](https://github.com/microsoft/onnxruntime/releases/download/v1.19.2/onnxruntime-osx-universal2-1.19.2.tgz)
   - Extract the archive.
   - Copy `lib/libonnxruntime.1.19.2.dylib` to `frontend/macos/libonnxruntime.dylib`.
   - **Crucial**: Ensure the file is named exactly `libonnxruntime.dylib`.

## 4. Run the Application

Navigate to the `frontend` directory and run:

```bash
cd frontend
flutter pub get
flutter run -d macos
```

## 5. Troubleshooting

### "Library not found"
Ensure `libbackend.dylib` and `libonnxruntime.dylib` are in `frontend/macos/` AND added to the Xcode project as "Embed & Sign" (General tab of the Runner target).

### FFmpeg (NOT NEEDED)
The new Rust backend handles audio decoding natively. You do NOT need to install FFmpeg.
