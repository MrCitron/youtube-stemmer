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

2. **Download ONNX Runtime (v1.19.2 recommended)**:
   - Download the Universal2 binary: [onnxruntime-osx-universal2-1.19.2.tgz](https://github.com/microsoft/onnxruntime/releases/download/v1.19.2/onnxruntime-osx-universal2-1.19.2.tgz)
   - Extract and copy `lib/libonnxruntime.1.19.2.dylib` to `frontend/macos/libonnxruntime.dylib`.

3. **Download and Bundle yt-dlp**:
   - Download the macOS binary: [yt-dlp_macos](https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos)
   - Rename it to `yt-dlp` and make it executable: `chmod +x yt-dlp`
   - Copy it to the `frontend/macos/` folder.

## 4. Xcode Configuration (CRITICAL)

To ensure the application can find the bundled tools and libraries:

1. **Open Xcode**: `open frontend/macos/Runner.xcworkspace`
2. **Add yt-dlp to Bundle**:
   - Right-click the **Runner** folder in the Project Navigator.
   - Select **"Add Files to 'Runner'..."**.
   - Select the `yt-dlp` binary.
   - Ensure **"Copy items if needed"** is checked and the **Runner** target is selected.
3. **Verify yt-dlp in Build Phases**:
   - Select the project -> **Runner** target -> **Build Phases**.
   - Ensure `yt-dlp` is listed in **"Copy Bundle Resources"**.
4. **Configure Libraries**:
   - Under the **General** tab of the **Runner** target, find **"Frameworks, Libraries, and Embedded Content"**.
   - Ensure both `libbackend.dylib` and `libonnxruntime.dylib` are present and set to **"Embed & Sign"**.

## 5. Run the Application

```bash
cd frontend
flutter pub get
flutter run -d macos
```
