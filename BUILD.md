# Building YouTube Stemmer from Source

This guide covers the process of compiling both the Rust backend and the Flutter frontend for all supported platforms.

## 🛠️ Global Prerequisites

Before starting, ensure you have the following installed:

- **Flutter SDK:** [https://docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install)
- **Rust Toolchain:** [https://rustup.rs/](https://rustup.rs/)
- **ONNX Runtime (v1.19.2):** Shared libraries are required for AI inference.
- **yt-dlp:** Required for audio retrieval from YouTube.

---

## 🏗️ 1. Build the Rust Backend

The backend is located in the `backend/` directory.

### Standard Build (Linux / Windows)

```bash
cd backend
cargo build --release
```

- **Linux output:** `target/release/libbackend.so`
- **Windows output:** `target/release/backend.dll`

### macOS (Universal Binary)

To support both Apple Silicon and Intel Macs, build a Universal binary:

```bash
cd backend
rustup target add x86_64-apple-darwin aarch64-apple-darwin

# Build both targets
MACOSX_DEPLOYMENT_TARGET=11.0 cargo build --release --target x86_64-apple-darwin
MACOSX_DEPLOYMENT_TARGET=11.0 cargo build --release --target aarch64-apple-darwin

# Combine into a single dylib
lipo -create -output libbackend.dylib \
  target/aarch64-apple-darwin/release/libbackend.dylib \
  target/x86_64-apple-darwin/release/libbackend.dylib
```

---

## 📱 2. Prepare the Frontend

### Asset Placement

The application expects certain files to be present in the build bundle or search paths:

1.  **Backend Library:** Copy the built `libbackend` to the appropriate location (typically next to the executable or in `frontend/macos/` for Mac).
2.  **ONNX Runtime:** Place `libonnxruntime` in the same directory.
3.  **yt-dlp:**
    -   **Linux/Windows:** Place in the same directory as the executable.
    -   **macOS:** Must be bundled via Xcode (see [README_MAC.md](README_MAC.md)).

### Fetch Dependencies

```bash
cd frontend
flutter pub get
```

---

## 🚀 3. Compile the Application

### Linux

```bash
cd frontend
flutter build linux
# Output: build/linux/x64/release/bundle/
```

### macOS

```bash
cd frontend
flutter build macos
# Output: build/macos/Build/Products/Release/youtube_stemmer.app
```
*Note: See [README_MAC.md](README_MAC.md) for critical Xcode configuration steps.*

### Windows

```bash
cd frontend
flutter build windows
# Output: build/windows/x64/runner/Release/
```

---

## 🧪 4. Troubleshooting

- **FFI Load Errors:** Ensure all shared libraries (`libbackend`, `libonnxruntime`) and `yt-dlp` are in the correct directory. On Linux, you may need to set `LD_LIBRARY_PATH=.` if running manually from the bundle.
- **Audio Issues (Linux):** If the metronome is silent, ensure `libmpv` is installed on your system.
- **macOS Permissions:** If `yt-dlp` fails to run, check the "App Sandbox" and "Hardened Runtime" settings in Xcode.
