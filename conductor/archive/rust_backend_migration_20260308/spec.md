# Track Specification: rust_backend_migration_20260308

## Description
This track involves migrating the entire backend from Go to Rust. The primary goals are to resolve persistent symbol mismatch issues on older macOS versions (Big Sur), improve FFI safety, and remove the runtime dependency on FFmpeg by using native Rust audio decoding crates.

## Goals
- Initialize a Rust crate (`libbackend`) that compiles to a shared library (`.so`, `.dylib`, `.dll`).
- Re-implement all FFI functions currently provided by the Go backend.
- Replace `ffmpeg` subprocess calls with a native Rust audio engine (using `symphonia` for decoding and `hound` for WAV writing).
- Use the `ort` Rust crate for ONNX Runtime integration, enabling better control over library loading and API versions.
- Ensure the build process targets macOS 11.0 (Big Sur) as the minimum deployment target.

## Requirements
- **FFI Compatibility:** The Rust library must export functions with the exact same signatures as the current Go backend to avoid breaking the Flutter frontend.
- **Native Decoding:** Must decode MP4/AAC/M4A streams from YouTube directly into float32 buffers without FFmpeg.
- **Universal Binary:** Support ARM64 and AMD64 on macOS.
- **Memory Safety:** Use Rust's ownership model to manage FFI memory more reliably than the current `FreeString` approach.

## Acceptance Criteria
- The application compiles and runs on macOS 11.0 (Big Sur) without "Symbol not found" errors.
- The application processes a YouTube URL, stems it, and plays the result without needing FFmpeg installed.
- All existing features (History, Mixer, Export) function identically to the Go version.
- GitHub Actions pipeline produces functional artifacts for Linux, macOS (Universal), and Windows.

## Out of Scope
- Changing the AI model or stemming logic (this is a direct migration).
- Refactoring the Frontend UI (unless required for FFI changes).
