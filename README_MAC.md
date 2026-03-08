# Building YouTube Stemmer on macOS

Follow these steps to build and run the application on your MacBook.

## 1. Prerequisites

Ensure you have the following installed:
- **Go**: [https://go.dev/dl/](https://go.dev/dl/)
- **Flutter SDK**: [https://docs.flutter.dev/get-started/install/macos/desktop](https://docs.flutter.dev/get-started/install/macos/desktop)
- **Xcode**: Install from the Mac App Store.
- **FFmpeg**: Run `brew install ffmpeg` (requires [Homebrew](https://brew.sh/)).

## 2. Build the Backend Shared Library

The Go backend should be compiled as a **Universal Binary** to support both Intel and Apple Silicon Macs:

```bash
cd backend
# Build for Apple Silicon
GOOS=darwin GOARCH=arm64 go build -buildmode=c-shared -o libbackend_arm64.dylib main.go
# Build for Intel
GOOS=darwin GOARCH=amd64 CGO_ENABLED=1 go build -buildmode=c-shared -o libbackend_amd64.dylib main.go
# Merge into a Universal Binary
lipo -create -output libbackend.dylib libbackend_arm64.dylib libbackend_amd64.dylib
```


## 3. Prepare the Flutter App

1. Copy the generated `libbackend.dylib` to the `frontend/macos/` directory:
   ```bash
   cp libbackend.dylib ../frontend/macos/
   ```

2. Download the **ONNX Runtime** shared library for macOS (Intel or Apple Silicon depending on your Mac):
   - [Download from ONNX Runtime Releases](https://github.com/microsoft/onnxruntime/releases)
   - Extract `libonnxruntime.dylib` and place it in the `frontend/macos/` directory.

## 4. Run the Application

Navigate to the `frontend` directory and run:

```bash
cd ../frontend
flutter pub get
flutter run -d macos
```

## 5. Build a Standalone Bundle

To create a distributable `.app` bundle:

```bash
flutter build macos
```
The application will be located in `build/macos/Build/Products/Release/YouTube Stemmer.app`.
