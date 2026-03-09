# Building YouTube Stemmer on macOS (Big Sur 11.0+)

Follow these steps to build and run the application locally on your MacBook.

## 1. Prerequisites

Ensure you have the following installed:
- **Go (1.22+)**: [https://go.dev/dl/](https://go.dev/dl/)
- [https://docs.flutter.dev/get-started/install/macos/desktop](https://docs.flutter.dev/get-started/install/macos/desktop)
- **Xcode**: Install from the Mac App Store.

## 2. Build the Backend Shared Library

The Go backend should be compiled as a **Universal Binary** with explicit compatibility for macOS 11.0:

```bash
cd backend
go mod tidy


# Build for Apple Silicon (ARM64)
GOOS=darwin GOARCH=arm64 CGO_ENABLED=1 go build -buildmode=c-shared \
  -ldflags="-linkmode=external -extldflags='-mmacosx-version-min=11.0'" \
  -o libbackend_arm64.dylib main.go

# Build for Intel (AMD64)
GOOS=darwin GOARCH=amd64 CGO_ENABLED=1 go build -buildmode=c-shared \
  -ldflags="-linkmode=external -extldflags='-mmacosx-version-min=11.0'" \
  -o libbackend_amd64.dylib main.go

# Merge into a Universal Binary
lipo -create -output libbackend.dylib libbackend_arm64.dylib libbackend_amd64.dylib
```

## 3. Prepare the Flutter App

1. **Copy Backend Library**:
   ```bash
   cp libbackend.dylib ../frontend/macos/
   ```

2. **Download ONNX Runtime (v1.19.2 recommended for Big Sur)**:
   - Download the Universal2 binary: [onnxruntime-osx-universal2-1.19.2.tgz](https://github.com/microsoft/onnxruntime/releases/download/v1.19.2/onnxruntime-osx-universal2-1.19.2.tgz)
   - Extract the archive.
   - Copy `lib/libonnxruntime.1.19.2.dylib` to `frontend/macos/libonnxruntime.dylib`.
   - **Crucial**: Ensure the file is named exactly `libonnxruntime.dylib` in the `frontend/macos/` folder.

## 4. Run the Application

Navigate to the `frontend` directory and run:

```bash
cd ../frontend
flutter pub get
flutter run -d macos
```

## 5. Troubleshooting

### "Library not found" or Code Signing Errors
The Xcode project is configured to "Embed & Sign" these libraries. If you encounter errors:
1. Open the project in Xcode: `open macos/Runner.xcworkspace`.
2. Select the **Runner** target.
3. Go to **General** -> **Frameworks, Libraries, and Embedded Content**.
4. Ensure both `libbackend.dylib` and `libonnxruntime.dylib` are listed and set to **Embed & Sign**.

### FFmpeg Runtime Dependency
The application currently uses `ffmpeg` at runtime to standardize audio formats before stemming. If you encounter "ffmpeg conversion failed" errors, ensure FFmpeg is installed and available in your system PATH (e.g., `brew install ffmpeg`).

### Network Errors
The app requires the `com.apple.security.network.client` entitlement to download models. This is already included in the project's `.entitlements` files.
