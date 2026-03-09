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

3. **Download and Bundle yt-dlp**:
   - Download the macOS binary: [yt-dlp_macos](https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos)
   - Rename it to `yt-dlp` and make it executable: `chmod +x yt-dlp`
   - Copy it to the `frontend/macos/` folder: `cp yt-dlp frontend/macos/`

## 4. Run the Application

Navigate to the `frontend` directory and run:

```bash
cd frontend
flutter pub get
flutter run -d macos
```

## 5. Troubleshooting

### "yt-dlp not found" or "Failed to execute yt-dlp"
The application expects `yt-dlp` to be bundled inside the app. For local development:
1. Open the project in Xcode: `open macos/Runner.xcworkspace`.
2. Add the `yt-dlp` binary from the `macos/` folder to the **Runner** target (similar to how you added the dylibs).
3. In the **"Build Phases"** tab, under **"Copy Bundle Resources"**, ensure `yt-dlp` is listed.

### FFmpeg (NOT NEEDED)
The new Rust backend handles audio decoding natively. You do NOT need to install FFmpeg.
