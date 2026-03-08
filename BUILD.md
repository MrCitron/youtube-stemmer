# Building and Deploying YouTube Stemmer

This document explains how to build the Go-based backend shared library and integrate it with the Flutter frontend.

## Prerequisites

- **Go 1.26+**
- **Flutter SDK**
- **GCC** (for Linux)
- **MinGW-w64** (for Windows cross-compilation)
- **Android NDK** (for Android)

## 1. Build the Backend (Go)

The backend is located in the `backend/` directory. It must be compiled as a shared library for each target platform.

### Standard Build (Linux)

```bash
cd backend
make linux
```

This generates `backend/build/linux/libbackend.so`.

### Cross-Compilation (Windows)

```bash
cd backend
make windows
```

Requires `x86_64-w64-mingw32-gcc`. Generates `backend/build/windows/libbackend.dll`.

### Distribution

To copy the built libraries to the Flutter project:

```bash
cd backend
make dist
```

## 2. Platform-Specific Integration (FFI)

The Flutter frontend uses `dart:ffi` to communicate with the Go library.

### Linux
The `libbackend.so` file must be in the same directory as the executable or in a standard library path. During development, `BackendFFI` looks in `backend/`.

### Windows
The `libbackend.dll` file must be in the same directory as the `.exe`.

### Android
Place the `.so` files in `frontend/android/app/src/main/jniLibs/<arch>/` (e.g., `arm64-v8a`).

### macOS / iOS
These require a Mac for compilation and specific app signing/packaging.

## 3. Runtime Dependencies

The application requires the **ONNX Runtime** shared library (`libonnxruntime.so`, `onnxruntime.dll`, etc.) to be present on the host system or bundled with the application for AI stemming to work.
