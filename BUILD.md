# Building YouTube Stemmer from Source

This guide covers the process of compiling both the Rust backend and the Flutter frontend for all supported platforms using the unified build system.

## 🛠️ Prerequisites

Before starting, ensure you have the following installed:

- **Flutter SDK:** [https://docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install)
- **Rust Toolchain:** [https://rustup.rs/](https://rustup.rs/)
- **Python 3:** Required for the packaging script.
- **Make:** To run the build commands.

---

## 🏗️ 1. Quick Build (Current Platform)

The easiest way to build the entire project is to use the root `Makefile`:

```bash
# Build both backend and frontend
make build

# Clean everything
make clean
```

---

## 📦 2. Packaging for Release

To create a distributable package (`.tar.gz` for Linux, `.zip` for Windows/macOS), run:

```bash
make package
```

This command will:
1.  Verify the backend and frontend are built.
2.  Download necessary dependencies (ONNX Runtime, yt-dlp) if they are missing from the `backend/` directory.
3.  Organize all files into a platform-specific bundle.
4.  Create a compressed archive in the `dist/` directory.

---

## 🔍 3. Manual Build Steps

If you prefer to build components individually:

### Backend (Rust)
```bash
cd backend
# Standard build
cargo build --release

# macOS Universal binary (Apple Silicon + Intel)
rustup target add x86_64-apple-darwin aarch64-apple-darwin
MACOSX_DEPLOYMENT_TARGET=11.0 cargo build --release --target x86_64-apple-darwin
MACOSX_DEPLOYMENT_TARGET=11.0 cargo build --release --target aarch64-apple-darwin
lipo -create -output libbackend.dylib \
  target/aarch64-apple-darwin/release/libbackend.dylib \
  target/x86_64-apple-darwin/release/libbackend.dylib
```

### Frontend (Flutter)
```bash
cd frontend
flutter pub get
flutter build <linux|windows|macos> --release
```

---

## 🧪 4. Troubleshooting

- **Missing Libraries:** If the app fails to start, ensure `libbackend` and `libonnxruntime` are in the correct directory. Running `make package` ensures these are correctly placed in the `dist/` folder.
- **Audio Issues (Linux):** If the metronome is silent, ensure `libmpv` is installed on your system (`sudo apt install libmpv-dev`).
- **macOS Permissions:** If `yt-dlp` fails to run, check the "App Sandbox" and "Hardened Runtime" settings in Xcode. See [README_MAC.md](README_MAC.md) for more details.
